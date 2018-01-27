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
  val dsidConfig = new DsidConfigIO
  val addressMapperConfig = new AddressMapperConfigIO
  val tokenBucketConfig = new TokenBucketConfigIO
  val cachePartitionConfig = new CachePartitionConfigIO
}

class ControlPlaneTopModule(implicit p: Parameters) extends ControlPlaneModule {
  val io = IO(new ControlPlaneIO)
  val coreCP = Module(new CoreControlPlaneModule)

  io.dsidConfig <> coreCP.io.dsidConfig
  io.addressMapperConfig <> coreCP.io.addressMapperConfig

  val rcpIdx = getCpFromAddr(io.rw.raddr)
  val wcpIdx = getCpFromAddr(io.rw.waddr)
  coreCP.io.rw <> io.rw

  coreCP.io.rw.ren := io.rw.ren && (coreCP.cpIdx === rcpIdx)
  coreCP.io.rw.wen := io.rw.wen && (coreCP.cpIdx === wcpIdx)

  io.rw.rdata := MuxLookup(rcpIdx, UInt(0), Array(
    coreCP.cpIdx -> coreCP.io.rw.rdata
  ))
}
