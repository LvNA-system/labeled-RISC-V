module   cache_cp_stab
#(
    parameter integer   CACHE_ASSOCIATIVITY     = 16,
    parameter integer   DSID_WIDTH              = 16,
    parameter integer   ENTRY_SIZE              = 32,
    parameter integer   NUM_ENTRIES             =  4
)
(
    input                                                   SYS_CLK,
    input                                                   DETECT_RST,
    input                                                   is_this_table,
    input      [63:0]                                      wdata,
    input                                                  wen,
    input      [14:0]                                        col,
    input      [14:0]                                        row,
    output reg [63:0]                                      rdata,

    input      [NUM_ENTRIES * DSID_WIDTH - 1 : 0]          DSid_storage,

    input [14:0] trigger_row,
    input [2:0] trigger_metric,
    output reg [31:0] trigger_rdata,

    input                                                  lookup_valid_from_calc_to_stab,
    input      [DSID_WIDTH - 1 : 0]                        lookup_DSid_from_calc_to_stab,
    input                                                  lookup_hit_from_calc_to_stab,
    input                                                  lookup_miss_from_calc_to_stab,
    input                                                  update_tag_en_from_calc_to_stab,
    input      [CACHE_ASSOCIATIVITY - 1 : 0]               update_tag_we_from_calc_to_stab,
    input      [DSID_WIDTH - 1 : 0]                        update_tag_old_DSid_from_calc_to_stab,
    input      [DSID_WIDTH - 1 : 0]                        update_tag_new_DSid_from_calc_to_stab
);

// col 0 is Hit counter
reg [ENTRY_SIZE - 1 : 0] hit_counters [NUM_ENTRIES - 1 : 0];
// col 1 is Miss conter
reg [ENTRY_SIZE - 1 : 0] total_counters [NUM_ENTRIES - 1 : 0];
// col 2 is capacity counters
reg [ENTRY_SIZE - 1 : 0] capacity_counters [NUM_ENTRIES - 1 : 0];

//Latching all of the singals for timing
reg                                                   lookup_hit_from_calc_to_stab_stage2;
reg                                                   lookup_miss_from_calc_to_stab_stage2;
reg                                                   update_tag_en_from_calc_to_stab_stage2;
reg      [CACHE_ASSOCIATIVITY - 1 : 0]                update_tag_we_from_calc_to_stab_stage2;
reg      [31 : 0]                                     sel_old_stage2;
reg      [31 : 0]                                     sel_new_stage2;
reg      [31 : 0]                                     sel_look_stage2;

//Finding Matched DSid
wire [DSID_WIDTH - 1 : 0] dsid_unselected [NUM_ENTRIES - 1 :0];
generate
    genvar i;
        assign dsid_unselected[0] = DSid_storage[DSID_WIDTH - 1 : 0];
    for(i=1;i<NUM_ENTRIES;i=i+1)
    begin : dsid_vec
        assign dsid_unselected[i] = DSid_storage[(i+1) * DSID_WIDTH - 1 : i * DSID_WIDTH];
    end
endgenerate

reg [31:0] sel_old;
integer index_old;
    always@*
    begin : Find_Matched_DSid_old
    sel_old <= NUM_ENTRIES - 1;
    for( index_old = 0; index_old < NUM_ENTRIES; index_old = index_old + 1)
       if((update_tag_old_DSid_from_calc_to_stab == dsid_unselected[index_old]))
       begin
           sel_old <= index_old;
           disable Find_Matched_DSid_old; //TO exit the loop
       end
    end

reg [31:0] sel_new;
integer index_new;
    always@*
    begin : Find_Matched_DSid_new
    sel_new <= NUM_ENTRIES - 1;
    for( index_new = 0; index_new < NUM_ENTRIES; index_new = index_new + 1)
       if((update_tag_new_DSid_from_calc_to_stab == dsid_unselected[index_new]))
       begin
           sel_new <= index_new;
           disable Find_Matched_DSid_new; //TO exit the loop
       end
    end

reg [31:0] sel_look;
integer index_look;
    always@*
    begin : Find_Matched_DSid_look
    sel_look <= NUM_ENTRIES - 1;
    for( index_look = 0; index_look < NUM_ENTRIES; index_look = index_look + 1)
       if(lookup_valid_from_calc_to_stab & (lookup_DSid_from_calc_to_stab == dsid_unselected[index_look]))
       begin
           sel_look <= index_look;
           disable Find_Matched_DSid_look; //TO exit the loop
       end
    end

