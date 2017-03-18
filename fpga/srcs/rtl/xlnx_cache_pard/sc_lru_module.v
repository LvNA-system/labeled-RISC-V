`define decoder_case(count) count : lru_check_used_set_decoded_s1 <= {{(2 ** C_LINE_SIZE_LOG2-(count)-1){1'b0}}, {{1'b1}}, {(count){1'b0}}}
`define encoder_case(count) { {(2 ** C_LINE_SIZE_LOG2 - (count) - 1){1'b1}}, {{1'b0}}, {(count){1'bx}} } : lru_way_encoded <= (count)

module sc_lru_module
(
    input 									Clk,
    input 									Reset,
    
//Pipe control.
input 									lookup_fetch_piperun,
input 									lookup_mem_piperun,
    
//Peek LRU.
input 	[C_ADDR_SIZE_LOG2 - 1 : 0] 		lru_fetch_line_addr,
output 	[C_LINE_SIZE_LOG2 - 1 : 0]		lru_check_next_set,
output 	[2**C_LINE_SIZE_LOG2 - 1 : 0] 	lru_check_next_hot_set,
    
//Control LRU.
input   [2**C_LINE_SIZE_LOG2 - 1 : 0]   way_mask_from_ptab,
input 									lru_check_use_lru,
input 	[C_ADDR_SIZE_LOG2 - 1 : 0]		lru_check_line_addr,
input 	[C_LINE_SIZE_LOG2 - 1 : 0] 		lru_check_used_set,
    
//After refresh.
    output 	[C_LINE_SIZE_LOG2 - 1 : 0]		lru_update_prev_lru_set,
    output 	[C_LINE_SIZE_LOG2 - 1 : 0]		lru_update_new_lru_set
);

parameter [1000:0]   C_TARGET           = 1;
parameter integer    C_ADDR_SIZE_LOG2   = 31;
parameter integer    C_LINE_SIZE_LOG2   = 31;

wire    [2**C_LINE_SIZE_LOG2 - 1 : 0]   history_read_from_array;
reg     [2**C_LINE_SIZE_LOG2 - 1 : 0]   history_read_from_array_stage1;
wire    [2**C_LINE_SIZE_LOG2 - 1 : 0]   history_write_to_array_s1;

reg     [2**C_LINE_SIZE_LOG2 - 1:0]     lru_check_used_set_decoded_s1;

reg     [C_LINE_SIZE_LOG2 - 1 : 0]      lru_way_encoded;
reg 	 [C_LINE_SIZE_LOG2 - 1 : 0]     lru_way_encoded_stage1;

sc_ram_module
    #(
      .C_TARGET(C_TARGET),
      //PortA   
      .C_WE_A_WIDTH(1),
      .C_DATA_A_WIDTH(2**C_LINE_SIZE_LOG2),
      .C_ADDR_A_WIDTH(C_ADDR_SIZE_LOG2),
      //PortB 
      .C_WE_B_WIDTH(1),
      .C_DATA_B_WIDTH(2**C_LINE_SIZE_LOG2),
      .C_ADDR_B_WIDTH(C_ADDR_SIZE_LOG2)
     ) 
LRU_History
    (
	 //PortA
      .CLKA(Clk),
      .ENA(lookup_fetch_piperun),
      .WEA(1'b0),
      .ADDRA(lru_fetch_line_addr),
      .DATA_INA({(2**C_LINE_SIZE_LOG2){1'b0}}),
      .DATA_OUTA(history_read_from_array),
     //PORT B
      .CLKB(Clk),
      .ENB(lru_check_use_lru),
      .WEB(lru_check_use_lru),
      .ADDRB(lru_check_line_addr),
      .DATA_INB(history_write_to_array_s1),
      .DATA_OUTB()
    );

 
//PipeStage 1
always@(posedge Clk, posedge Reset)
begin
	if(Reset)
	begin
		history_read_from_array_stage1 <= {(2**C_LINE_SIZE_LOG2){1'b0}};
	end
	else if(lookup_mem_piperun)
	begin
		history_read_from_array_stage1 <= history_read_from_array;
	end
end

//LRU History
always@(*)
begin
	case(lru_check_used_set)
			
       `decoder_case(0);
       `decoder_case(1);
       `decoder_case(2);
       `decoder_case(3);
       `decoder_case(4);
       `decoder_case(5);
       `decoder_case(6);
       `decoder_case(7);
       `decoder_case(8);
       `decoder_case(9);
       `decoder_case(10);
       `decoder_case(11);
       `decoder_case(12);
       `decoder_case(13);
       `decoder_case(14);
       `decoder_case(15);
       `decoder_case(16);
       `decoder_case(17);
       `decoder_case(18);
       `decoder_case(19);
       `decoder_case(20);
       `decoder_case(21);
       `decoder_case(22);
       `decoder_case(23);
       `decoder_case(24);
       `decoder_case(25);
       `decoder_case(26);
       `decoder_case(27);
       `decoder_case(28);
       `decoder_case(29);
       `decoder_case(30);
       `decoder_case(31);
		
	endcase
end



//LRU encoding
always@(*)
begin
    casex((history_read_from_array | way_mask_from_ptab) == {(2**C_LINE_SIZE_LOG2){1'b1}} ? way_mask_from_ptab : history_read_from_array | way_mask_from_ptab)
    //casex(history_read_from_array)
    
    default:
    begin
        lru_way_encoded <= 0;    
    end 
       
        `encoder_case(1);
        `encoder_case(2);
        `encoder_case(3);
        `encoder_case(4);
        `encoder_case(5);
        `encoder_case(6);
        `encoder_case(7);
        `encoder_case(8);
        `encoder_case(9);
        `encoder_case(10);
        `encoder_case(11);
        `encoder_case(12);
        `encoder_case(13);
        `encoder_case(14);
        `encoder_case(15);
        `encoder_case(16);
        `encoder_case(17);
        `encoder_case(18);
        `encoder_case(19);
        `encoder_case(20);
        `encoder_case(21);
        `encoder_case(22);
        `encoder_case(23);
        `encoder_case(24);
        `encoder_case(25);
        `encoder_case(26);
        `encoder_case(27);
        `encoder_case(28);
        `encoder_case(29);
        `encoder_case(30);
        `encoder_case(31);
        
   endcase
end


always@(posedge Clk, posedge Reset)
begin
    if(Reset)
        lru_way_encoded_stage1 <= 32'b0;
    else if(lookup_mem_piperun)
        lru_way_encoded_stage1 <= lru_way_encoded;
        	
end

assign history_write_to_array_s1        = (history_read_from_array_stage1 | lru_check_used_set_decoded_s1) == {(2**C_LINE_SIZE_LOG2){1'b1}} ?
                                            {(2**C_LINE_SIZE_LOG2){1'b0}} : history_read_from_array_stage1 | lru_check_used_set_decoded_s1;

/*assign history_write_to_array_s1        = (history_read_from_array_stage1 | lru_check_used_set_decoded_s1) == {(2**C_LINE_SIZE_LOG2){1'b1}} ?
                                            {(2**C_LINE_SIZE_LOG2){1'b0}} : history_read_from_array_stage1 | lru_check_used_set_decoded_s1;*/
assign lru_check_next_set       = lru_way_encoded_stage1;

//Presumably unuseful signals
assign lru_check_next_hot_set	= lru_way_encoded_stage1;
assign lru_update_prev_lru_set  = lru_way_encoded_stage1;
assign lru_update_new_lru_set   = lru_way_encoded_stage1;

endmodule
