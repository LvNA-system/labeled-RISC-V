// See LICENSE for license details.

package pard.cp

import Chisel._
import cde.{Parameters, Field}
import rocketchip.ExtMemSize
import uncore.agents.{NWays}
import uncore.devices.{NTiles}

case object NDsids extends Field[Int]

trait HasControlPlaneParameters {
  val cpAddrSize = 32
  val cpDataSize = 32

  // control plane register address space
  // 31     23        21     11       0
  // +-------+--------+-------+-------+
  // | cpIdx | tabIdx |  col  |  row  |
  // +-------+--------+-------+-------+
  //  \- 8 -/ \-  2 -/ \- 10-/ \- 12 -/

  val rowIdxLen = 12
  val colIdxLen = 10
  val tabIdxLen = 2
  val cpIdxLen = 8

  val rowIdxLow = 0
  val colIdxLow = rowIdxLow + rowIdxLen
  val tabIdxLow = colIdxLow + colIdxLen
  val cpIdxLow  = tabIdxLow + tabIdxLen

  val rowIdxHigh = colIdxLow - 1
  val colIdxHigh = tabIdxLow - 1
  val tabIdxHigh = cpIdxLow  - 1
  val cpIdxHigh  = 31

  // control plane index
  val coreCpIdx = 0
  val memCpIdx = 1
  val cacheCpIdx = 2
  val ioCpIdx = 3

  // tables
  val ptabIdx = 0
  val stabIdx = 1
  val ttabIdx = 2

  def getRowFromAddr(addr: UInt) = addr(rowIdxHigh, rowIdxLow)
  def getColFromAddr(addr: UInt) = addr(colIdxHigh, colIdxLow)
  def getCpFromAddr(addr: UInt)  = addr(cpIdxHigh, cpIdxLow)
}

abstract class ControlPlaneBundle extends Bundle with HasControlPlaneParameters
abstract class ControlPlaneModule extends Module with HasControlPlaneParameters

class ControlPlaneRWIO(implicit val p: Parameters) extends ControlPlaneBundle
  with HasControlPlaneParameters {
  // read
  val ren = Bool(OUTPUT)
  val raddr = UInt(OUTPUT, width = cpAddrSize)
  val rdata = UInt(INPUT, width = cpDataSize)

  // write
  val wen = Bool(OUTPUT)
  val waddr = UInt(OUTPUT, width = cpAddrSize)
  val wdata = UInt(OUTPUT, width = cpDataSize)
  override def cloneType = (new ControlPlaneRWIO).asInstanceOf[this.type]
}

class ControlPlaneIO(implicit val p: Parameters) extends ControlPlaneBundle {
  val rw = (new ControlPlaneRWIO).flip
  val addressMapperConfig = new AddressMapperConfigIO
  val tokenBucketConfig = new TokenBucketConfigIO
  val cachePartitionConfig = new CachePartitionConfigIO
}

class ControlPlaneModule2(implicit p: Parameters) extends ControlPlaneModule {
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
  val cpRegs = Reg(Vec(nReg, UInt(width = cpDataSize)))

  val size = p(ExtMemSize)

  // initialize the registers with valid content
  when (reset) {
    for (i <- 0 until p(NTiles))
      cpRegs(amBasesBase + i) := UInt(0x0L) // make this invalid
    for (i <- 0 until p(NTiles))
      cpRegs(amSizesBase + i):= UInt(size)

    for (i <- 0 until p(NDsids))
      cpRegs(tbSizesBase + i) := 1.U
    for (i <- 0 until p(NDsids))
      cpRegs(tbFreqsBase + i) := 0.U
    for (i <- 0 until p(NDsids))
      cpRegs(tbIncsBase + i) := 1.U

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
