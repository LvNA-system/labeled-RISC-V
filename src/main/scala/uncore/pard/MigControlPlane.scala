package uncore.pard

import chisel3._
import chisel3.util._
import config._
import uncore.axi4._

class I2CBundle extends Bundle {
  val scl = Bool()
  val sda = Bool()
}

class APMBundle extends Bundle {
  val valid = Input(Bool())
  val addr = Input(UInt(32.W))
  val data = Input(UInt(32.W))
}

class MigControlPlane(implicit p: Parameters) extends Module {
  private val dataBits = 64
  private val addrBits = p(AddrBits)
  private val nEntries = p(NEntries)

  val io = IO(new Bundle {
    val addr = Input(UInt(7.W))
    val l1enable = Output(Vec(nEntries, Bool()))
    val i = Input(new I2CBundle)
    val t = Output(new I2CBundle)
    val o = Output(new I2CBundle)
    val apm = new APMBundle
    val s_axi =  Flipped(AXI4Bundle(AXI4BundleParameters(addrBits, dataBits, 5)))
    val m_axi = AXI4Bundle(AXI4BundleParameters(addrBits, dataBits, 5))
    val trigger_axis = new DecoupledIO(UInt(16.W))
  })

  val i2c = Module(new I2CInterface)

  val reg = Module(new RegInterface('M', "PARDMig7CP"))

  val detect = Module(new MigDetectLogic)

  // i2c <> outer
  i2c.io.RST := reset
  i2c.io.SYS_CLK := clock
  i2c.io.ADDR := io.addr
  i2c.io.SCL_ext_i := io.i.scl
  i2c.io.SDA_ext_i := io.i.sda
  io.o.scl := i2c.io.SCL_o
  io.o.sda := i2c.io.SDA_o
  io.t.scl := i2c.io.SCL_t
  io.t.sda := i2c.io.SDA_t

  // i2c <> regIntf
  i2c.io.SEND_BUFFER := reg.io.SEND_BUFFER
  reg.io.STOP_DETECT := i2c.io.STOP_DETECT_o
  reg.io.INDEX_POINTER := i2c.io.INDEX_POINTER_o
  reg.io.WRITE_ENABLE := i2c.io.WRITE_ENABLE_o
  reg.io.RECEIVE_BUFFER := i2c.io.RECEIVE_BUFFER

  // regIntf <> detect
  reg.io.detect <> detect.io.reg
  detect.io.reg.COMM_VALID := reg.io.detect.COMM_VALID && !reg.io.detect.COMM_DATA(31)

  // detect <> outer
  detect.io.trigger_axis <> io.trigger_axis
  detect.io.apm <> io.apm

  // Bypass
  io.s_axi <> io.m_axi

  // Address map
  List((io.m_axi.ar.bits, io.s_axi.ar.bits, detect.io.rTag),
       (io.m_axi.aw.bits, io.s_axi.aw.bits, detect.io.wTag)).foreach { case (m, s, map) =>
      map.tag := s.user
      m.addr := Mux(map.matched, s.addr & (~map.mask).asUInt | map.base, 0.U)
  }

  // Traffic control
  val buckets = Seq.fill(nEntries){ Module(new TokenBucket) }
  buckets.zipWithIndex.foreach { case (bucket, i) =>
    List((bucket.io.read, io.s_axi.ar), (bucket.io.write, io.s_axi.aw)).foreach { case (bktCh, axiCh) =>
      bktCh.valid := axiCh.valid && (detect.io.dsids(i) === axiCh.bits.user)
      bktCh.ready := axiCh.ready
      bktCh.bits := (axiCh.bits.len + 1.U) << axiCh.bits.size
    }
    bucket.io.bucket := detect.io.buckets(i)
    io.l1enable(i) := detect.io.l1enables(i) && bucket.io.enable
  }
}

object MIG extends App {
  Driver.execute(args, () => new MigControlPlane()(MigConfig))
}
