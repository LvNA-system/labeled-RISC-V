// See LICENSE for license details.

package pard.cp

import Chisel._
import cde.{Parameters, Field}
import rocketchip.ExtMemSize
import uncore.agents.{NWays}
import uncore.devices.{NTiles}
import uncore.tilelink.{DsidBits}

case object UseSim extends Field[Boolean]

trait HasControlPlaneParameters {
  implicit val p: Parameters
  val dsidBits = p(DsidBits)
  val nDsids = 1 << dsidBits
  val nTiles = p(NTiles)
  val cpAddrSize = 32
  val cpDataSize = 64

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
  def getTabFromAddr(addr: UInt) = addr(tabIdxHigh, tabIdxLow)
  def getCpFromAddr(addr: UInt)  = addr(cpIdxHigh, cpIdxLow)
}

abstract class ControlPlaneBundle(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters
abstract class ControlPlaneModule(implicit val p: Parameters) extends Module with HasControlPlaneParameters

class ControlPlaneRWIO(implicit p: Parameters) extends ControlPlaneBundle
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

class ControlPlaneIO(implicit p: Parameters) extends ControlPlaneBundle {
  val rw = (new ControlPlaneRWIO).flip
  val dsidConfig = new DsidConfigIO
  val hartidConfig = new HartidConfigIO
  val addressMapperConfig = new AddressMapperConfigIO
  val tokenBucketConfig = new TokenBucketConfigIO
  val memMonitor = new MemMonitorIO
  val cachePartitionConfig = new CachePartitionConfigIO
}

class ControlPlaneTopModule(implicit p: Parameters) extends ControlPlaneModule {
  val io = IO(new ControlPlaneIO)
  val coreCP = Module(new CoreControlPlaneModule)
  val cacheCP = Module(new CacheControlPlaneModule)
  val memCP = Module(new MemControlPlaneModule)

  io.cachePartitionConfig <> cacheCP.io.cacheConfig
  io.dsidConfig <> coreCP.io.dsidConfig
  io.hartidConfig <> coreCP.io.hartidConfig
  io.addressMapperConfig <> coreCP.io.addressMapperConfig
  io.tokenBucketConfig <> memCP.io.tokenBucketConfig
  io.memMonitor <> memCP.io.memMonitor

  val rcpIdx = getCpFromAddr(io.rw.raddr)
  val wcpIdx = getCpFromAddr(io.rw.waddr)
  coreCP.io.rw <> io.rw
  cacheCP.io.rw <> io.rw
  memCP.io.rw <> io.rw

  coreCP.io.rw.ren := io.rw.ren && (coreCP.cpIdx === rcpIdx)
  coreCP.io.rw.wen := io.rw.wen && (coreCP.cpIdx === wcpIdx)
  cacheCP.io.rw.ren := io.rw.ren && (cacheCP.cpIdx === rcpIdx)
  cacheCP.io.rw.wen := io.rw.wen && (cacheCP.cpIdx === wcpIdx)
  memCP.io.rw.ren := io.rw.ren && (memCP.cpIdx === rcpIdx)
  memCP.io.rw.wen := io.rw.wen && (memCP.cpIdx === wcpIdx)

  io.rw.rdata := MuxLookup(rcpIdx, UInt(0), Array(
    coreCP.cpIdx -> coreCP.io.rw.rdata,
    cacheCP.cpIdx -> cacheCP.io.rw.rdata,
    memCP.cpIdx -> memCP.io.rw.rdata
  ))
}
