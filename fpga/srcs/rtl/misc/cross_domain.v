`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Frontier System Group, ICT
// Engineer: Jiuyue Ma
// 
// Create Date: 02/24/2016 09:47:09 AM
// Design Name: pardsys
// Module Name: system_top
// Project Name: pard_fpga_vc709
// Target Devices: xc7vx690tffg1761-2
// Tool Versions: Vivado 2014.4
// Description: 
//   This file contains signal synchronize logic for cross clock domain
//   design.
//    * Signal_CrossDomain: If a signal from clkA domain is needed in clkB
//      domain. It needs to be "synchronized" to clkB domain
//       - [ref] http://www.fpga4fun.com/CrossClockDomain1.html
//    * Flag_CrossDomain: If the signal that needs to cross the clock domains
//      is just a pulse (i.e. it lasts just one clock cycle), we call it a "flag".
//       - [ref] http://www.fpga4fun.com/CrossClockDomain2.html
//    * TaskAck_CrossDomain: If the clkA domain has a task that needs to be
//      completed in the clkB domain, you can use the following design.
//       - [ref] http://www.fpga4fun.com/CrossClockDomain3.html
//////////////////////////////////////////////////////////////////////////////////

/*
 * A signal to another clock domain
 *
 * Let's say a signal from clkA domain is needed in clkB domain. It needs to
 * be "synchronized" to clkB domain, so we want to build a "synchronizer"
 * design, which takes a signal from clkA domain, and creates a new signal
 * into clkB domain.
 */
module Signal_CrossDomain #(
    parameter C_SIGNAL_WIDTH = 1
)(
    input                         clkA,
    input  [C_SIGNAL_WIDTH-1 : 0] SignalIn_clkA,
    input                         clkB,
    output [C_SIGNAL_WIDTH-1 : 0] SignalOut_clkB
);
    // We use a two-stages shift-register to synchronize SignalIn_clkA
    // to the clkB clock domain
    (* ASYNC_REG = "TRUE" *) reg [C_SIGNAL_WIDTH-1 : 0] SyncA_clkB_stage1;
    reg [C_SIGNAL_WIDTH-1 : 0] SyncA_clkB_stage2;

    // notice that we use clkB
    always @(posedge clkB) SyncA_clkB_stage1 <= SignalIn_clkA;
    always @(posedge clkB) SyncA_clkB_stage2 <= SyncA_clkB_stage1;

    // new signal synchronized to (=ready to be used in) clkB domain
    assign SignalOut_clkB = SyncA_clkB_stage2;
endmodule


/*
 * A flag to another clock domain
 *
 * If the signal that needs to cross the clock domains is just a pulse (i.e.
 * it lasts just one clock cycle), we call it a "flag". The previous design
 * usually doesn't work (the flag might be missed, or be seen for too long,
 * depending on the ratio of the clocks used).
 */
module Flag_CrossDomain(
    input clkA,
    input FlagIn_clkA, 
    input clkB,
    output FlagOut_clkB
);
    // this changes level when the FlagIn_clkA is seen in clkA
    reg FlagToggle_clkA;
    always @(posedge clkA) FlagToggle_clkA <= FlagToggle_clkA ^ FlagIn_clkA;
    
    // which can then be sync-ed to clkB
    reg [2:0] SyncA_clkB;
    always @(posedge clkB) SyncA_clkB <= {SyncA_clkB[1:0], FlagToggle_clkA};
    
    // and recreate the flag in clkB
    assign FlagOut_clkB = (SyncA_clkB[2] ^ SyncA_clkB[1]);
endmodule


/*
 * Getting a task done in another clock domain
 *
 * If the clkA domain has a task that needs to be completed in the clkB domain,
 * you can use the following design.
 */
module TaskAck_CrossDomain(
    input clkA,
    input TaskStart_clkA,
    output TaskBusy_clkA, TaskDone_clkA,

    input clkB,
    output TaskStart_clkB, TaskBusy_clkB,
    input TaskDone_clkB
);
    reg FlagToggle_clkA, FlagToggle_clkB, Busyhold_clkB;
    reg [2:0] SyncA_clkB, SyncB_clkA;
    
    always @(posedge clkA) FlagToggle_clkA <= FlagToggle_clkA ^ (TaskStart_clkA & ~TaskBusy_clkA);
    
    always @(posedge clkB) SyncA_clkB <= {SyncA_clkB[1:0], FlagToggle_clkA};
    assign TaskStart_clkB = (SyncA_clkB[2] ^ SyncA_clkB[1]);
    assign TaskBusy_clkB = TaskStart_clkB | Busyhold_clkB;
    always @(posedge clkB) Busyhold_clkB <= ~TaskDone_clkB & TaskBusy_clkB;
    always @(posedge clkB) if(TaskBusy_clkB & TaskDone_clkB) FlagToggle_clkB <= FlagToggle_clkA;
    
    always @(posedge clkA) SyncB_clkA <= {SyncB_clkA[1:0], FlagToggle_clkB};
    assign TaskBusy_clkA = FlagToggle_clkA ^ SyncB_clkA[2];
    assign TaskDone_clkA = SyncB_clkA[2] ^ SyncB_clkA[1];
endmodule
