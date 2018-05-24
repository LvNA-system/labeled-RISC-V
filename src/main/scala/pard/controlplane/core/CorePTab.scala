package uncore.pard

import chisel3._
import freechips.rocketchip.config._
import freechips.rocketchip.devices.debug.{DMIConsts, DebugModuleParams}

class CorePTabIO(implicit val p: Parameters)
  extends PTabIO
  with HasCoreIO


class CorePTab(implicit p: Parameters) extends PTab(new CorePTabIO) {
  val dsids = makeField(0.U(p(TagBits).W))()
  val states = makeField(false.B)()
  // Fields for debug module interface
  val req_valid = makeField(false.B)()
  val req_op = makeField(0.U(DMIConsts.dmiOpSize.W))()
  val req_addr = makeField(0.U(p(DebugModuleParams).nDMIAddrSize.W))()
  val req_data = makeField(0.U(DMIConsts.dmiDataSize.W))()
  val resp_valid = makeField(false.B, false.B, NoSet)()
  val resp_resp = makeField(0.U(DMIConsts.dmiRespSize.W), false.B, NoSet)()
  val resp_data = makeField(0.U(DMIConsts.dmiDataSize.W), false.B, NoSet)()

  io.dsid := dsids
  io.extReset := states
  io.table.data := makeRead(io.cmd.row, io.cmd.col)

  // Debug Module Logic
  val valid = req_valid.head
  val resp = resp_resp.head
  val data = resp_data.head

  when(valid) {
    resp := "b11".U
    data := "hFFFF_FFFF".U
    resp_valid.head := false.B
  }.elsewhen(io.debug.resp.fire) {
    resp := io.debug.resp.bits.resp
    data := io.debug.resp.bits.data
    resp_valid.head := true.B
  }

  when(io.debug.req.fire) {
    valid := false.B
  }

  io.debug.req.valid := valid
  io.debug.req.bits.op := req_op.head
  io.debug.req.bits.addr := req_addr.head
  io.debug.req.bits.data := req_data.head
  io.debug.resp.ready := true.B
}
