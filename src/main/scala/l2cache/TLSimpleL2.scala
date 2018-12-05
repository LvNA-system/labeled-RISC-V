//**************************************************************************
// L2 Cache
//--------------------------------------------------------------------------
//
// Zhigang Liu
// 2018 Aug 15

package freechips.rocketchip.subsystem

import Chisel._
import chisel3.util.IrrevocableIO
import freechips.rocketchip.config.{Field, Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._
import freechips.rocketchip.tilelink._
import lvna.{HasControlPlaneParameters, WayMaskIO}

case class TLL2CacheParams(
  debug: Boolean = false
)

class MetadataEntry(tagBits: Int, dsidWidth: Int) extends Bundle {
  val valid = Bool()
  val dirty = Bool()
  val tag = UInt(width = tagBits.W)
  val rr_state = Bool()
  val dsid = UInt(width = dsidWidth.W)
  override def cloneType = new MetadataEntry(tagBits, dsidWidth).asInstanceOf[this.type]
}

// ============================== DCache ==============================
class TLSimpleL2Cache(param: TLL2CacheParams)(implicit p: Parameters) extends LazyModule
with HasControlPlaneParameters
{
  val node = TLAdapterNode(
    clientFn = { c => c.copy(clients = c.clients map { c2 => c2.copy(sourceId = IdRange(0, 1))} )}
  )

  lazy val module = new LazyModuleImp(this) {
    val nWays = p(NL2CacheWays)
    val nSets = p(NL2CacheCapacity) * 1024 / 64 / nWays
    val cp = IO(new WayMaskIO().flip())
    (node.in zip node.out) foreach { case ((in, edgeIn), (out, edgeOut)) =>
      require(isPow2(nSets))
      require(isPow2(nWays))

      /* parameters */
      val Y = true.B
      val N = false.B

      val blockSize = 64 * 8
      val blockBytes = blockSize / 8
      val innerBeatSize = in.d.bits.params.dataBits
      val innerBeatBytes = innerBeatSize / 8
      val innerDataBeats = blockSize / innerBeatSize
      val innerBeatBits = log2Ceil(innerBeatBytes)
      val innerBeatIndexBits = log2Ceil(innerDataBeats)
      val innerBeatLSB = innerBeatBits
      val innerBeatMSB = innerBeatLSB + innerBeatIndexBits - 1

      val outerBeatSize = out.d.bits.params.dataBits
      val outerBeatBytes = outerBeatSize / 8
      val outerDataBeats = blockSize / outerBeatSize
      val outerBeatLen = log2Ceil(outerBeatBytes)
      val outerBurstLen = outerBeatLen + log2Ceil(outerDataBeats)
      val addrWidth = in.a.bits.params.addressBits
      val innerIdWidth = in.a.bits.params.sourceBits
      val outerIdWidth = out.a.bits.params.sourceBits

      // to keep L1 miss & L2 hit penalty small, inner axi bus width should be as large as possible
      // on loongson and zedboard, outer axi bus width are usually 32bit
      // so we require that innerBeatSize to be multiples of outerBeatSize
      val split = innerBeatSize / outerBeatSize
      val splitBits = log2Ceil(split)
      require(isPow2(split))

      val indexBits = log2Ceil(nSets)
      val blockOffsetBits = log2Ceil(blockBytes)
      val tagBits = addrWidth - indexBits - blockOffsetBits
      val offsetLSB = 0
      val offsetMSB = blockOffsetBits - 1
      val indexLSB = offsetMSB + 1
      val indexMSB = indexLSB + indexBits - 1
      val tagLSB = indexMSB + 1
      val tagMSB = tagLSB + tagBits - 1

      val rst_cnt = RegInit(0.asUInt(log2Up(2 * nSets + 1).W))
      val rst = (rst_cnt < UInt(2 * nSets)) && !reset.toBool
      when (rst) { rst_cnt := rst_cnt + 1.U }

      val s_idle :: s_gather_write_data :: s_send_bresp :: s_update_meta :: s_tag_read_req :: s_tag_read_resp :: s_tag_read :: s_merge_put_data :: s_data_read :: s_data_write :: s_wait_ram_awready :: s_do_ram_write :: s_wait_ram_bresp :: s_wait_ram_arready :: s_do_ram_read :: s_data_resp :: Nil = Enum(UInt(), 16)

      val state = Reg(init = s_idle)
      // state transitions for each case
      // read hit: s_idle -> s_tag_read -> s_data_read -> s_data_resp -> s_idle
      // read miss no writeback : s_idle -> s_tag_read -> s_wait_ram_arready -> s_do_ram_read -> s_data_write -> s_update_meta -> s_idle
      // read miss writeback : s_idle -> s_tag_read -> s_data_read -> s_wait_ram_awready -> s_do_ram_write -> s_wait_ram_bresp
      //                              -> s_wait_ram_arready -> s_do_ram_read -> s_data_write -> s_update_meta -> s_idle
      // write hit: s_idle -> s_gather_write_data ->  s_send_bresp -> s_tag_read -> s_data_read -> s_merge_put_data -> s_data_write -> s_update_meta -> s_idle
      // write miss no writeback : s_idle -> s_gather_write_data ->  s_send_bresp -> s_tag_read -> s_wait_ram_arready -> s_do_ram_read
      //                                  -> s_merge_put_data -> s_data_write -> s_update_meta -> s_idle
      // write miss writeback : s_idle -> s_gather_write_data ->  s_send_bresp -> s_tag_read -> s_data_read -> s_wait_ram_awready -> s_do_ram_write -> s_wait_ram_bresp
      //                               -> s_wait_ram_arready -> s_do_ram_read -> s_merge_put_data -> s_data_write -> s_update_meta -> s_idle
      val timer = GTimer()
      val log_prefix = "cycle: %d [L2Cache] state %x "
      def log_raw(prefix: String, fmt: String, tail: String, args: Bits*) = {
        if (param.debug) {
          printf(prefix + fmt + tail, args:_*)
        }
      }

      /** Single log */
      def log(fmt: String, args: Bits*) = log_raw(log_prefix, fmt, "\n", timer +: state +: args:_*)
      /** Log with line continued */
      def log_part(fmt: String, args: Bits*) = log_raw(log_prefix, fmt, "", timer +: state +: args:_*)
      /** Log with nothing added */
      def log_plain(fmt: String, args: Bits*) = log_raw("", fmt, "", args:_*)

      when (in.a.fire()) {
        log("in.a opcode %x, dsid %x, param %x, size %x, source %x, address %x, mask %x, data %x",
          in.a.bits.opcode,
          in.a.bits.dsid,
          in.a.bits.param,
          in.a.bits.size,
          in.a.bits.source,
          in.a.bits.address,
          in.a.bits.mask,
          in.a.bits.data)
      }

      when (out.a.fire()) {
        log("out.a.opcode %x, dsid %x, param %x, size %x, source %x, address %x, mask %x, data %x",
          out.a.bits.opcode,
          out.a.bits.dsid,
          out.a.bits.param,
          out.a.bits.size,
          out.a.bits.source,
          out.a.bits.address,
          out.a.bits.mask,
          out.a.bits.data)
      }


      val in_opcode = in.a.bits.opcode
      val in_dsid = in.a.bits.dsid
      val in_addr = in.a.bits.address
      val in_id   = in.a.bits.source
      val in_len_shift = in.a.bits.size >= innerBeatBits.U
      val in_len  = Mux(in_len_shift, ((1.U << in.a.bits.size) >> innerBeatBits) - 1.U, 0.U)  // #word, i.e., arlen in AXI
      val in_data = in.a.bits.data
      val in_data_mask = in.a.bits.mask

      val in_recv_fire = in.a.fire()
      val in_read_req = in_recv_fire && (in_opcode === TLMessages.Get)
      val in_write_req = in_recv_fire && (in_opcode === TLMessages.PutFullData || in_opcode === TLMessages.PutPartialData)
      val in_recv_handshake = in.a.ready

      val in_send_ok = in.d.fire()
      val in_send_id = in.d.bits.source
      val in_send_opcode = in.d.bits.opcode

      val addr = Reg(UInt(addrWidth.W))
      val id = Reg(UInt(innerIdWidth.W))
      val opcode = Reg(UInt(3.W))
      val dsid = Reg(UInt(dsidWidth.W))
      val size_reg = Reg(UInt(width=in.a.bits.params.sizeBits))
      
      val ren = RegInit(N)
      val wen = RegInit(N)

      val start_beat = in_addr(innerBeatMSB, innerBeatLSB)
      val inner_end_beat_reg = Reg(UInt(4.W))
      val inner_end_beat = Mux(state === s_idle, start_beat + in_len, inner_end_beat_reg)
      val gather_curr_beat_reg = RegInit(0.asUInt(log2Ceil(innerDataBeats).W))
      val gather_curr_beat = Mux(state === s_idle, start_beat, gather_curr_beat_reg)
      val gather_last_beat = gather_curr_beat === inner_end_beat
      val merge_curr_beat = RegInit(0.asUInt(log2Ceil(innerDataBeats).W))
      val merge_last_beat = merge_curr_beat === inner_end_beat
      val resp_curr_beat = RegInit(0.asUInt(log2Ceil(innerDataBeats).W))
      val resp_last_beat = resp_curr_beat === inner_end_beat

      // state transitions:
      // s_idle: idle state
      // capture requests
      // CheckOneHot(Seq(in.ar.fire(), in.aw.fire(), in.r.fire(), in.w.fire(), in.b.fire()))
      when (state === s_idle) {
        when (in_read_req) {
          ren := Y
          wen := N

          addr := in_addr
          id := in_id
          opcode := in_opcode
          dsid := in_dsid
          size_reg := in.a.bits.size

          // gather_curr_beat_reg := start_beat
          merge_curr_beat := start_beat
          resp_curr_beat := start_beat
          inner_end_beat_reg := start_beat + in_len

          state := s_tag_read_req
        } .elsewhen (in_write_req) {
          ren := N
          wen := Y
          addr := in_addr
          id := in_id
          opcode := in_opcode
          dsid := in_dsid
          size_reg := in.a.bits.size

          // gather_curr_beat_reg := start_beat
          merge_curr_beat := start_beat
          resp_curr_beat := start_beat
          inner_end_beat_reg := start_beat + in_len

          state := s_gather_write_data
        } .elsewhen (in.b.fire() || in.c.fire() || in.e.fire()) {
          assert(N, "Inner tilelink Unexpected handshake")
        }
      }

      val raddr_recv_ready = state === s_idle && !rst
      val waddr_recv_ready = state === s_idle && !rst

      // s_gather_write_data:
      // gather write data
      val put_data_buf = Reg(Vec(outerDataBeats, UInt(outerBeatSize.W)))
      val put_data_mask = Reg(init=Vec.fill(outerDataBeats)(Fill(outerBeatBytes, 0.U)))
      val wdata_recv_ready = state === s_gather_write_data
      // when (state === s_gather_write_data && in_write_req) {
      // tilelink receives the first data beat when address handshake
      // which is different with axi
      when (in_write_req || (state === s_gather_write_data && in_recv_fire)) {
        when (state === s_idle) {
          gather_curr_beat_reg := start_beat + 1.U
        } .elsewhen (state === s_gather_write_data) {
          gather_curr_beat_reg := gather_curr_beat_reg + 1.U
        } .otherwise {
          assert(N, "state error")
        }

        for (i <- 0 until split) {
          put_data_buf((gather_curr_beat << splitBits) + i.U) := in_data(outerBeatSize * (i + 1) - 1, outerBeatSize * i)
          put_data_mask((gather_curr_beat << splitBits) + i.U) := in_data_mask(outerBeatBytes * (i + 1) - 1, outerBeatBytes * i)
        }
        when (gather_last_beat) {
          state := s_send_bresp
        }
      }

      in_recv_handshake := raddr_recv_ready || waddr_recv_ready || wdata_recv_ready
      val raddr_fire = raddr_recv_ready && in_recv_fire
      val waddr_fire = waddr_recv_ready && in_recv_fire
      val wdata_fire = wdata_recv_ready && in_recv_fire

      // s_send_bresp:
      // send bresp, end write transaction
      val in_write_ok = state === s_send_bresp

      when (state === s_send_bresp && in_send_ok) {
        state := s_tag_read_req
      }

      // s_tag_read: inspecting meta data
      // to keep the sram access path short, sram addr and output are latched
      // now, tag access has three stages:
      // 1. read req  2. read response  3. check hit, miss

      // metadata array
      val meta_array = DescribedSRAM(
        name = "L2_meta_array",
        desc = "L2 cache metadata array",
        size = nSets,
        data = Vec(nWays, new MetadataEntry(tagBits, dsidWidth))
      )

      val idx = addr(indexMSB, indexLSB)

      val meta_array_wen = rst || state === s_tag_read
      val read_tag_req = (state === s_tag_read_req)
      val meta_rdata = meta_array.read(idx, read_tag_req && !meta_array_wen)

      def wayMap[T <: Data](f: Int => T) = Vec((0 until nWays).map(f))

      val vb_rdata = wayMap((w: Int) => meta_rdata(w).valid).asUInt
      val db_rdata = wayMap((w: Int) => meta_rdata(w).dirty).asUInt
      val tag_rdata = wayMap((w: Int) => meta_rdata(w).tag)
      val curr_state = wayMap((w: Int) => meta_rdata(w).rr_state).asUInt
      val set_dsids = wayMap((w: Int) => meta_rdata(w).dsid)

      when (state === s_tag_read_req) {
        state := s_tag_read_resp
      }

      // tag, valid, dirty response
      val vb_rdata_reg = Reg(Bits(width = nWays.W))
      val db_rdata_reg = Reg(Bits(width = nWays.W))
      val tag_rdata_reg = Reg(Vec(nWays, UInt(width = tagBits.W)))
      val curr_state_reg = Reg(Bits(width = nWays))
      val set_dsids_reg = Reg(Vec(nWays, UInt(width = dsidWidth.W)))

      when (state === s_tag_read_resp) {
        state := s_tag_read
        vb_rdata_reg := vb_rdata
        db_rdata_reg := db_rdata
        tag_rdata_reg := tag_rdata
        curr_state_reg := curr_state
        set_dsids_reg := set_dsids
      }

      // check hit, miss, repl_way
      val tag = addr(tagMSB, tagLSB)
      val tag_eq_way = wayMap((w: Int) => tag_rdata_reg(w) === tag)
      val tag_match_way = wayMap((w: Int) => tag_eq_way(w) && vb_rdata_reg(w)).asUInt
      val hit = tag_match_way.orR
      val read_hit = hit && ren
      val write_hit = hit && wen
      val read_miss = !hit && ren
      val write_miss = !hit && wen
      val hit_way = Wire(Bits())
      hit_way := Bits(0)
      (0 until nWays).foreach(i => when (tag_match_way(i)) { hit_way := Bits(i) })

      cp.dsid := dsid
      val curr_mask = cp.waymask
      val repl_way = Mux((curr_state_reg & curr_mask).orR, PriorityEncoder(curr_state_reg & curr_mask),
        Mux(curr_mask.orR, PriorityEncoder(curr_mask), UInt(0)))

      // valid and dirty
      val need_writeback = vb_rdata_reg(repl_way) && db_rdata_reg(repl_way)
      val writeback_tag = tag_rdata_reg(repl_way)
      val writeback_addr = Cat(writeback_tag, Cat(idx, 0.U(blockOffsetBits.W)))

      val read_miss_writeback = read_miss && need_writeback
      val read_miss_no_writeback = read_miss && !need_writeback
      val write_miss_writeback = write_miss && need_writeback
      val write_miss_no_writeback = write_miss && !need_writeback

      val need_data_read = read_hit || write_hit || read_miss_writeback || write_miss_writeback

      when (state === s_tag_read) {
        log("hit: %d idx: %x curr_state_reg: %x hit_way: %x repl_way: %x", hit, idx, curr_state_reg, hit_way, repl_way)
        when (ren) {
          log_part("read addr: %x idx: %d tag: %x hit: %d ", addr, idx, tag, hit)
        }
        when (wen) {
          log_part("write addr: %x idx: %d tag: %x hit: %d ", addr, idx, tag, hit)
        }
        when (hit) {
          log_plain("hit_way: %d\n", hit_way)
        } .elsewhen (need_writeback) {
          log_plain("repl_way: %d wb_addr: %x\n", repl_way, writeback_addr)
        } .otherwise {
          log_plain("repl_way: %d repl_addr: %x\n", repl_way, writeback_addr)
        }
        log("s1 tags: " + Seq.fill(tag_rdata_reg.size)("%x").mkString(" "), tag_rdata_reg:_*)
        log("s1 vb: %x db: %x", vb_rdata_reg, db_rdata_reg)

        // check for cross cache line bursts
        assert(inner_end_beat < innerDataBeats.U, "cross cache line bursts detected")

        when (read_hit || write_hit || read_miss_writeback || write_miss_writeback) {
          state := s_data_read
        } .elsewhen (read_miss_no_writeback || write_miss_no_writeback) {
          // no need to write back, directly refill data
          state := s_wait_ram_arready
        } .otherwise {
          assert(N, "Unexpected condition in s_tag_read")
        }
      }

      val rst_metadata = Wire(Vec(nWays, new MetadataEntry(tagBits, 16)))
      for (i <- 0 until nWays) {
        val metadata = rst_metadata(i)
        metadata.valid := false.B
        metadata.dirty := false.B
        metadata.tag := 0.U
        metadata.dsid := 0.U
      }


      // update metadata

      val update_way = Mux(hit, hit_way, repl_way)
      val next_state = Wire(Bits())
      when (state === s_tag_read) {
        when (!(curr_state_reg & curr_mask).orR) {
          next_state := curr_state_reg | curr_mask
        } .otherwise {
          next_state := curr_state_reg.bitSet(update_way, Bool(false))
        }
        log("dsid: %d set: %d hit: %d rw: %d update_way: %d curr_state: %x next_state: %x",
          dsid, idx, hit, ren, update_way, curr_state_reg, next_state)
      }

      val update_metadata = Wire(Vec(nWays, new MetadataEntry(tagBits, 16)))
      for (i <- 0 until nWays) {
        val metadata = update_metadata(i)
        val is_update_way = update_way === i.U
        when (is_update_way) {
          metadata.valid := true.B
          metadata.dirty := Mux(read_hit, db_rdata_reg(update_way),
            Mux(read_miss, false.B, true.B))
          metadata.tag := tag
          metadata.dsid := dsid
        } .otherwise {
          metadata.valid := vb_rdata_reg(i)
          metadata.dirty := db_rdata_reg(i)
          metadata.tag := tag_rdata_reg(i)
          metadata.dsid := set_dsids_reg(i)
        }
        metadata.rr_state := next_state(i)
      }

      val meta_array_widx = Mux(rst, rst_cnt, idx)
      val meta_array_wdata = Mux(rst, rst_metadata, update_metadata)

      when (meta_array_wen) {
        meta_array.write(meta_array_widx, meta_array_wdata)
      }

      // ###############################################################
      // #                  data array read/write                      #
      // ###############################################################
      val data_read_way = Mux(read_hit || write_hit, hit_way, repl_way)
      // incase it overflows
      val data_read_cnt = RegInit(0.asUInt((log2Ceil(innerDataBeats) + 1).W))
      val data_read_valid = (state === s_tag_read && need_data_read) || (state === s_data_read && data_read_cnt =/= innerDataBeats.U)
      val data_read_idx = idx << log2Ceil(innerDataBeats) | data_read_cnt
      val dout = Wire(Vec(split, UInt(outerBeatSize.W)))

      val data_write_way = Mux(write_hit, hit_way, repl_way)
      val data_write_cnt = Wire(UInt())
      val data_write_valid = state === s_data_write
      val data_write_idx = idx << log2Ceil(innerDataBeats) | data_write_cnt
      val din = Wire(Vec(split, UInt(outerBeatSize.W)))

      val data_arrays = Seq.fill(split) {
        DescribedSRAM(
          name = "L2_data_array",
          desc = "L2 data array",
          size = nSets * innerDataBeats,
          data = Vec(nWays, UInt(width = outerBeatSize.W))
        ) }
      for ((data_array, i) <- data_arrays zipWithIndex) {
        when (data_write_valid) {
          log("write data array: %d idx: %d way: %d data: %x", i.U, data_write_idx, data_write_way, din(i))
          data_array.write(data_write_idx, Vec.fill(nWays)(din(i)), (0 until nWays).map(data_write_way === UInt(_)))
        }
        dout(i) := data_array.read(data_read_idx, data_read_valid && !data_write_valid)(data_read_way)
        when (RegNext(data_read_valid, N)) {
          log("read data array: %d idx: %d way: %d data: %x",
            i.U, RegNext(data_read_idx), RegNext(data_read_way), dout(i))
        }
      }

      // s_data_read
      // read miss or need write back
      val data_buf = Reg(Vec(outerDataBeats, UInt(outerBeatSize.W)))
      when (data_read_valid) {
        data_read_cnt := data_read_cnt + 1.U
      }
      when (state === s_data_read) {
        for (i <- 0 until split) {
          data_buf(((data_read_cnt - 1.U) << splitBits) + i.U) := dout(i)
        }
        when (data_read_cnt === innerDataBeats.U) {
          data_read_cnt := 0.U
          when (read_hit) {
            state := s_data_resp
          } .elsewhen (read_miss_writeback || write_miss_writeback) {
            state := s_wait_ram_awready
          } .elsewhen (write_hit) {
            state := s_merge_put_data
          } .otherwise {
            assert(N, "Unexpected condition in s_data_read")
          }
        }
      }

      // s_merge_put_data: merge data_buf and put_data_buf, and store the final result in data_buf
      // the old data(either read from data array or from refill) resides in data_buf
      // the new data(gathered from inner write) resides in put_data_buf
      def mergePutData(old_data: UInt, new_data: UInt, wmask: UInt): UInt = {
        val full_wmask = FillInterleaved(8, wmask)
          ((~full_wmask & old_data) | (full_wmask & new_data))
      }
      when (state === s_merge_put_data) {
        merge_curr_beat := merge_curr_beat + 1.U
        for (i <- 0 until split) {
          val idx = (merge_curr_beat << splitBits) + i.U
          data_buf(idx) := mergePutData(data_buf(idx), put_data_buf(idx), put_data_mask(idx))
        }
        when (merge_last_beat) {
          state := s_data_write
        }
      }

      // s_data_write
      val (write_cnt, write_done) = Counter(state === s_data_write, innerDataBeats)
      data_write_cnt := write_cnt
      for (i <- 0 until split) {
        val idx = (data_write_cnt << splitBits) + i.U
        din(i) := data_buf(idx)
      }
      when (state === s_data_write && write_done) {
        when (ren) {
          state := s_data_resp
        } .otherwise {
          state := s_idle
        }
      }

      // outer tilelink interface
      // external memory bus width is 32/64/128bits
      // so each memport read/write is mapped into a whole tilelink bus width read/write
      val axi4_size = log2Up(outerBeatBytes).U
      val mem_addr = Cat(addr(tagMSB, indexLSB), 0.asUInt(blockOffsetBits.W))

      val out_raddr_fire = out.a.fire()
      val out_waddr_fire = out.a.fire()
      val out_wdata_fire = out.a.fire()
      val out_wreq_fire = out.d.fire()
      val out_rdata_fire = out.d.fire()
      val out_rdata = out.d.bits.data
      // #########################################################
      // #                  write back path                      #
      // #########################################################
      // s_wait_ram_awready
      when (state === s_wait_ram_awready) {
        state := s_do_ram_write
      }

      val (wb_cnt, wb_done) = Counter(out_wdata_fire && state === s_do_ram_write, outerDataBeats)
      when (state === s_do_ram_write && wb_done) {
        state := s_wait_ram_bresp
      }

      val out_write_valid = state === s_do_ram_write

      when (state === s_wait_ram_bresp && out_wreq_fire) {
        when (read_miss_writeback || write_miss_writeback) {
          // do refill
          state := s_wait_ram_arready
        } .otherwise {
          assert(N, "Unexpected condition in s_wait_ram_bresp")
        }
      }

      // write response channel signals
      // out.d.ready := 

      // #####################################################
      // #                  refill path                      #
      // #####################################################
      when (state === s_wait_ram_arready && out_raddr_fire) {
        state := s_do_ram_read
      }
      val (refill_cnt, refill_done) = Counter(out_rdata_fire && state === s_do_ram_read, outerDataBeats)
      when (state === s_do_ram_read && out_rdata_fire) {
        data_buf(refill_cnt) := out_rdata
        when (refill_done) {
          when (ren) {
            state := s_data_write
          } .otherwise {
            state := s_merge_put_data
          }
        }
      }

      val out_read_valid = state === s_wait_ram_arready

      val out_data = data_buf(wb_cnt)
      val out_addr = Mux(out_read_valid, mem_addr, writeback_addr)
      val out_opcode = Mux(out_read_valid, TLMessages.Get, TLMessages.PutFullData)

      out.a.bits.opcode  := out_opcode
      out.a.bits.dsid    := dsid
      out.a.bits.param   := UInt(0)
      out.a.bits.size    := outerBurstLen.U
      out.a.bits.source  := 0.asUInt(outerIdWidth.W)
      out.a.bits.address := out_addr
      out.a.bits.mask    := edgeOut.mask(out_addr, outerBurstLen.U)
      out.a.bits.data    := out_data
      out.a.bits.corrupt := Bool(false)
      // edgeOut.Put(0.asUInt(outerIdWidth.W), out_addr, outerBeatLen.U, out_data)
      
      out.a.valid := out_write_valid || out_read_valid

      // read data channel signals
      out.d.ready := (state === s_do_ram_read) || (state === s_wait_ram_bresp)

      // ########################################################
      // #                  data resp path                      #
      // ########################################################
      when (state === s_data_resp && in_send_ok) {
        resp_curr_beat := resp_curr_beat + 1.U
        when (resp_last_beat) {
          state := s_idle
        }
      }

      val resp_data = Wire(Vec(split, UInt(outerBeatSize.W)))
      for (i <- 0 until split) {
        resp_data(i) := data_buf((resp_curr_beat << splitBits) + i.U)
      }
      
      val in_read_ok = state === s_data_resp

      in.d.valid := in_write_ok || in_read_ok
      in.d.bits.opcode  := Mux(in_read_ok, TLMessages.AccessAckData, TLMessages.AccessAck)
      in.d.bits.param   := UInt(0)
      in.d.bits.size    := size_reg
      in.d.bits.source  := id
      in.d.bits.sink    := UInt(0)
      in.d.bits.denied  := Bool(false)
      in.d.bits.data    := resp_data(resp_curr_beat)
      in.d.bits.corrupt := Bool(false)
      // edgeIn.AccessAck(id, size_reg, resp_data(resp_curr_beat))

      if (edgeOut.manager.anySupportAcquireB && edgeOut.client.anySupportProbe) {
        in.b <> out.b
        out.c <> in.c
        out.e <> in.e
      } else {
        in.b.valid := Bool(false)
        in.c.ready := Bool(true)
        in.e.ready := Bool(true)
        out.b.ready := Bool(true)
        out.c.valid := Bool(false)
        out.e.valid := Bool(false)
      }
    }
  }
}

object TLSimpleL2Cache
{
  def apply()(implicit p: Parameters): TLNode =
  {
    if (p(NL2CacheCapacity) != 0) {
      val tlsimpleL2cache = LazyModule(new TLSimpleL2Cache(TLL2CacheParams()))
      tlsimpleL2cache.node
    }
    else {
      val tlsimpleL2cache = LazyModule(new TLBuffer(BufferParams.none))
      tlsimpleL2cache.node
    }
  }
}

object TLSimpleL2CacheRef
{
  def apply()(implicit p: Parameters): TLSimpleL2Cache = {
    val tlsimpleL2cache = LazyModule(new TLSimpleL2Cache(TLL2CacheParams()))
    tlsimpleL2cache
  }
}
