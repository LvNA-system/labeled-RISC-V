package uncore.pard

import chisel3._
import uncore.axi4._

class I2CBundle extends Bundle {
  val scl = Bool()
  val sda = Bool()
}

class APMBundle extends Bundle {
  val valid = Bool()
  val addr = UInt(32.W)
  val data = UInt(32.W)
}

class MigControlPlane(tagWidth: Int = 16, addrWidth: Int = 32, numEntries: Int= 3) extends Module {
  private val dataWidth = 64

  val io = IO(new Bundle {
    val addr = Input(UInt(7.W))
    val l1enable = Output(Vec(numEntries, Bool()))
    val i = Input(new I2CBundle)
    val t = Output(new I2CBundle)
    val o = Output(new I2CBundle)
    val apm = Output(new APMBundle)
    val s_axi =  Flipped(AXI4Bundle(AXI4BundleParameters(addrWidth, dataWidth, 5)))
    val m_axi = AXI4Bundle(AXI4BundleParameters(addrWidth, dataWidth, 5))
  })

  val i2c = Module(new I2CInterface)

  val ident = "PARDMig7CP".padTo((32 + 64) / 8, ' ').reverse
  val reg = Module(new RegisterInterface(
    TYPE = 0x40,  // 'M'
    IDENT_LOW = ident.substring(8, 12),
    IDENT_HIGH = ident.substring(0, 8)
  ))

  val detect = Module(new MigDetectLogic(
    tagBits = tagWidth,
    bucketSizeBits = 32,
    bucketFreqBits = 32,
    addrBits = addrWidth,
    nEntries = numEntries
  ))

  i2c.io.RST := reset
  i2c.io.SYS_CLK := clock
  i2c.io.ADDR := io.addr
  i2c.io.SCL_ext_i := io.i.scl
  i2c.io.SDA_ext_i := io.i.sda
  io.o.scl := i2c.io.SCL_o
  io.o.sda := i2c.io.SDA_o
  io.t.scl := i2c.io.SCL_t
  io.t.sda := i2c.io.SDA_t
  i2c.io.SEND_BUFFER := reg.io.SEND_BUFFER

  reg.io.RST := reset
  reg.io.SYS_CLK := clock
  reg.io.SCL_i := io.i.scl
  reg.io.STOP_DETECT := i2c.io.STOP_DETECT_o
  reg.io.INDEX_POINTER := i2c.io.INDEX_POINTER_o
  reg.io.WRITE_ENABLE := i2c.io.WRITE_ENABLE_o
  reg.io.RECEIVE_BUFFER := i2c.io.RECEIVE_BUFFER
  reg.io.DATA_VALID := detect.io.DATA_VALID
  reg.io.DATA_RBACK := detect.io.DATA_RBACK
  reg.io.DATA_MASK := detect.io.DATA_MASK
  reg.io.DATA_OFFSET := detect.io.DATA_OFFSET

  val rdBase = Wire(Bits((detect.dataBits / 2).W))
  val wrBase = Wire(Bits(rdBase.getWidth.W))
  val rdMask = Wire(Bits(rdBase.getWidth.W))
  val wrMask = Wire(Bits(rdMask.getWidth.W))

  detect.io.COMM_VALID := reg.io.COMM_VALID && !reg.io.COMM_DATA(31)
  (detect.io, io.s_axi) match { case (recv, in) =>
    // TODO: Use rocket's split utility
    recv.TAG_A := in.ar.bits.user
    rdMask := recv.DO_A(detect.dataBits - 1, detect.dataBits / 2)
    rdBase := recv.DO_A(detect.dataBits / 2 - 1, 0)
    recv.TAG_B := in.aw.bits.user
    wrMask := recv.DO_B(detect.dataBits - 1, detect.dataBits / 2)
    wrBase := recv.DO_B(detect.dataBits / 2 - 1, 0)
  }

  (detect.io, io.apm) match { case (d, apm) =>
      d.APM_DATA := apm.data
      d.APM_VALID := apm.valid
      d.APM_ADDR := apm.addr
  }

  io.s_axi <> io.m_axi

  // Address map
  io.m_axi.ar.bits.addr := Mux(detect.io.TAG_MATCH_A, io.s_axi.ar.bits.addr & (~rdMask).asUInt | rdBase, 0.U)
  io.m_axi.aw.bits.addr := Mux(detect.io.TAG_MATCH_B, io.s_axi.aw.bits.addr & (~wrMask).asUInt | wrBase, 0.U)

  // Traffic control
  val buckets = Seq.fill(numEntries){ Module(new token_bucket) }
  buckets.zipWithIndex.foreach { case (bucket, i) =>
    val id = detect.io.dsids(i)
    bucket.io.aclk := clock
    bucket.io.aresetn := !reset
    bucket.io.is_reading := io.s_axi.ar.valid && (id === io.s_axi.ar.bits.user)
    bucket.io.is_writing := io.s_axi.aw.valid && (id === io.s_axi.aw.bits.user)
    bucket.io.can_read := io.m_axi.ar.ready
    bucket.io.can_write := io.m_axi.aw.ready
    bucket.io.nr_rbyte := (io.s_axi.ar.bits.len + 1.U) << io.s_axi.ar.bits.size
    bucket.io.nr_wbyte := (io.s_axi.aw.bits.len + 1.U) << io.s_axi.aw.bits.size
    bucket.io.bucket_size := detect.io.buckets(i).size
    bucket.io.bucket_freq := detect.io.buckets(i).freq
    bucket.io.bucket_inc := detect.io.buckets(i).inc
    io.l1enable(i) := detect.io.l1enables(i) && bucket.io.enable
  }
}

object MIG extends App {
  Driver.execute(args, () => new MigControlPlane)
}
