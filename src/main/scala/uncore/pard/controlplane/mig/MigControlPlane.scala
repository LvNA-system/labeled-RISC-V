package uncore.pard

import chisel3._
import chisel3.util._
import freechips.rocketchip.config._
import freechips.rocketchip.amba.axi4._


class APMBundle extends Bundle {
  val valid = Input(Bool())
  val addr = Input(UInt(32.W))
  val data = Input(UInt(32.W))
}


class MigControlPlaneIO(implicit p: Parameters) extends ControlPlaneIO {
  val l1enable = Output(Vec(p(NEntries), Bool()))
  val apm = new APMBundle
  val s_axi =  Flipped(AXI4Bundle(AXI4BundleParameters(p(AddrBits), p(DataBits), 5, 16, 0)))
  val m_axi = AXI4Bundle(AXI4BundleParameters(p(AddrBits), p(DataBits), 5, 16, 0))
}


class MigControlPlane(implicit p: Parameters)
    extends ControlPlane(new MigControlPlaneIO, new MigDetectLogic)('M', "PARDMig7CP") {
  // detect <> outer
  detect.io.reg_interface.COMM_VALID := reg_interface.io.detect.COMM_VALID && !reg_interface.io.detect.COMM_DATA(31)
  detect.io.apm <> io.apm

  // Bypass
  io.s_axi <> io.m_axi

  // Address map
  List((io.m_axi.ar.bits, io.s_axi.ar.bits, detect.io.rTag),
       (io.m_axi.aw.bits, io.s_axi.aw.bits, detect.io.wTag)).foreach { case (m, s, map) =>
      map.tag := s.user.get
      m.addr := Mux(map.matched, s.addr & (~map.mask).asUInt | map.base, 0.U)
  }

  // Traffic control
  val buckets = Seq.fill(p(NEntries)){ Module(new TokenBucket) }
  buckets.zipWithIndex.foreach { case (bucket, i) =>
    List((bucket.io.read, io.s_axi.ar), (bucket.io.write, io.s_axi.aw)).foreach { case (bktCh, axiCh) =>
      bktCh.valid := axiCh.valid && (detect.io.dsids(i) === axiCh.bits.user.get)
      bktCh.ready := axiCh.ready
      bktCh.bits := (axiCh.bits.len + 1.U) << axiCh.bits.size
    }
    bucket.io.bucket := detect.io.buckets(i)
    io.l1enable(i) := detect.io.l1enables(i) && bucket.io.enable
  }
}
