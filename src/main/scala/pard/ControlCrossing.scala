package uncore.pard

import Chisel._
import uncore.tilelink.{ClientUncachedTileLinkIO, ClientTileLinkIO}
import cde.{Parameters, Config}

class ClientUncachedTileLinkControlCrossing(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val in = (new ClientUncachedTileLinkIO).flip
    val out = new ClientUncachedTileLinkIO
    val enable = Bool().asInput
  })
  
  io.out <> io.in
  io.in.acquire.ready := io.out.acquire.ready && io.enable
  io.out.acquire.valid := io.in.acquire.valid && io.enable
}

class ClientTileLinkControlCrossing(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val in = (new ClientTileLinkIO).flip
    val out = new ClientTileLinkIO
    val enable = Bool().asInput
  })

  io.out <> io.in
  io.in.acquire.ready := io.out.acquire.ready && io.enable
  io.out.acquire.valid := io.in.acquire.valid && io.enable
}
