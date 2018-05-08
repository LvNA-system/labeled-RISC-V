// See LICENSE for license details.

package pard.cp

import Chisel._
import cde.{Parameters}


class MemMonitorIO(implicit p: Parameters) extends ControlPlaneBundle {
  val ren = Bool(INPUT)
  val readDsid = UInt(INPUT, width = dsidBits)
  val wen = Bool(INPUT)
  val writeDsid = UInt(INPUT, width = dsidBits)
  override def cloneType = (new MemMonitorIO).asInstanceOf[this.type]
}

class TokenBucketConfigIO(implicit p: Parameters) extends ControlPlaneBundle {
  val sizes = Vec(nTiles, UInt(OUTPUT, width = cpDataSize))
  val freqs = Vec(nTiles, UInt(OUTPUT, width = cpDataSize))
  val incs  = Vec(nTiles, UInt(OUTPUT, width = cpDataSize))
  override def cloneType = (new TokenBucketConfigIO).asInstanceOf[this.type]
}

class MemControlPlaneIO(implicit p: Parameters) extends ControlPlaneBundle {
  val rw = (new ControlPlaneRWIO).flip
  val tokenBucketConfig = new TokenBucketConfigIO
  val memMonitor = new MemMonitorIO
}

class MemControlPlaneModule(implicit p: Parameters) extends ControlPlaneModule {
  val io = IO(new MemControlPlaneIO)
  val cpIdx = UInt(memCpIdx)

  // ptab
  val sizeCol = 0
  val sizeRegs = Reg(Vec(nTiles, UInt(width = cpDataSize)))
  val freqCol = 1
  val freqRegs = Reg(Vec(nTiles, UInt(width = cpDataSize)))
  val incCol = 2
  val incRegs = Reg(Vec(nTiles, UInt(width = cpDataSize)))

  // stab
  val readCounterCol = 0
  val writeCounterCol = 1
  val readCounterRegs = Reg(Vec(nTiles, UInt(width = cpDataSize)))
  val writeCounterRegs = Reg(Vec(nTiles, UInt(width = cpDataSize)))

  when (reset) {
    for (i <- 0 until nTiles) {
      if (p(UseSim)) {
        sizeRegs(i) := 32.U
        freqRegs(i) := 0.U
        incRegs(i) := 32.U
      }
      else {
        freqRegs(i) := 0.U
      }
      readCounterRegs(i) := 0.U
      writeCounterRegs(i) := 0.U
    }
  }

  val cpRen = io.rw.ren
  val cpWen = io.rw.wen
  val cpRWEn = cpRen || cpWen

  val monitor = io.memMonitor

  // read
  val rtab = getTabFromAddr(io.rw.raddr)
  val rrow = getRowFromAddr(io.rw.raddr)
  val rcol = getColFromAddr(io.rw.raddr)

  val readCounterRdata = readCounterRegs(Mux(cpRWEn, rrow, monitor.readDsid))
  val writeCounterRdata = writeCounterRegs(Mux(cpRWEn, rrow, monitor.writeDsid))

  // write
  val wtab = getTabFromAddr(io.rw.waddr)
  val wrow = getRowFromAddr(io.rw.waddr)
  val wcol = getColFromAddr(io.rw.waddr)

  val cpReadCounterWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(readCounterCol)
  val cpWriteCounterWen = cpWen && wtab === UInt(stabIdx) && wcol === UInt(writeCounterCol)
  val readCounterWen = (monitor.ren && !cpRWEn) || cpReadCounterWen
  val writeCounterWen = (monitor.wen && !cpRWEn) || cpWriteCounterWen
  val readCounterWdata = Mux(cpRWEn, io.rw.wdata, readCounterRdata + UInt(1))
  val writeCounterWdata = Mux(cpRWEn, io.rw.wdata, writeCounterRdata + UInt(1))

  when (readCounterWen) {
    readCounterRegs(Mux(cpRWEn, wrow, monitor.readDsid)) := readCounterWdata
  }
  when (writeCounterWen) {
    writeCounterRegs(Mux(cpRWEn, wrow, monitor.writeDsid)) := writeCounterWdata
  }

  io.rw.rready := true.B
  // ControlPlaneIO
  // read decoding
  when (cpRen) {
    val ptabData = MuxLookup(rcol, UInt(0), Array(
      UInt(sizeCol)   -> sizeRegs(rrow),
      UInt(freqCol)   -> freqRegs(rrow),
      UInt(incCol)   -> incRegs(rrow)
    ))

    val stabData = MuxLookup(rcol, UInt(0), Array(
      UInt(readCounterCol)   -> readCounterRdata,
      UInt(writeCounterCol)   -> writeCounterRdata
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
        }
      }
    }
  }

  // wire out cpRegs
  (io.tokenBucketConfig.sizes zip sizeRegs) ++
    (io.tokenBucketConfig.freqs zip freqRegs) ++
    (io.tokenBucketConfig.incs zip incRegs) map { case (o, i) => o := i } 
}
