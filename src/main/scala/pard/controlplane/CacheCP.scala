// See LICENSE for license details.

package pard.cp

import Chisel._
import uncore.agents.{NWays}
import cde.{Parameters}


class CachePartitionConfigIO(implicit p: Parameters) extends ControlPlaneBundle {
  val en = Bool(INPUT)
  val dsid = UInt(INPUT, width = dsidBits)
  val waymask = UInt(OUTPUT, width = p(NWays))
  val access = Bool(INPUT)
  val miss = Bool(INPUT)
  override def cloneType = (new CachePartitionConfigIO).asInstanceOf[this.type]
}

class CacheControlPlaneIO(implicit p: Parameters) extends ControlPlaneBundle {
  val rw = (new ControlPlaneRWIO).flip
  val cacheConfig = new CachePartitionConfigIO
}

class CacheControlPlaneModule(implicit p: Parameters) extends ControlPlaneModule {
  val io = IO(new CacheControlPlaneIO)
  val cpIdx = UInt(cacheCpIdx)

  // ptab
  val waymaskCol = 0
  val ptabWaymaskRegs = Reg(Vec(nDsids, UInt(width = p(NWays))))

  // stab
  val accessCounterCol = 0
  val missCounterCol = 1
  val accessCounterRegs = Reg(Vec(nDsids, UInt(width = cpDataSize)))
  val missCounterRegs = Reg(Vec(nDsids, UInt(width = cpDataSize)))

  when (reset) {
    for (i <- 0 until nDsids)
      ptabWaymaskRegs(i) := UInt((BigInt(1) << p(NWays)) - 1)
    accessCounterRegs foreach {case a => a := 0.U }
    missCounterRegs foreach {case a => a := 0.U }
  }

  val cpRen = io.rw.ren
  val cpWen = io.rw.wen
  val cpRWEn = cpRen || cpWen

  val cache = io.cacheConfig
  val cacheRWEn = cache.en
  val dsid = cache.dsid
  val access = cache.access
  val miss = cache.miss

  // read
  val rtab = getTabFromAddr(io.rw.raddr)
  val rrow = getRowFromAddr(io.rw.raddr)
  val rcol = getColFromAddr(io.rw.raddr)

  val waymaskRdata = ptabWaymaskRegs(Mux(cpRWEn, rrow, dsid))
  val accessRdata = accessCounterRegs(Mux(cpRWEn, rrow, dsid))
  val missRdata = missCounterRegs(Mux(cpRWEn, rrow, dsid))

  // write
  val wtab = getTabFromAddr(io.rw.waddr)
  val wrow = getRowFromAddr(io.rw.waddr)
  val wcol = getColFromAddr(io.rw.waddr)

  val cpAccessWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(accessCounterCol)
  val cpMissWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(missCounterCol)
  val accessWen = (cacheRWEn && !cpRWEn) || cpAccessWen
  val missWen = (cacheRWEn && !cpRWEn) || cpMissWen
  val accessWdata = Mux(cpRWEn, io.rw.wdata,
    Mux(access, accessRdata + UInt(1), accessRdata))
  val missWdata = Mux(cpRWEn, io.rw.wdata,
    Mux(miss, missRdata + UInt(1), missRdata))

  when (accessWen) {
    accessCounterRegs(Mux(cpRWEn, wrow, dsid)) := accessWdata
  }
  when (missWen) {
    missCounterRegs(Mux(cpRWEn, wrow, dsid)) := missWdata
  }

  // ControlPlaneIO
  // read decoding
  when (cpRen) {
    val ptabData = MuxLookup(rcol, UInt(0), Array(
      UInt(waymaskCol)   -> waymaskRdata
    ))

	val stabData = MuxLookup(rcol, UInt(0), Array(
	  UInt(accessCounterCol)   -> accessRdata,
	  UInt(missCounterCol)   -> missRdata
	))

	io.rw.rdata := MuxLookup(rtab, UInt(0), Array(
	  UInt(ptabIdx)   -> ptabData,
	  UInt(stabIdx)   -> stabData
	))
  }

  // write
  // write decoding
  when (cpWen) {
    switch (wtab) {
      is (UInt(ptabIdx)) {
        switch (wcol) {
          is (UInt(waymaskCol)) {
            ptabWaymaskRegs(wrow) := io.rw.wdata
          }
        }
      }
    }
  }

  // CacheConfigIO
  cache.waymask := waymaskRdata
}
