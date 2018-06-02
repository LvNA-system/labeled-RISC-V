// See LICENSE for license details.

package pard.cp

import Chisel._
import cde.{Parameters}


class CacheMonitorIO(implicit p: Parameters) extends ControlPlaneBundle {
  val cen = Vec(nTiles, Bool()).asInput
  val ucen = Vec(nTiles, Bool()).asInput
  override def cloneType = (new CacheMonitorIO).asInstanceOf[this.type]
}
class TokenBucketConfigIO(implicit p: Parameters) extends ControlPlaneBundle {
  val sizes = Vec(nTiles, UInt(OUTPUT, width = 16))
  val freqs = Vec(nTiles, UInt(OUTPUT, width = 16))
  val incs  = Vec(nTiles, UInt(OUTPUT, width = 16))
  val dsid = Vec(nTiles, UInt(OUTPUT, width = dsidBits))

  override def cloneType = (new TokenBucketConfigIO).asInstanceOf[this.type]
}

class MemControlPlaneIO(implicit p: Parameters) extends ControlPlaneBundle {
  val rw = (new ControlPlaneRWIO).flip
  val tokenBucketConfig = new TokenBucketConfigIO
  val cacheMonitor = new CacheMonitorIO
}

class MemControlPlaneModule(implicit p: Parameters) extends ControlPlaneModule {
  val io = IO(new MemControlPlaneIO)
  val cpIdx = UInt(memCpIdx)

  // ptab
  val sizeCol = 0
  val sizeRegs = Reg(Vec(nTiles, UInt(width = 16)))
  val freqCol = 1
  val freqRegs = Reg(Vec(nTiles, UInt(width = 16)))
  val incCol = 2
  val incRegs = Reg(Vec(nTiles, UInt(width = 16)))
  val dsidCol = 3
  val dsidRegs = Reg(Vec(nTiles, UInt(width = dsidBits)))

  // stab
  val cachedTLCounterCol = 0
  val uncachedTLCounterCol = 1
  val cachedTLCounterRegs = Reg(Vec(nTiles, UInt(width = 32)))
  val uncachedTLCounterRegs = Reg(Vec(nTiles, UInt(width = 32)))

  when (reset) {
    for (i <- 0 until nTiles) {
      if (p(UseSim)) {
        sizeRegs(i) := 32.U
        freqRegs(i) := 128.U
        incRegs(i) := 1.U
      }
      else {
        freqRegs(i) := 0.U
      }
      cachedTLCounterRegs(i) := 0.U
      uncachedTLCounterRegs(i) := 0.U
    }
  }

  val cpRen = io.rw.ren
  val cpWen = io.rw.wen
  val cpRWEn = cpRen || cpWen

  val monitor = io.cacheMonitor

  // read
  val rtab = getTabFromAddr(io.rw.raddr)
  val rrow = getRowFromAddr(io.rw.raddr)
  val rcol = getColFromAddr(io.rw.raddr)

  // write
  val wtab = getTabFromAddr(io.rw.waddr)
  val wrow = getRowFromAddr(io.rw.waddr)
  val wcol = getColFromAddr(io.rw.waddr)

  val cpCachedTLCounterWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(cachedTLCounterCol)
  val cpWriteCounterWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(uncachedTLCounterCol)

  ((monitor.cen zip monitor.ucen) zipWithIndex).foreach {case ((mcen,mucen),idx) =>
    val cachedTLCounterWen = (mcen && !cpRWEn) || (cpCachedTLCounterWen && wrow===UInt(idx))
    val uncachedTLCounterWen = (mucen && !cpRWEn) || (cpWriteCounterWen && wrow===UInt(idx))

    val cachedTLCounterRdata = cachedTLCounterRegs(idx)
    val uncachedTLCounterRdata = uncachedTLCounterRegs(idx)

    val cachedTLCounterWdata = Mux(cpRWEn, io.rw.wdata, cachedTLCounterRdata + UInt(1))
    val uncachedTLCounterWdata = Mux(cpRWEn, io.rw.wdata, uncachedTLCounterRdata + UInt(1))

    when (cachedTLCounterWen) {
      cachedTLCounterRegs(idx) := cachedTLCounterWdata
    }
    when (uncachedTLCounterWen) {
      uncachedTLCounterRegs(idx) := uncachedTLCounterWdata
    }
  }

  io.rw.rready := true.B
  // ControlPlaneIO
  // read decoding
  when (cpRen) {
    val ptabData = MuxLookup(rcol, UInt(0), Array(
      UInt(sizeCol)   -> sizeRegs(rrow),
      UInt(freqCol)   -> freqRegs(rrow),
      UInt(incCol)   -> incRegs(rrow),
      UInt(dsidCol)  -> dsidRegs(rrow)
    ))

    val stabData = MuxLookup(rcol, UInt(0), Array(
      UInt(cachedTLCounterCol)   -> cachedTLCounterRegs(rrow),
      UInt(uncachedTLCounterCol)   -> uncachedTLCounterRegs(rrow)
    ))

    val rdata = MuxLookup(rtab, UInt(0), Array(
      UInt(ptabIdx)   -> ptabData,
      UInt(stabIdx)   -> stabData
    ))
    io.rw.rdata := RegNext(rdata)
  }

  // write
  // write decoding
  when (cpWen) {
    switch (wtab) {
      is (UInt(ptabIdx)) {
        switch (wcol) {
          is (UInt(sizeCol)) {
            sizeRegs(wrow) := io.rw.wdata
          }
          is (UInt(freqCol)) {
            freqRegs(wrow) := io.rw.wdata
          }
          is (UInt(incCol)) {
            incRegs(wrow) := io.rw.wdata
          }
          is (UInt(dsidCol)) {
            dsidRegs(wrow) := io.rw.wdata
          }
        }
      }
    }
  }

  // wire out cpRegs
  (io.tokenBucketConfig.sizes zip sizeRegs) ++
    (io.tokenBucketConfig.freqs zip freqRegs) ++
    (io.tokenBucketConfig.incs zip incRegs) ++
	(io.tokenBucketConfig.dsid zip dsidRegs) map { case (o, i) => o := i }
}
