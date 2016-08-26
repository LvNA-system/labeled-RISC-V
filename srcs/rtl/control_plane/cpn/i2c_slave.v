`timescale 1ns / 1ps
/* code from http://dlbeer.co.nz/articles/i2c.html */

module i2c_slave(
    ACLK, RST, ADDR, CONTROL, VALID,
    SCL_ext_i, SCL_o, SCL_t, SDA_ext_i, SDA_o, SDA_t
);
    input  wire      ACLK;
    input  wire      RST;
    input  wire[2:0] ADDR;
    output wire[7:0] CONTROL;
    output wire      VALID;
    input  wire      SCL_ext_i;
    output wire      SCL_o;
    output wire      SCL_t;
    input  wire      SDA_ext_i;
    output wire      SDA_o;
    output wire      SDA_t;

    /* Cross-ClockDomain Sync */
    wire SCL_i, SDA_i;
    i2c_io_sync i2c_io_sync_i (
        .sysclk(ACLK),
        .reset(RST),
        .ext_scl(SCL_ext_i),
        .ext_sda(SDA_ext_i),
        .int_scl(SCL_i),
        .int_sda(SDA_i)
    );

    /* I2C bit detector: START/STOP/BIT_STROBE */
    wire start_detect, stop_detect, bit_strobe, scl_fall;
    i2c_slave_code_detect code_det (
        .sysclk(ACLK),
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
    
    always @ (posedge RST or posedge ACLK)
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
    wire            address_detect = (input_shift[7:1] == {4'b1110, ADDR[2:0]});
    wire            read_write_bit = input_shift[0];

    always @ (posedge RST or posedge ACLK)
    begin
        if (RST)
            input_shift <= 8'b00000000;
        else if (bit_strobe) begin
            if (ack_bit)
                master_ack <= ~SDA_i;
            else
                input_shift <= {input_shift[6:0], SDA_i};
        end
    end


    /**
     * Slave VALID signal
     */
     reg rValid;
     //wire start_or_address = start_detect | (lsb_bit & address_detect &(state ==STATE_DEV_ADDR ));
     assign VALID = rValid;
     always @ (posedge RST or posedge ACLK)
     begin
         if (RST)
             rValid <= 1'b1;
         else if (start_detect)
             rValid <= 1'b0;
         else if (lsb_bit & address_detect & (state==STATE_DEV_ADDR))
             rValid <= 1'b1;
         else
             rValid <= rValid;
     end

/**
 * STATE MACHINE
 */
    parameter [1:0] STATE_IDLE      = 3'h0,
                    STATE_DEV_ADDR  = 3'h1,
                    STATE_READ      = 3'h2,
                    STATE_WRITE     = 3'h3;
    reg [2:0]       state;
    wire            write_strobe = (state == STATE_WRITE) && ack_bit;

    always @ (posedge RST or posedge ACLK)
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
                        state <= STATE_WRITE;
                STATE_READ:
                    if (master_ack)
                        state <= STATE_READ;
                    else
                        state <= STATE_IDLE;
                STATE_WRITE:
                    state <= STATE_WRITE;
                endcase
            end
        end
    end

/**
 * REGISTER TRANSFERS
 */
    reg [7:0]       rControl;
    
    reg [7:0]       rControlOut; 
    assign CONTROL = rControlOut;
    always @ (posedge RST or posedge ACLK)
    begin
        if (RST)
            rControlOut[7:0] <= 8'h0;
        else if (stop_detect)
            rControlOut[7:0] <= rControl[7:0];
    end 

    /*
     * Handling register writes
     */
    always @ (posedge RST or posedge ACLK)
    begin
        if (RST)
            rControl <= 8'h00;
        else if (scl_fall & write_strobe)
            rControl <= input_shift;
    end

    /*
     * Handling resgister reads
     */
    reg [7:0]       output_shift;
    always @ (posedge RST or posedge ACLK)
    begin
        if (RST)
            output_shift <= 8'h00;
        else if (scl_fall) begin
            if (lsb_bit)
                output_shift <= rControl;
            else
                output_shift <= {output_shift[6:0], 1'b0};
        end
    end

/**
 * OUTPUT DRIVER
 */
    reg             output_control;
    assign          SDA_o = 1'b0;
    assign          SDA_t = output_control;
    assign          SCL_o = 1'b0;
    assign          SCL_t = 1'b1;
    always @ (posedge RST or posedge ACLK)
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
endmodule
