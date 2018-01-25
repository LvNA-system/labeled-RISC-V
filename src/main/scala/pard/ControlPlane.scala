// See LICENSE for license details.

package rocketchip

import chisel3._
import cde.{Parameters}
import uncore.agents.{NWays}
import uncore.devices.{NTiles}


object ControlPlaneConsts {
  def cpAddrSize = 32
  def cpDataSize = 32

  def cpRead = Bool(true)
  def cpWrite = Bool(false)
}

class AddressMapperConfigIO(implicit val p: Parameters) extends Bundle {
  val bases = Output(Vec(p(NTiles), UInt(width = ControlPlaneConsts.cpDataSize)))
  val sizes = Output(Vec(p(NTiles), UInt(width = ControlPlaneConsts.cpDataSize)))
  override def cloneType = (new AddressMapperConfigIO).asInstanceOf[this.type]
}

class TokenBucketConfigIO(implicit val p: Parameters) extends Bundle {
  val sizes = Output(Vec(p(NDsids), UInt(width = ControlPlaneConsts.cpDataSize)))
  val freqs = Output(Vec(p(NDsids), UInt(width = ControlPlaneConsts.cpDataSize)))
  val incs = Output(Vec(p(NDsids), UInt(width = ControlPlaneConsts.cpDataSize)))
  override def cloneType = (new TokenBucketConfigIO).asInstanceOf[this.type]
}

class CachePartitionConfigIO(implicit val p: Parameters) extends Bundle {
  val nWays = Output(Vec(p(NDsids), UInt(width = ControlPlaneConsts.cpDataSize)))
  val dsidMaps = Output(Vec(p(NDsids), Vec(p(NWays), UInt(width = ControlPlaneConsts.cpDataSize))))
  val dsidMasks = Output(Vec(p(NDsids), UInt(width = ControlPlaneConsts.cpDataSize)))
  override def cloneType = (new CachePartitionConfigIO).asInstanceOf[this.type]
}

class ControlPlaneRWIO(implicit val p: Parameters) extends Bundle {
  // read
  val ren = Output(Bool())
  val raddr = Output(UInt(width = ControlPlaneConsts.cpAddrSize))
  val rdata = Input(UInt(width = ControlPlaneConsts.cpDataSize))

  // write
  val wen = Output(Bool())
  val waddr = Output(UInt(width = ControlPlaneConsts.cpAddrSize))
  val wdata = Output(UInt(width = ControlPlaneConsts.cpDataSize))
  override def cloneType = (new ControlPlaneRWIO).asInstanceOf[this.type]
}

class ControlPlaneIO(implicit val p: Parameters) extends Bundle {
  val rw = (new ControlPlaneRWIO).flip
  val addressMapperConfig = new AddressMapperConfigIO
  val tokenBucketConfig = new TokenBucketConfigIO
  val cachePartitionConfig = new CachePartitionConfigIO
}

class ControlPlaneModule(implicit p: Parameters) extends Module {
  val io = IO(new ControlPlaneIO)

  val amBasesBase = 0
  val amSizesBase = amBasesBase + p(NTiles)

  val tbSizesBase = amSizesBase + p(NTiles)
  val tbFreqsBase = tbSizesBase + p(NDsids)
  val tbIncsBase = tbFreqsBase + p(NDsids)


  val cpNWaysBase = tbIncsBase + p(NDsids)
  val cpDsidMapsBase = cpNWaysBase + p(NDsids)
  val cpDsidMasksBase = cpDsidMapsBase + p(NDsids) * p(NWays)
  val nReg = cpDsidMasksBase + p(NDsids)

  // register read/write should be single cycle
  val cpRegs = Reg(Vec(nReg, UInt(width = ControlPlaneConsts.cpDataSize)))

  val size = p(ExtMemSize) / p(NTiles)

  // initialize the registers with valid content
  when (reset) {
    for (i <- 0 until p(NTiles))
      cpRegs(amBasesBase + i) := UInt(0x80000000L + size * i)
    for (i <- 0 until p(NTiles))
      cpRegs(amSizesBase + i):= UInt(size)

    for (i <- 0 until p(NDsids))
      cpRegs(tbSizesBase + i) := 32.U
    for (i <- 0 until p(NDsids))
      cpRegs(tbFreqsBase + i) := 32.U
    for (i <- 0 until p(NDsids))
      cpRegs(tbIncsBase + i) := 32.U

    for (i <- 0 until p(NDsids))
      cpRegs(cpNWaysBase + i) := p(NWays).U
    for (i <- 0 until p(NDsids))
      for (j <- 0 until p(NWays))
        cpRegs(cpDsidMapsBase + i * p(NWays) + j) := j.U
	/*
    for (i <- 0 until p(NDsids))
      cpRegs(cpDsidMasksBase + i) := 0xffffff.U
	*/
	cpRegs(cpDsidMasksBase + 0) := 0xffffff.U
	cpRegs(cpDsidMasksBase + 1) := 0x00aaaa.U
	cpRegs(cpDsidMasksBase + 2) := 0x005555.U
  }

  // do no sanity check!
  when (io.rw.ren) { io.rw.rdata := cpRegs(io.rw.raddr) }
  when (io.rw.wen) { cpRegs(io.rw.waddr) := io.rw.wdata }

  // wire out cpRegs
  for (i <- 0 until p(NTiles))
    io.addressMapperConfig.bases(i) := cpRegs(amBasesBase + i)
  for (i <- 0 until p(NTiles))
    io.addressMapperConfig.sizes(i) := cpRegs(amSizesBase + i)

  for (i <- 0 until p(NDsids))
    io.tokenBucketConfig.sizes(i) := cpRegs(tbSizesBase + i)
  for (i <- 0 until p(NDsids))
    io.tokenBucketConfig.freqs(i) := cpRegs(tbFreqsBase + i)
  for (i <- 0 until p(NDsids))
    io.tokenBucketConfig.incs(i) := cpRegs(tbIncsBase + i)

  for (i <- 0 until p(NDsids))
    io.cachePartitionConfig.nWays(i) := cpRegs(cpNWaysBase + i)
  for (i <- 0 until p(NDsids) * p(NWays))
    io.cachePartitionConfig.dsidMaps(i / p(NWays))(i % p(NWays)) := cpRegs(cpDsidMapsBase + i)
  for (i <- 0 until p(NDsids))
    io.cachePartitionConfig.dsidMasks(i) := cpRegs(cpDsidMasksBase + i)
}
