// See LICENSE for license details.

package pard

import Chisel._
import cde.{Parameters}
import uncore.agents.{NWays, NSets}
import coreplex.UseL2


class CachePartitionConfigIO(implicit p: Parameters) extends ControlPlaneBundle {
  val p_dsid = UInt(INPUT, width = dsidBits)
  val waymask = UInt(OUTPUT, width = if (p(UseL2)) p(NWays) else 1)

  val curr_dsid = UInt(INPUT, width = dsidBits)
  val replaced_dsid = UInt(INPUT, width = dsidBits)
  // is the victim way valid
  val victim_way_valid = Bool(INPUT)
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

  // stab
  val accessCounterCol = 0
  val missCounterCol = 1
  val usageCounterCol = 2

  val cpRen = io.rw.ren
  val cpWen = io.rw.wen
  val cpRWEn = cpRen || cpWen

  val cache = io.cacheConfig
  val dsid = cache.p_dsid

  // latched to avoid long signal path
  val cacheRWEn = RegNext(cache.access)
  val curr_dsid = RegNext(cache.curr_dsid)
  val replaced_dsid = RegNext(cache.replaced_dsid)
  val victim_way_valid = RegNext(cache.victim_way_valid)
  val access = RegNext(cache.access)
  val miss = RegNext(cache.miss)

  val alloc = access && miss
  val dealloc = miss && victim_way_valid
  val rready = !alloc && !dealloc && !access
  io.rw.rready := rready

  // read
  val rtab = getTabFromAddr(io.rw.raddr)
  val rrow = getRowFromAddr(io.rw.raddr)
  val rcol = getColFromAddr(io.rw.raddr)

  // write
  val wtab = getTabFromAddr(io.rw.waddr)
  val wrow = getRowFromAddr(io.rw.waddr)
  val wcol = getColFromAddr(io.rw.waddr)

  // ********** waymask **********
  val ptabWaymaskRegs = SeqMem(nDsids, UInt(width = nWays))
  val waymaskRdata = ptabWaymaskRegs.read(Mux(cpRen && rready, rrow, dsid))

  // ********** access/miss counters **********
  // because we are using SeqMem, which is sync read/write
  // update cache access/miss statistics have the following stages
  //   1. read out the old value
  //   2. update with old value + 1
  val accessCounterRegs = SeqMem(nDsids, UInt(width = 32))
  val missCounterRegs = SeqMem(nDsids, UInt(width = 32))

  val cacheAccessWen = cacheRWEn
  val cacheMissWen = cacheRWEn && miss
  // cp read access/miss conflict on read port with update in stage 1
  // we handle this with the rready signal
  val s0_dsid = Mux(rready, rrow, curr_dsid)
  val s1_dsid = RegNext(curr_dsid)
  val s1_access = RegNext(cacheAccessWen)
  val s1_miss = RegNext(cacheMissWen)

  val cpAccessWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(accessCounterCol)
  val accessWen = s1_access || cpAccessWen
  val cpMissWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(missCounterCol)
  val missWen = s1_miss || cpMissWen

  val accessMemdata = accessCounterRegs.read(s0_dsid)
  val missMemdata = missCounterRegs.read(s0_dsid)

  val accessWdata = Wire(UInt())
  val missWdata = Wire(UInt())
  val access_forward = (s1_access && s0_dsid === s1_dsid) || (cpAccessWen && s0_dsid === wrow)
  val s1_access_rdata_valid = RegNext(access_forward)
  val s1_access_rdata = RegNext(accessWdata)

  val miss_forward = (s1_miss && s0_dsid === s1_dsid) || (cpMissWen && s0_dsid === wrow)
  val s1_miss_rdata_valid = RegNext(miss_forward)
  val s1_miss_rdata = RegNext(missWdata)


  // cp write access/miss conflict on write port with update in stage 2
  // we handle this by drop the update signal
  val accessRdata = Mux(s1_access_rdata_valid, s1_access_rdata, accessMemdata)
  val missRdata = Mux(s1_miss_rdata_valid, s1_miss_rdata, missMemdata)
  accessWdata := Mux(cpAccessWen, io.rw.wdata, accessRdata + UInt(1))
  missWdata := Mux(cpMissWen, io.rw.wdata, missRdata + UInt(1))

