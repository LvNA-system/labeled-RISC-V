package uncore.pard

/**
 * Common part of various control planes
 */

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._

class I2CBundle extends Bundle {
  val scl = Bool()
  val sda = Bool()
}


class I2CBus extends Bundle {
  val i = Input(new I2CBundle)
  val t = Output(new I2CBundle)
  val o = Output(new I2CBundle)
}


class ControlPlaneIO extends Bundle {
  val addr = Input(UInt(7.W))  // Address to detect thsi cp used from i2c switch.
  val i2c = new I2CBus
  val trigger_axis = new DecoupledIO(UInt(16.W))
}


class DetectLogicIO(implicit p: Parameters) extends Bundle {
  val reg_interface = new RegisterInterfaceIO
  val trigger_axis = new DecoupledIO(UInt(16.W))
}


/**
 * Any specific ControlPlane should mix-in a trait that instantiate
 * this class' subclass.
 */
abstract class DetectLogic[+B <: DetectLogicIO](_io: => B)(implicit p: Parameters) extends Module {
  val io = IO(_io)
  val common = Module(new DetectLogicCommon)
  common.io.reg <> io.reg_interface

  def createPTab[T <: PTab[PTabIO]](gen: => T): T = {
    val ptab = Module(gen)
    common.io.ptab <> ptab.io.table
    common.io.cmd  <> ptab.io.cmd
    ptab
  }

  def createSTab[T <: STab[STabIO]](gen: => T): T = {
    val stab = Module(gen)
    common.io.stab <> stab.io.table
    common.io.cmd  <> stab.io.cmd
    stab
  }

  def createTTab(cpid: Int, stab: STab[STabIO], dsids: Vec[UInt]): TTab = {
    val ttab = Module(new TTab(cpid))
    ttab.io.fifo <> io.trigger_axis
    common.io.ttab <> ttab.io.table
    common.io.cmd <> ttab.io.cmd
    ttab.io.trigger_rdata := stab.io.trigger_rdata
    stab.io.trigger_metric := ttab.io.trigger_metric
    // Look up dsid
    val triggerDsidMatch = dsids.map{_ === ttab.io.trigger_dsid}
    val triggerRow = Mux1H(triggerDsidMatch, dsids.indices.map(_.U))
    val triggerDsidValid = PopCount(triggerDsidMatch) === 1.U  // Promise one hot
    stab.io.trigger_row := triggerRow
    ttab.io.trigger_dsid_valid := triggerDsidValid
    ttab
  }
}


/**
 * Any specific ControlPlane should inherit from this class
 * to perform common wiring-up.
 */
abstract class ControlPlane[B <: ControlPlaneIO, D <: DetectLogic[DetectLogicIO]]
    (_io: => B, _detect: => D)(cpType: Int, name: String)(implicit p: Parameters) extends Module {
  val io = IO(_io)
  val detect = Module(_detect)
  val i2c_interface = Module(new I2CInterface)
  val reg_interface = Module(new RegInterface(cpType, name))

  // outer <> i2c
  reset        <> i2c_interface.io.RST
  clock        <> i2c_interface.io.SYS_CLK
  io.addr      <> i2c_interface.io.ADDR
  io.i2c.i.scl <> i2c_interface.io.SCL_ext_i
  io.i2c.i.sda <> i2c_interface.io.SDA_ext_i
  io.i2c.o.scl <> i2c_interface.io.SCL_o
  io.i2c.o.sda <> i2c_interface.io.SDA_o
  io.i2c.t.scl <> i2c_interface.io.SCL_t
  io.i2c.t.sda <> i2c_interface.io.SDA_t

  // i2c <> reg
  i2c_interface.io.SEND_BUFFER     <> reg_interface.io.SEND_BUFFER
  i2c_interface.io.STOP_DETECT_o   <> reg_interface.io.STOP_DETECT
  i2c_interface.io.INDEX_POINTER_o <> reg_interface.io.INDEX_POINTER
  i2c_interface.io.WRITE_ENABLE_o  <> reg_interface.io.WRITE_ENABLE
  i2c_interface.io.RECEIVE_BUFFER  <> reg_interface.io.RECEIVE_BUFFER

  // reg <> detect
  reg_interface.io.detect <> detect.io.reg_interface

  // detect <> outer
  detect.io.trigger_axis <> io.trigger_axis
}