always@(posedge SYS_CLK or posedge DETECT_RST)
begin
    if(DETECT_RST)
    begin
         //DSid_storage_stage2                             <= {(NUM_ENTRIES * DSID_WIDTH){1'b0}};
        lookup_hit_from_calc_to_stab_stage2             <= 1'b0;
        lookup_miss_from_calc_to_stab_stage2            <= 1'b0;
        update_tag_en_from_calc_to_stab_stage2          <= 1'b0;
        update_tag_we_from_calc_to_stab_stage2          <= {(CACHE_ASSOCIATIVITY){1'b0}};
        sel_old_stage2                                  <= 32'd0;
        sel_new_stage2                                  <= 32'd0;
        sel_look_stage2                                 <= 32'd0;
    end
    else
    begin
        //DSid_storage_stage2                             <= DSid_storage;
        lookup_hit_from_calc_to_stab_stage2             <= lookup_hit_from_calc_to_stab;
        lookup_miss_from_calc_to_stab_stage2            <= lookup_miss_from_calc_to_stab;
        update_tag_en_from_calc_to_stab_stage2          <= update_tag_en_from_calc_to_stab;
        update_tag_we_from_calc_to_stab_stage2          <= update_tag_we_from_calc_to_stab;
        sel_old_stage2                                  <= sel_old;
        sel_new_stage2                                  <= sel_new;
        sel_look_stage2                                 <= sel_look;
    end
end


//Updating hit/miss counter
integer index;
always @(posedge SYS_CLK or posedge DETECT_RST)
begin
    if(DETECT_RST)
    begin
       for(index = 0; index < NUM_ENTRIES; index = index + 1)
       begin
            hit_counters[index]  <= {(ENTRY_SIZE){1'b0}};
       end
    end

    else if(wen & is_this_table & (col==15'd0))
    begin
       hit_counters[row]        <= wdata;
    end

    else if(lookup_hit_from_calc_to_stab_stage2)
    begin
       hit_counters[sel_look_stage2]     <= hit_counters[sel_look_stage2] + 1'b1;
    end
end

always @(posedge SYS_CLK or posedge DETECT_RST)
begin
    if(DETECT_RST)
    begin
       for(index = 0; index < NUM_ENTRIES; index = index + 1)
       begin
            total_counters[index]        <= {(ENTRY_SIZE){1'b0}};
       end
    end

    else if(wen & is_this_table & (col==15'd1))
    begin
       total_counters[row]        <= wdata;
    end

    else if(lookup_miss_from_calc_to_stab_stage2 | lookup_hit_from_calc_to_stab_stage2)
    begin
       total_counters[sel_look_stage2]    <= total_counters[sel_look_stage2] + 1'b1;
    end
end

//Updating capacity counter
wire capcacity_update_en = (sel_old_stage2 != sel_new_stage2)  &
                            update_tag_en_from_calc_to_stab_stage2 & (|update_tag_we_from_calc_to_stab_stage2);

always @(posedge SYS_CLK or posedge DETECT_RST)
begin
    if(DETECT_RST)
    begin
       for(index = 0; index < NUM_ENTRIES; index = index + 1)
       begin
            capacity_counters[index]    <= {(ENTRY_SIZE){1'b0}};
       end
    end

    else if(wen & is_this_table & (col==15'd2))
    begin
       capacity_counters[row]           <= wdata;
    end

    else if(capcacity_update_en)
    begin
       capacity_counters[sel_old_stage2] <= capacity_counters[sel_old_stage2] - 1'b1;
       capacity_counters[sel_new_stage2] <= capacity_counters[sel_new_stage2] + 1'b1;
    end
end

//calculate the hit rate

reg [ENTRY_SIZE - 1 : 0] win_hit_counters [NUM_ENTRIES - 1 : 0];
reg [ENTRY_SIZE - 1 : 0] win_total_counters [NUM_ENTRIES - 1 : 0];
reg [ENTRY_SIZE - 1 : 0] win_hit_ratex100 [NUM_ENTRIES - 1 : 0];

always @(posedge SYS_CLK or posedge DETECT_RST) begin
    if(DETECT_RST)  begin
        for(index = 0; index < NUM_ENTRIES; index = index + 1) begin
            win_total_counters[index]  <= {(ENTRY_SIZE){1'b0}};
            win_hit_counters[index]  <= {(ENTRY_SIZE){1'b0}};
            win_hit_ratex100[index] <= {(ENTRY_SIZE){1'b0}};
        end
    end
    else if(lookup_miss_from_calc_to_stab_stage2 | lookup_hit_from_calc_to_stab_stage2) begin
        if(win_total_counters[sel_look_stage2] == (1600 - 1)) begin
            win_total_counters[sel_look_stage2]  <= {(ENTRY_SIZE){1'b0}};
            win_hit_counters[sel_look_stage2]  <= {(ENTRY_SIZE){1'b0}};
            win_hit_ratex100[sel_look_stage2] <= {4'b0, win_hit_counters[sel_look_stage2][31:4]};    // hit_counters / 16
        end
        else begin
            win_total_counters[sel_look_stage2] <= win_total_counters[sel_look_stage2] + 1'b1;
            if(lookup_hit_from_calc_to_stab_stage2) begin
                win_hit_counters[sel_look_stage2] <= win_hit_counters[sel_look_stage2] + 1'b1;
            end
        end
    end
end

//read out
always @(*) begin
    case(col)
    15'd0: rdata = {32'b0, hit_counters[row]};
    15'd1: rdata = {32'b0, total_counters[row]};
    15'd2: rdata = {32'b0, capacity_counters[row]};
    15'd3: rdata = {32'b0, win_hit_ratex100[row]};
    default: rdata = 64'b0;
    endcase
end

always @(*) begin
    case(trigger_metric)
    15'd0: trigger_rdata = hit_counters[trigger_row];
    15'd1: trigger_rdata = total_counters[trigger_row];
    15'd2: trigger_rdata = capacity_counters[trigger_row];
    15'd3: trigger_rdata = win_hit_ratex100[trigger_row];
    default: trigger_rdata = 32'b0;
    endcase
end
endmodule