  when (accessWen) {
    accessCounterRegs.write(Mux(cpAccessWen, wrow, s1_dsid), accessWdata)
  }
  when (missWen) {
    missCounterRegs.write(Mux(cpMissWen, wrow, s1_dsid), missWdata)
  }

  // ********** usage counters **********
  // usageCounter needs at least two write ports
  // eg: when dsid a replaced dsid b, then counter(a) increment and counter(b) decrement.
  // In order to fit usageCounter into SeqMem,
  // we count the number of alloc and dealloc of a dsid
  // eg: when dsid a replaced dsid b, then alloc(a) increment, dealloc(b) decrement
  // so usage(a) = alloc(a) - dealloc(a)
  // be careful about overflows
  val allocCounterRegs = SeqMem(nDsids, UInt(width = 32))
  val deallocCounterRegs = SeqMem(nDsids, UInt(width = 32))

  val allocValid = RegInit(Vec.fill(nDsids) {Bool(false)})
  val deallocValid = RegInit(Vec.fill(nDsids) {Bool(false)})

  val allocWdata = Wire(UInt())
  val deallocWdata = Wire(UInt())

  val alloc_dsid = Mux(rready, rrow, curr_dsid)
  val s1_alloc = RegNext(alloc)
  val s1_alloc_dsid = RegNext(alloc_dsid)
  val alloc_valid = allocValid(alloc_dsid)
  val alloc_forward = s1_alloc && s1_alloc_dsid === alloc_dsid
  val s1_alloc_rdata_valid = RegNext(!alloc_valid || alloc_forward)
  val s1_alloc_rdata = RegNext(Mux(alloc_forward, allocWdata, 0.U))

  val dealloc_dsid = Mux(rready, rrow, replaced_dsid)
  val s1_dealloc = RegNext(dealloc)
  val s1_dealloc_dsid = RegNext(dealloc_dsid)
  val dealloc_valid = deallocValid(dealloc_dsid)
  val dealloc_forward = s1_dealloc && s1_dealloc_dsid === dealloc_dsid
  val s1_dealloc_rdata_valid = RegNext(!dealloc_valid || dealloc_forward)
  val s1_dealloc_rdata = RegNext(Mux(dealloc_forward, deallocWdata, 0.U))

  val allocMemData = allocCounterRegs.read(alloc_dsid)
  val deallocMemData = deallocCounterRegs.read(dealloc_dsid)

  when (alloc) { allocValid(alloc_dsid) := true.B }
  when (dealloc) { deallocValid(dealloc_dsid) := true.B }

  val allocRdata = Mux(s1_alloc_rdata_valid, s1_alloc_rdata, allocMemData)
  allocWdata := allocRdata + UInt(1)
  val deallocRdata = Mux(s1_dealloc_rdata_valid, s1_dealloc_rdata, deallocMemData)
  deallocWdata := deallocRdata + UInt(1)
  when (s1_alloc) {
    allocCounterRegs.write(s1_alloc_dsid, allocWdata)
  }
  when (s1_dealloc) {
    deallocCounterRegs.write(s1_dealloc_dsid, deallocWdata)
  }

  // ControlPlaneIO
  // read decoding
  // read data becomes valid in the Next cycle
  val reg_rcol = RegEnable(rcol, cpRen)
  val reg_rtab = RegEnable(rtab, cpRen)

  when (RegNext(cpRen && rready)) {
    val ptabData = MuxLookup(reg_rcol, UInt(0), Array(
      UInt(waymaskCol)   -> waymaskRdata
    ))

    // deal with possible overflows
    val usageCount = Mux(allocRdata >= deallocRdata, allocRdata - deallocRdata,
      Cat(UInt(1, width = 1), allocRdata) - deallocRdata)
    assert(usageCount <= UInt(nWays * nSets))

    val stabData = MuxLookup(reg_rcol, UInt(0), Array(
      UInt(accessCounterCol)   -> accessRdata,
      UInt(missCounterCol)     -> missRdata,
      UInt(usageCounterCol)    -> usageCount
    ))

    io.rw.rdata := MuxLookup(reg_rtab, UInt(0), Array(
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
            ptabWaymaskRegs.write(wrow, io.rw.wdata)
          }
        }
      }
    }
  }

  // CacheConfigIO
  cache.waymask := waymaskRdata
}
