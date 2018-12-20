package lvna

import Chisel._
import chisel3.VecInit
import chisel3.core.{IO, Input, Output}
import freechips.rocketchip.config.{Config, Field, Parameters}
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp}
import freechips.rocketchip.subsystem._
import freechips.rocketchip.system.{ExampleRocketSystem, ExampleRocketSystemModuleImp, UseEmu}
import freechips.rocketchip.tile.XLen
import freechips.rocketchip.util._
import scala.math.round
import freechips.rocketchip.util.GTimer

case object ProcDSidWidth extends Field[Int](3)

trait HasControlPlaneParameters {
  implicit val p: Parameters
  val nTiles = p(NTiles)
  val ldomDSidWidth = log2Up(nTiles)
  val procDSidWidth = p(ProcDSidWidth)
  val dsidWidth = ldomDSidWidth + procDSidWidth
  val nDSID = 1 << dsidWidth
  val cacheCapacityWidth = log2Ceil(p(NL2CacheCapacity) * 1024 / 64)
}

/**
 * From ControlPlane's side of view.
 */
class ControlPlaneIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters {
  private val indexWidth = 32
  val updateData   = UInt(INPUT, 32)
  val traffic      = UInt(OUTPUT, 32)
  val cycle        = UInt(OUTPUT, 32)
  val capacity     = UInt(OUTPUT, cacheCapacityWidth)
  val hartDsid     = UInt(OUTPUT, ldomDSidWidth)
  val hartDsidWen  = Bool(INPUT)
  val memBase      = UInt(OUTPUT, p(XLen))
  val memBaseLoWen = Bool(INPUT)
  val memBaseHiWen = Bool(INPUT)
  val memMask      = UInt(OUTPUT, p(XLen))
  val memMaskLoWen = Bool(INPUT)
  val memMaskHiWen = Bool(INPUT)
  val bucket       = new BucketBundle().asOutput
  val bktFreqWen   = Bool(INPUT)
  val bktSizeWen   = Bool(INPUT)
  val bktIncWen    = Bool(INPUT)
  val waymask      = UInt(OUTPUT, p(NL2CacheWays))
  val waymaskWen   = Bool(INPUT)
  val hartSel      = UInt(OUTPUT, indexWidth)
  val hartSelWen   = Bool(INPUT)
  val dsidSel      = UInt(OUTPUT, dsidWidth)
  val dsidSelWen   = Bool(INPUT)
}

/* From ControlPlane's View */
class CPToL2CacheIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters {
  val waymask = Output(UInt(p(NL2CacheWays).W))  // waymask returned to L2cache (1 cycle delayed)
  val dsid = Input(UInt(dsidWidth.W))  // DSID from requests L2 cache received
  val capacity = Input(UInt(cacheCapacityWidth.W))  // Count on way numbers
  val capacity_dsid = Output(UInt(dsidWidth.W))  // Capacity query dsid
}

