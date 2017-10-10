`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2015 02:30:02 PM
// Design Name: 
// Module Name: i2c_intf
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   code from http://dlbeer.co.nz/articles/i2c.html 
//////////////////////////////////////////////////////////////////////////////////

module i2c_io_sync (
    input wire sysclk,
    input wire reset,
    input wire ext_scl,
    input wire ext_sda,
    output wire int_scl,
    output wire int_sda
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] sda_in_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] scl_in_sync;

    assign int_scl = scl_in_sync[1];
    assign int_sda = sda_in_sync[1];
    
    always @(posedge reset or posedge sysclk)
    begin
        if (reset) begin
            sda_in_sync <= 2'b11;
            scl_in_sync <= 2'b11;
        end else begin
            sda_in_sync[1:0] <= {sda_in_sync[0], ext_sda};
            scl_in_sync[1:0] <= {scl_in_sync[0], ext_scl};
            /*sda_in_sync[0] <= ext_sda;
            sda_in_sync[1] <= sda_in_sync[0];
            scl_in_sync[0] <= ext_scl;
            scl_in_sync[1] <= scl_in_sync[0];*/
        end
    end
endmodule

module i2c_slave_code_detect (
    input  wire sysclk,
    input  wire reset,
    input  wire scl,
    input  wire sda,
    output wire start_detect,
    output wire stop_detect,
    output wire bit_strobe,
    output wire scl_fall
);
    reg prev_sda, prev_scl;
    reg start_detect_r, stop_detect_r, bit_strobe_r, scl_fall_r;
    
    assign start_detect = start_detect_r2;
    assign stop_detect  = stop_detect_r2;
    assign bit_strobe   = bit_strobe_r;
    assign scl_fall     = scl_fall_r;

    /* Store the previous value of SDA and SCL, for edge detection */
    always @(posedge sysclk or posedge reset)
    begin
        if (reset) begin
            prev_sda <= 1'b1;
            prev_scl <= 1'b1;
        end else begin
            prev_sda <= sda;
            prev_scl <= scl;
        end
    end
    
    always @(posedge reset or posedge sysclk)
    begin
        if (reset) begin
            start_detect_r <= 1'b0;
            stop_detect_r  <= 1'b0;
            bit_strobe_r   <= 1'b0;
            scl_fall_r     <= 1'b0;
        end else begin
            // Start conditions: SCL is stable, SDA falls
            start_detect_r <= (scl && prev_scl && prev_sda && !sda);
            // Stop concitions: SCL is stable, SDA rises
            stop_detect_r  <= (scl && prev_scl && sda && !prev_sda);
            
            // A data bit is valid: SCL rises
            if (scl && !prev_scl) begin
                bit_strobe_r <= 1;
            end else begin
                bit_strobe_r <= 0;
            end
            
            // Prepare output bit: SCL fall
            if (!scl && prev_scl)
                scl_fall_r <= 1'b1;
            else
                scl_fall_r <= 1'b0;
        end
    end

    reg start_detect_r2 ;
    always @(posedge reset or posedge sysclk) begin 
       if (reset) begin
        start_detect_r2 <= 1'b0 ;
       end
       else if (start_detect_r == 1'b1) begin
        start_detect_r2 <= 1'b1 ;
       end
       else if (scl_fall_r) begin
        start_detect_r2 <= 1'b0 ;
       end
    end
    reg stop_detect_r2 ;
  always @(posedge reset or posedge sysclk) begin
     if (reset) begin
       stop_detect_r2 <= 1'b0;
     end
     else if (stop_detect_r == 1'b1) begin
       stop_detect_r2 <= 1'b1 ; 
     end
     else if (bit_strobe_r) begin
       stop_detect_r2 <= 1'b0;
     end 
    end
endmodule 

module I2CInterface (
    RST, SYS_CLK,
    /* I2C Interface */
    ADDR, SCL_ext_i, SCL_o, SCL_t, SDA_ext_i, SDA_o, SDA_t,
    /* Register Interface */
    STOP_DETECT_o, INDEX_POINTER_o, WRITE_ENABLE_o, RECEIVE_BUFFER, SEND_BUFFER
);
    input  wire RST;
    input  wire SYS_CLK;
    input  wire[6:0] ADDR;
    input  wire SCL_ext_i;
    output wire SCL_o;
    output wire SCL_t;
    input  wire SDA_ext_i;
    output wire SDA_o;
    output wire SDA_t;

    output wire       STOP_DETECT_o;
    output wire [7:0] INDEX_POINTER_o;
    output wire       WRITE_ENABLE_o;
    output wire [7:0] RECEIVE_BUFFER;
    input  wire [7:0] SEND_BUFFER;

    wire SCL_i, SDA_i;
    i2c_io_sync i2c_io_sync_i (
        .sysclk(SYS_CLK),
        .reset(RST),
        .ext_scl(SCL_ext_i),
        .ext_sda(SDA_ext_i),
        .int_scl(SCL_i),
        .int_sda(SDA_i)
    );
    
    /* I2C bit detector: START/STOP/BIT_STROBE */
    wire start_detect, stop_detect, bit_strobe, scl_fall;
    i2c_slave_code_detect code_det (
        .sysclk(SYS_CLK),
        .reset(RST),
        .scl(SCL_i),
        .sda(SDA_i),
        .start_detect(start_detect),
        .stop_detect(stop_detect),
        .bit_strobe(bit_strobe),
        .scl_fall(scl_fall));

    /* Latching input data */
    reg [3:0]       bit_counter;

    wire            lsb_bit = (bit_counter == 4'h7) && !start_detect;
    wire            ack_bit = (bit_counter == 4'h8) && !start_detect;
    
    always @ (posedge SYS_CLK or posedge RST)
    begin
       if (RST) begin
           bit_counter <= 4'd0;
       end else if (scl_fall) begin
           if (ack_bit || start_detect)
               bit_counter <= 4'h0;
           else
               bit_counter <= bit_counter + 4'h1;
       end
    end

    reg [7:0]       input_shift;
    reg             master_ack;

    //parameter [6:0] device_address = 7'h50;
    wire            address_detect = (input_shift[7:1] == ADDR[6:0]);
    wire            read_write_bit = input_shift[0];

    always @ (posedge RST or posedge SYS_CLK)
    begin
        if (RST)
            input_shift <= 8'b00000000;
        else if (bit_strobe) begin
            if (ack_bit)
                master_ack  <= ~SDA_i;
            else
                input_shift <= {input_shift[6:0], SDA_i};
        end
    end
            

/**
 * STATE MACHINE
 */
    parameter [2:0] STATE_IDLE      = 3'h0,
                    STATE_DEV_ADDR  = 3'h1,
                    STATE_READ      = 3'h2,
                    STATE_IDX_PTR   = 3'h3,
                    STATE_WRITE     = 3'h4;
    reg [2:0]       state;
    wire            write_strobe = (state == STATE_WRITE) && ack_bit;

    always @ (posedge RST or posedge SYS_CLK)
    begin
        if (RST)
            state <= STATE_IDLE;
        else if (scl_fall) begin
            if (start_detect)
                state <= STATE_DEV_ADDR;
            else if (ack_bit)
            begin
                case (state)
                STATE_IDLE:
                    state <= STATE_IDLE;

                STATE_DEV_ADDR:
                    if (!address_detect)
                        state <= STATE_IDLE;
                    else if (read_write_bit)
                        state <= STATE_READ;
                    else
                        state <= STATE_IDX_PTR;
                STATE_READ:
                    if (master_ack)
                        state <= STATE_READ;
                    else
                        state <= STATE_IDLE;
                STATE_IDX_PTR:
                    state <= STATE_WRITE;
                STATE_WRITE:
                    state <= STATE_WRITE;
                endcase
            end
        end
    end


/**
 * REGISTER TRANSFERS
 */
    // Handle IndexPointer
    reg [7:0] index_pointer;
    always @ (posedge RST or posedge SYS_CLK)
    begin
           if (RST)
                    index_pointer <= 8'h00;
           else  if (scl_fall) begin
              if (stop_detect)
                    index_pointer <= 8'h00;
              else if (ack_bit)
                 begin
                    if (state == STATE_IDX_PTR)
                            index_pointer <= input_shift;
                    else
                            index_pointer <= index_pointer + 8'h01;
                 end
            end
    end

    // Read
    reg [7:0]       output_shift;
    always @ (posedge SYS_CLK)
    begin
        if (scl_fall) begin
            if (lsb_bit)
                output_shift <= SEND_BUFFER;
            else
                output_shift <= {output_shift[6:0], 1'b0};
        end
    end
/**************************************************************************************************/


/**
 * OUTPUT DRIVER
 */
    reg             output_control;
    assign          SDA_o = 1'b0;
    assign          SDA_t = output_control;
    assign          SCL_o = 1'b0;
    assign          SCL_t = 1'b1;
    always @ (posedge RST or posedge SYS_CLK)
    begin
        if (RST)
            output_control <= 1'b1;
        else if (scl_fall) begin   
            if (start_detect)
                output_control <= 1'b1;
            else if (lsb_bit)
            begin
                output_control <=
                    !(((state == STATE_DEV_ADDR) && address_detect) ||
                      (state == STATE_IDX_PTR) ||
                      (state == STATE_WRITE));
            end
            else if (ack_bit)
            begin
                // Deliver the first bit of the next slave-to-master
                // transfer, if applicable.
                if (((state == STATE_READ) && master_ack) ||
                    ((state == STATE_DEV_ADDR) &&
                        address_detect && read_write_bit))
                        output_control <= output_shift[7];
                else
                        output_control <= 1'b1;
            end
            else if (state == STATE_READ)
                output_control <= output_shift[7];
            else
                output_control <= 1'b1;
        end
    end
    
    
    /* Connect to RegisterInterface */
    assign STOP_DETECT_o         = stop_detect;
    assign INDEX_POINTER_o [7:0] = index_pointer[7:0];
    assign WRITE_ENABLE_o        = write_strobe;
    assign RECEIVE_BUFFER  [7:0] = input_shift[7:0];

endmodule
