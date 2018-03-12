// See LICENSE for license details.

package pard.cp

import Chisel._
import cde.{Parameters}
import uncore.agents.{NWays, NSets}
import coreplex.UseL2


class CachePartitionConfigIO(implicit p: Parameters) extends ControlPlaneBundle {
  // need to retrive waymask in the same cycle, not latched
  val dsid = UInt(INPUT, width = dsidBits)
  val waymask = UInt(OUTPUT, width = if (p(UseL2)) p(NWays) else 1)

  val curr_dsid = UInt(INPUT, width = dsidBits)
  val replaced_dsid = UInt(INPUT, width = dsidBits)
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

  val nWays = if (p(UseL2)) p(NWays) else 1
  val nSets = if (p(UseL2)) p(NSets) else 1

  // ptab
  val waymaskCol = 0
  val ptabWaymaskRegs = Reg(Vec(nDsids, UInt(width = nWays)))

  // stab
  val accessCounterCol = 0
  val missCounterCol = 1
  val usageCounterCol = 2
  val accessCounterRegs = Reg(Vec(nDsids, UInt(width = cpDataSize)))
  val missCounterRegs = Reg(Vec(nDsids, UInt(width = cpDataSize)))
  val usageCounterRegs = Reg(Vec(nDsids, UInt(width = cpDataSize)))

  when (reset) {
    for (i <- 0 until nDsids)
      ptabWaymaskRegs(i) := UInt((BigInt(1) << nWays) - 1)
    accessCounterRegs foreach {case a => a := 0.U }
    missCounterRegs foreach {case a => a := 0.U }
    usageCounterRegs foreach {case a => a := 0.U }
  }

  val cpRen = io.rw.ren
  val cpWen = io.rw.wen
  val cpRWEn = cpRen || cpWen

  val cache = io.cacheConfig
  val dsid = cache.dsid

  // latched to avoid long signal path
  val cacheRWEn = RegNext(cache.access)
  val curr_dsid = RegNext(cache.curr_dsid)
  val replaced_dsid = RegNext(cache.replaced_dsid)
  val access = RegNext(cache.access)
  val miss = RegNext(cache.miss)

  // read
  val rtab = getTabFromAddr(io.rw.raddr)
  val rrow = getRowFromAddr(io.rw.raddr)
  val rcol = getColFromAddr(io.rw.raddr)

  val waymaskRdata = ptabWaymaskRegs(Mux(cpRWEn, rrow, dsid))
  val accessRdata = accessCounterRegs(Mux(cpRWEn, rrow, curr_dsid))
  val missRdata = missCounterRegs(Mux(cpRWEn, rrow, curr_dsid))
  val currentUsageRdata = usageCounterRegs(Mux(cpRWEn, rrow, curr_dsid))
  val replacedUsageRdata = usageCounterRegs(Mux(cpRWEn, rrow, replaced_dsid))

  // write
  val wtab = getTabFromAddr(io.rw.waddr)
  val wrow = getRowFromAddr(io.rw.waddr)
  val wcol = getColFromAddr(io.rw.waddr)

  val cpAccessWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(accessCounterCol)
  val accessWen = (cacheRWEn && !cpRWEn) || cpAccessWen

  val cpMissWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(missCounterCol)
  val cacheMissWen = cacheRWEn && miss && !cpRWEn
  val missWen = cacheMissWen || cpMissWen

  val cpUsageWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(usageCounterCol)
  // corner case: curr_dsid == replaced_dsid
  // in this case, do not update, or increment and decrement will race
  val cacheUsageWen = cacheRWEn && miss && curr_dsid != replaced_dsid && !cpRWEn
  val usageWen = cacheUsageWen || cpUsageWen

  val accessWdata = Mux(cpRWEn, io.rw.wdata,
    Mux(access, accessRdata + UInt(1), accessRdata))
  val missWdata = Mux(cpRWEn, io.rw.wdata,
    Mux(miss, missRdata + UInt(1), missRdata))

  val overflow = currentUsageRdata === UInt(nSets * nWays)
  val underflow = replacedUsageRdata === UInt(0)
  val currentUsageWdata = Mux(cpRWEn, io.rw.wdata,
    Mux(miss && !overflow, currentUsageRdata + UInt(1), currentUsageRdata))
  val replacedUsageWdata = Mux(cpRWEn, io.rw.wdata,
    Mux(miss && !underflow, replacedUsageRdata - UInt(1), replacedUsageRdata))

  when (accessWen) {
    accessCounterRegs(Mux(cpRWEn, wrow, curr_dsid)) := accessWdata
  }
  when (missWen) {
    missCounterRegs(Mux(cpRWEn, wrow, curr_dsid)) := missWdata
  }
  when (usageWen) {
    usageCounterRegs(Mux(cpRWEn, wrow, curr_dsid)) := currentUsageWdata
    when (cacheUsageWen) {
      usageCounterRegs(replaced_dsid) := replacedUsageWdata
    }
  }

  // ControlPlaneIO
  // read decoding
  when (cpRen) {
    val ptabData = MuxLookup(rcol, UInt(0), Array(
      UInt(waymaskCol)   -> waymaskRdata
    ))

	val stabData = MuxLookup(rcol, UInt(0), Array(
	  UInt(accessCounterCol)   -> accessRdata,
	  UInt(missCounterCol)   -> missRdata,
	  UInt(usageCounterCol)   -> currentUsageRdata
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