class BucketState(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters with HasTokenBucketParameters {
  val nToken = UInt(tokenBucketSizeWidth.W)
  val traffic = UInt(tokenBucketSizeWidth.W)
  val counter = UInt(32.W)
  val enable = Bool()
}

class BucketIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters with HasTokenBucketParameters {
  val dsid = Input(UInt(dsidWidth.W))
  val size = Input(UInt(tokenBucketSizeWidth.W))
  val fire = Input(Bool())
  val enable = Output(Bool())
}

trait HasTokenBucketPlane extends HasControlPlaneParameters with HasTokenBucketParameters {
  private val bucket_debug = true

  val bucketParams = RegInit(Vec(Seq.fill(nDSID){
    Cat(100.U(tokenBucketSizeWidth.W), 5.U(tokenBucketFreqWidth.W), 1.U(tokenBucketSizeWidth.W)).asTypeOf(new BucketBundle)
  }))

  val bucketState = RegInit(Vec(Seq.fill(nDSID){
    Cat(0.U(tokenBucketSizeWidth.W), 0.U(tokenBucketSizeWidth.W), 0.U(32.W), true.B).asTypeOf(new BucketState)
  }))

  val bucketIO = IO(Vec(nTiles, new BucketIO()))

  val timer = GTimer()

  bucketState.zipWithIndex.foreach { case (state, i) =>
    state.counter := Mux(state.counter >= bucketParams(i).freq, 0.U, state.counter + 1.U)
    val req_sizes = bucketIO.map{bio => Mux(bio.dsid === i.U && bio.fire, bio.size, 0.U) }
    val req_all = req_sizes.reduce(_ + _)
    val updating = state.counter >= bucketParams(i).freq
    val inc_size = Mux(updating, bucketParams(i).inc, 0.U)
    val enable_next = state.nToken + inc_size > req_all
    val calc_next = state.nToken + inc_size - req_all
    val limit_next = Mux(calc_next < bucketParams(i).size, calc_next, bucketParams(i).size)

    val has_requester = bucketIO.map{bio => bio.dsid === i.U && bio.fire}.reduce(_ || _)
    when (has_requester) {
      state.traffic := state.traffic + (req_all >> 3).asUInt
    }

    when (has_requester || updating) {
      state.nToken := Mux(enable_next, limit_next, 0.U)
      state.enable := enable_next
    }

    if (bucket_debug && i <= 1) {
      printf(s"cycle: %d bucket %d req_all %d tokens %d inc %d enable_next %b counter %d traffic %d\n",
        GTimer(), i.U(dsidWidth.W), req_all, state.nToken, inc_size, enable_next, state.counter, state.traffic)
    }
  }

  bucketIO.foreach { bio =>
    bio.enable := bucketState(bio.dsid).enable
  }
}

class ControlPlane()(implicit p: Parameters) extends LazyModule
with HasControlPlaneParameters
with HasTokenBucketParameters
{
  private val memAddrWidth = p(XLen)

  override lazy val module = new LazyModuleImp(this) with HasTokenBucketPlane {
    val io = IO(new Bundle {
      val hartDsids = Vec(nTiles, UInt(ldomDSidWidth.W)).asOutput
      val memBases  = Vec(nTiles, UInt(memAddrWidth.W)).asOutput
      val memMasks  = Vec(nTiles, UInt(memAddrWidth.W)).asOutput
      val l2        = new CPToL2CacheIO()
      val cp        = new ControlPlaneIO()
    })

    val hartSel   = RegInit(0.U(ldomDSidWidth.W))
    val hartDsids = RegInit(Vec(Seq.tabulate(nTiles)(_.U(ldomDSidWidth.W))))
    val memBases  = RegInit(Vec(Seq.tabulate(nTiles){ i =>
      if (p(UseEmu)) {
        val memSize: BigInt = p(ExtMem).map { m => m.size }.getOrElse(0x80000000)
        (i * memSize / nTiles).U(memAddrWidth.W)
      } else {
        0.U(memAddrWidth.W)
      }
    }))
    val memMasks  = RegInit(Vec(Seq.fill(nTiles)(~0.U(memAddrWidth.W))))
    val waymasks  = RegInit(Vec(Seq.fill(nTiles){ ((1L << p(NL2CacheWays)) - 1).U }))
    val l2dsid_reg = RegNext(io.l2.dsid)  // 1 cycle delay
    io.l2.waymask := waymasks(l2dsid_reg)

    val currDsid = RegEnable(io.cp.updateData, 0.U, io.cp.dsidSelWen)
    io.cp.dsidSel := currDsid
    io.cp.waymask := waymasks(currDsid)
    io.cp.traffic := bucketState(currDsid).traffic
    io.cp.cycle := timer
    io.cp.capacity := io.l2.capacity
    io.l2.capacity_dsid := currDsid

    io.cp.hartDsid := hartDsids(hartSel)
    io.cp.hartSel := hartSel
    io.cp.memBase := memBases(hartSel)
    io.cp.memMask := memMasks(hartSel)
    io.cp.bucket := bucketParams(currDsid)
    io.hartDsids := hartDsids
    io.memBases := memBases
    io.memMasks := memMasks

    when (io.cp.hartSelWen) {
      hartSel := io.cp.updateData
    }

    when (io.cp.hartDsidWen) {
      hartDsids(hartSel) := io.cp.updateData
    }

    val mem_base_lo_tmp = RegInit(0.U(32.W))
    val mem_mask_lo_tmp = RegInit(~0.U(32.W))

    when (io.cp.memBaseLoWen) {
      mem_base_lo_tmp := io.cp.updateData
    }

    when (io.cp.memBaseHiWen) {
      memBases(hartSel) := Cat(io.cp.updateData, mem_base_lo_tmp)
    }

    when (io.cp.memMaskLoWen) {
      mem_mask_lo_tmp := io.cp.updateData
    }

    when (io.cp.memMaskHiWen) {
      memMasks(hartSel) := Cat(io.cp.updateData, mem_mask_lo_tmp)
    }

    when (io.cp.bktFreqWen) {
      bucketParams(currDsid).freq := io.cp.updateData
    }

    when (io.cp.bktSizeWen) {
      bucketParams(currDsid).size := io.cp.updateData
    }

    when (io.cp.bktIncWen) {
      bucketParams(currDsid).inc := io.cp.updateData
    }

    when (io.cp.waymaskWen) {
      waymasks(currDsid) := io.cp.updateData
    }

    // AutoMBA goes here

    val accountingCycle = 10000
    val cycleCounter = RegInit(0.asUInt(64.W))
    val lastTraffic = RegInit(Vec(Seq.fill(nTiles){ 0.U(32.W) }))

    when (GTimer() >= cycleCounter) {
      for (i <- 0 until nTiles) {
        // 输出每段时间内，产生了多少流量，用于精细观察流量控制策略
        // printf("Traffic time: %d dsid: %d traffic: %d\n", cycleCounter, i.U, io.traffics(i) - lastTraffic(i))
        // 输出到了每个时间点后的CDF，用于看整体的流量曲线，观察流量控制效果
        printf("Traffic time: %d dsid: %d traffic: %d\n", cycleCounter, i.U, bucketState(i).traffic)
        lastTraffic(i) := bucketState(i).traffic
      }
      cycleCounter := cycleCounter + accountingCycle.U
    }

    private val policy = "yzh"

    private val highPriorIndex = if (p(UseEmu)) 0 else nTiles
    private val startIndex = if (p(UseEmu)) 1 else 0
    private val limitScaleIndex= if (p(UseEmu)) 1 else 3

    if (policy == "solo") {
      ///////////////////////////////////////////
      // c0 Solo:
      for (i <- startIndex until nTiles) {
        bucketParams(i).inc := 0.U
      }

    } else if (policy == "yzh") {
      //////////////////////////////////////////////
      // Yu Zihao:
      val startTraffic = RegInit(0.asUInt(32.W))
      val windowCounter = RegInit(0.asUInt(16.W))

      val windowSize = 1000
      val totalBW = 100

      val quota = RegInit(50.asUInt(8.W))
      val curLevel = RegInit(4.asUInt(4.W))

      val maxQuota = (totalBW/10*9).U
      val minQuota = (totalBW/10).U
      val quotaStep = (totalBW/10).U

      def freqTable() = {
        val allocatedBW = (1 until 10).map{totalBW.toDouble/10*_}
        val freqs = allocatedBW.map(bw => round(windowSize.toDouble/bw))
        println(freqs)
        VecInit(freqs.map(_.asUInt(8.W)))
      }
      def limitFreqTable() = {
        // 这里的3是假设4个核心，剩下3个核心共享余下带宽
        val allocatedBW = (1 until 10).map{totalBW - totalBW.toDouble/10*_}
        val freqs = allocatedBW.map(bw => round(windowSize.toDouble/(bw/limitScaleIndex)))
        println(freqs)
        VecInit(freqs.map(_.asUInt(8.W)))
      }

      val levelToFreq = freqTable()
      val levelToLimitFreq = limitFreqTable()


      when (windowCounter >= windowSize.U) {
        windowCounter := 0.U

        val bandwidthUsage = bucketState(highPriorIndex).traffic - startTraffic
        startTraffic := bucketState(highPriorIndex).traffic
        printf("limit level: %d;quota: %d/%d; traffic: %d\n", curLevel, quota, totalBW.U, bandwidthUsage)
        printf("freq 0: %d; freq 1: %d\n", bucketParams(0).freq, bucketParams(1).freq)
        printf("inc 0: %d; inc 1: %d\n", bucketParams(0).inc , bucketParams(1).inc)

        val nextLevel = Wire(UInt(4.W))
        val nextQuota = Wire(UInt(8.W))

        nextLevel := curLevel
        nextQuota := quota

        when (bandwidthUsage >= (((quota<<5) + (quota<<6)) >> 7) ) {
          // usage >= quota * 75%
          nextLevel := Mux(curLevel === 8.U, 8.U, curLevel + 1.U)
          nextQuota := Mux(quota === maxQuota, maxQuota, quota + quotaStep)

        } .elsewhen (bandwidthUsage < (((quota<<4) + (quota<<5)) >> 7) ) {
          // usage < quota * 37.5%
          nextLevel := Mux(curLevel === 0.U, 0.U, curLevel - 1.U)
          nextQuota := Mux(quota === minQuota, minQuota, quota - quotaStep)
        }

        // bucketParams(0).freq := levelToFreq(nextLevel)
        // bucketParams(0).inc := 1.U
        for (i <- startIndex until nTiles) {
          bucketParams(i).freq := levelToLimitFreq(nextLevel)
          bucketParams(i).inc := 1.U
        }
        curLevel := nextLevel
        quota := nextQuota

        printf("next level: %d;next quota: %d\n", nextLevel, nextQuota)
      }
      when (windowCounter < windowSize.U) {
        windowCounter := windowCounter + 1.U
      }

    } else if (policy == "lzg") {
      ///////////////////////////////////////////////
      // Liu Zhigang:
      val regulationCycles = 16000
      val samplingCycles = 1000
      val startTraffic = RegInit(0.asUInt(32.W))

      val samplingCounter = RegInit(0.asUInt(32.W))
      val regulationCounter = RegInit(0.asUInt(32.W))

      val s_sample :: s_regulate :: Nil = Enum(UInt(), 2)
      val state = Reg(init = s_sample)

      // during s_sample state, high priority app runs alone
      // all others' memory requests are blocked
      when (state === s_sample) {
        samplingCounter := samplingCounter + 1.U
        for (i <- startIndex until nTiles) {
          bucketParams(i).freq := 3200.U
          bucketParams(i).inc := 1.U
        }
        when (samplingCounter >= samplingCycles.U) {
          // estimate high priority app's memory bandwidth demand
          // set low priority app's bucket accordingly
          val bandwidthUsage = bucketState(highPriorIndex).traffic - startTraffic
          startTraffic := bucketState(highPriorIndex).traffic
          // val estimatedBandwidth = startTraffic << 4
          // 经验数据，仿真时，一万个周期，两个核最多往下面推了1000个beat
          // val totalBandwidth = regulationCycles / 10
          // 假设统计出来1000个周期内高优先级用了x beat，则在接下来的16000个周期里
          // 低优先级最多可以传输的beat数为 1600 - 16x
          // 相应地，其freq应该为 16000 / (1600 - 16x)
          // 由于这个无法简单表示，所以，我们手动将其分段表示
          // assume NTiles = 4
          // val newFreq = (regulationCycles.U - estimatedBandwidth) >> 4

          // 不那么激进的参数，这个是按照公式算的freq
          // val newFreq = Mux(bandwidthUsage >= 90.U, 100.U,
          //   Mux(bandwidthUsage >= 80.U, 50.U,
          //     Mux(bandwidthUsage >= 70.U, 33.U,
          //       Mux(bandwidthUsage >= 60.U, 25.U,
          //         Mux(bandwidthUsage >= 50.U, 20.U, 10.U)))))

          // 激进的参数，把上面根据freq算的数据，手动扩大几倍，把低优先级限制得更加死
          val newFreq = Mux(bandwidthUsage >= 90.U, 400.U,
            Mux(bandwidthUsage >= 80.U, 300.U,
              Mux(bandwidthUsage >= 70.U, 200.U,
                Mux(bandwidthUsage >= 60.U, 100.U,
                  Mux(bandwidthUsage >= 50.U, 100.U, 10.U)))))


          for (i <- startIndex until nTiles) {
            bucketParams(i).freq := newFreq
            bucketParams(i).inc := 1.U
          }

          regulationCounter := 0.U
          state := s_regulate
        }
      }

      when (state === s_regulate) {
        regulationCounter := regulationCounter + 1.U
        when (regulationCounter >= regulationCycles.U) {
          // temporarily disable all others' memory requests
          // let high priority app runs solo
          samplingCounter := 0.U
          state := s_sample
        }
      }
    }
  }
}

trait HasControlPlane extends HasRocketTiles {
  this: BaseSubsystem =>
  val controlPlane = LazyModule(new ControlPlane())
}

trait HasControlPlaneModuleImpl extends HasRocketTilesModuleImp {
  val outer: HasControlPlane

  (outer.rocketTiles zip outer.tokenBuckets).zipWithIndex.foreach { case((tile, token), i) =>
    val cpio = outer.controlPlane.module.io
    tile.module.dsid := cpio.hartDsids(i.U)
    tile.module.memBase := cpio.memBases(i.U)
    tile.module.memMask := cpio.memMasks(i.U)
    token.module.bucketIO <> outer.controlPlane.module.bucketIO(i)
  }

  outer.debug.module.io.cp <> outer.controlPlane.module.io.cp
}

trait BindL2WayMask extends HasRocketTiles {
  this: BaseSubsystem with HasControlPlane with CanHaveMasterAXI4MemPort =>
  val _cp = controlPlane
  val _l2 = l2cache
}

trait BindL2WayMaskModuleImp extends HasRocketTilesModuleImp {
  val outer: BindL2WayMask
  outer._l2.module.cp <> outer._cp.module.io.l2
}
