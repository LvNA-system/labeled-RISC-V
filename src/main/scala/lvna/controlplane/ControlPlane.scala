package lvna

import Chisel._
import freechips.rocketchip.config.{Config, Field, Parameters}
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp}
import freechips.rocketchip.subsystem.{BaseSubsystem, HasRocketTiles, HasRocketTilesModuleImp, NTiles}
import freechips.rocketchip.tile.XLen

case object ProcDSidWidth extends Field[Int](3)

trait HasControlPlaneParameters {
  implicit val p: Parameters
  val nTiles = p(NTiles)
  val ldomDSidWidth = log2Up(nTiles)
  val procDSidWidth = p(ProcDSidWidth)
  val dsidWidth = ldomDSidWidth + procDSidWidth
}

/**
  * From ControlPlane's side of view.
  */
class ControlPlaneIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters {
  private val indexWidth = 32
  val dsid          = UInt(OUTPUT, ldomDSidWidth)
  val updateData    = UInt(INPUT, 32)
  val traffic       = UInt(OUTPUT, 32)
  val dsidWen       = Bool(INPUT)
  val memBase       = UInt(OUTPUT, p(XLen))
  val memBaseLoWen  = Bool(INPUT)
  val memBaseHiWen  = Bool(INPUT)
  val memMask       = UInt(OUTPUT, p(XLen))
  val memMaskLoWen  = Bool(INPUT)
  val memMaskHiWen  = Bool(INPUT)
  val bucket        = new BucketBundle().asOutput
  val bktFreqWen    = Bool(INPUT)
  val bktSizeWen    = Bool(INPUT)
  val bktIncWen     = Bool(INPUT)
  val sel           = UInt(OUTPUT, indexWidth)
  val selUpdate     = UInt(INPUT, indexWidth)
  val selWen        = Bool(INPUT)
}

class ControlPlane()(implicit p: Parameters) extends LazyModule
  with HasControlPlaneParameters
  with HasTokenBucketParameters
{
  private val memAddrWidth = p(XLen)

  override lazy val module = new LazyModuleImp(this) {
    val io = IO(new Bundle {
      val dsids = Vec(nTiles, UInt(ldomDSidWidth.W)).asOutput
      val memBases = Vec(nTiles, UInt(memAddrWidth.W)).asOutput
      val memMasks = Vec(nTiles, UInt(memAddrWidth.W)).asOutput
      val bucketParams = Vec(nTiles, new BucketBundle()).asOutput
      val traffics = Vec(nTiles, UInt(32.W)).asInput
      val cp = new ControlPlaneIO()
    })

    val dsids = RegInit(Vec(Seq.fill(nTiles)(1.U(ldomDSidWidth.W))))
    val dsidSel = RegInit(0.U(ldomDSidWidth.W))
    val memBases = RegInit(Vec(Seq.fill(nTiles)(0.U(memAddrWidth.W))))
    val memMasks = RegInit(Vec(Seq.fill(nTiles)(~(0.U(memAddrWidth.W)))))
    val bucketParams = RegInit(Vec(Seq.fill(nTiles){
      Cat(256.U(tokenBucketSizeWidth.W), 0.U(tokenBucketFreqWidth.W), 256.U(tokenBucketSizeWidth.W)).asTypeOf(new BucketBundle)
    }))
    val currDsid = dsids(dsidSel)

    io.cp.traffic := io.traffics(dsidSel)

    io.cp.dsid := currDsid
    io.cp.sel := dsidSel
    io.cp.memBase := memBases(dsidSel)
    io.cp.memMask := memMasks(dsidSel)
    io.cp.bucket := bucketParams(dsidSel)
    io.dsids := dsids
    io.memBases := memBases
    io.memMasks := memMasks
    io.bucketParams := bucketParams

    when (io.cp.selWen) {
      dsidSel := io.cp.selUpdate
    }

    when (io.cp.dsidWen) {
      dsids(dsidSel) := io.cp.updateData
    }

    val mem_base_lo_tmp = RegInit(0.U(32.W))
    val mem_mask_lo_tmp = RegInit(~0.U(32.W))

    when (io.cp.memBaseLoWen) {
      mem_base_lo_tmp := io.cp.updateData
    }

    when (io.cp.memBaseHiWen) {
      memBases(dsidSel) := Cat(io.cp.updateData, mem_base_lo_tmp)
    }

    when (io.cp.memMaskLoWen) {
      mem_mask_lo_tmp := io.cp.updateData
    }

    when (io.cp.memMaskHiWen) {
      memMasks(dsidSel) := Cat(io.cp.updateData, mem_mask_lo_tmp)
    }

    when (io.cp.bktFreqWen) {
      bucketParams(dsidSel).freq := io.cp.updateData
    }

    when (io.cp.bktSizeWen) {
      bucketParams(dsidSel).size := io.cp.updateData
    }

    when (io.cp.bktIncWen) {
      bucketParams(dsidSel).inc := io.cp.updateData
    }


    // AutoMBA goes here
    val regulationCycles = 1000000
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
      when (samplingCounter >= samplingCycles.U) {
        // estimate high priority app's memory bandwidth demand
        // set low priority app's bucket accordingly
        val bandwidthUsage = io.traffics(0) - startTraffic
        startTraffic := io.traffics(0)
        val estimatedBandwidth = startTraffic << 4
        // assume NTiles = 4
        val newFreq = (regulationCycles.U - estimatedBandwidth) >> 4

        for (i <- 1 until nTiles) {
          bucketParams(i).freq := newFreq
          bucketParams(i).block := false.B
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
        for (i <- 1 until nTiles) {
          bucketParams(i).block := true.B
        }
        samplingCounter := 0.U
        state := s_sample
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
    tile.module.dsid := cpio.dsids(i.U)
    tile.module.memBase := cpio.memBases(i.U)
    tile.module.memMask := cpio.memMasks(i.U)
    token.module.bucketParam := cpio.bucketParams(i.U)
    cpio.traffics(i) := token.module.traffic
  }

  outer.debug.module.io.cp <> outer.controlPlane.module.io.cp
}
