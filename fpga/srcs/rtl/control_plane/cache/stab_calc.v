module   cache_cp_calc
#(  parameter integer   CACHE_ASSOCIATIVITY     = 16,
    parameter integer   DSID_WIDTH              = 16
)
(
    input                                                   SYS_CLK,
    input                                                   DETECT_RST,

    input                                                   lookup_valid_from_cache_to_calc,
    input      [DSID_WIDTH - 1 : 0]                         lookup_DSid_from_cache_to_calc,
    input                                                   lookup_hit_from_cache_to_calc,
    input                                                   lookup_miss_from_cache_to_calc,

    input                                                   update_tag_en_from_cache_to_calc,
    input      [CACHE_ASSOCIATIVITY - 1 : 0]                update_tag_we_from_cache_to_calc,
    input      [CACHE_ASSOCIATIVITY * DSID_WIDTH - 1 : 0]   update_tag_new_DSid_vec_from_cache_to_calc,
    input      [CACHE_ASSOCIATIVITY * DSID_WIDTH - 1 : 0]   update_tag_old_DSid_vec_from_cache_to_calc,

    output     reg                                          lookup_valid_from_calc_to_stab,
    output     reg [DSID_WIDTH - 1 : 0]                     lookup_DSid_from_calc_to_stab,
    output     reg                                          lookup_hit_from_calc_to_stab,
    output     reg                                          lookup_miss_from_calc_to_stab,

    output     reg                                          update_tag_en_from_calc_to_stab,
    output     reg [CACHE_ASSOCIATIVITY - 1 : 0]            update_tag_we_from_calc_to_stab,
    output     reg [DSID_WIDTH - 1 : 0]                     update_tag_new_DSid_from_calc_to_stab,
    output     reg [DSID_WIDTH - 1 : 0]                     update_tag_old_DSid_from_calc_to_stab
);

reg                                                   lookup_valid_from_cache_to_calc_input_latch;
reg      [DSID_WIDTH - 1 : 0]                         lookup_DSid_from_cache_to_calc_input_latch;
reg                                                   lookup_valid_from_cache_to_calc_input_latch_2;
reg      [DSID_WIDTH - 1 : 0]                         lookup_DSid_from_cache_to_calc_input_latch_2;

reg                                                   lookup_hit_from_cache_to_calc_input_latch;
reg                                                   lookup_miss_from_cache_to_calc_input_latch;

reg                                                   update_tag_en_from_cache_to_calc_input_latch;
reg      [CACHE_ASSOCIATIVITY - 1 : 0]                update_tag_we_from_cache_to_calc_input_latch;
reg      [CACHE_ASSOCIATIVITY * DSID_WIDTH - 1 : 0]   update_tag_new_DSid_vec_from_cache_to_calc_input_latch;
reg      [CACHE_ASSOCIATIVITY * DSID_WIDTH - 1 : 0]   update_tag_old_DSid_vec_from_cache_to_calc_input_latch;

reg                                                   update_tag_en_from_cache_to_calc_input_latch_2;
reg      [CACHE_ASSOCIATIVITY - 1 : 0]                update_tag_we_from_cache_to_calc_input_latch_2;
reg      [CACHE_ASSOCIATIVITY * DSID_WIDTH - 1 : 0]   update_tag_new_DSid_vec_from_cache_to_calc_input_latch_2;


always@(posedge SYS_CLK or posedge DETECT_RST)
begin
    if(DETECT_RST)
    begin
        lookup_valid_from_cache_to_calc_input_latch     <= 1'b0;
        lookup_DSid_from_cache_to_calc_input_latch             <= {(DSID_WIDTH){1'b0}};
        lookup_valid_from_cache_to_calc_input_latch_2          <= 1'b0;
        lookup_DSid_from_cache_to_calc_input_latch_2           <= {(DSID_WIDTH){1'b0}};

        lookup_hit_from_cache_to_calc_input_latch              <= 1'b0;
        lookup_miss_from_cache_to_calc_input_latch             <= 1'b0;

        update_tag_en_from_cache_to_calc_input_latch           <= 1'b0;
        update_tag_we_from_cache_to_calc_input_latch           <= {(CACHE_ASSOCIATIVITY){1'b0}};
        update_tag_new_DSid_vec_from_cache_to_calc_input_latch <= {(CACHE_ASSOCIATIVITY * DSID_WIDTH){1'b0}};
        update_tag_old_DSid_vec_from_cache_to_calc_input_latch <= {(CACHE_ASSOCIATIVITY * DSID_WIDTH){1'b0}};

        update_tag_en_from_cache_to_calc_input_latch_2         <= 1'b0;
        update_tag_we_from_cache_to_calc_input_latch_2         <= {(CACHE_ASSOCIATIVITY){1'b0}};
        update_tag_new_DSid_vec_from_cache_to_calc_input_latch_2   <= {(CACHE_ASSOCIATIVITY * DSID_WIDTH){1'b0}};

    end
    else
    begin
        lookup_valid_from_cache_to_calc_input_latch                <= lookup_valid_from_cache_to_calc;
        lookup_DSid_from_cache_to_calc_input_latch                 <= lookup_DSid_from_cache_to_calc;

        lookup_valid_from_cache_to_calc_input_latch_2              <= lookup_valid_from_cache_to_calc_input_latch;
        lookup_DSid_from_cache_to_calc_input_latch_2               <= lookup_DSid_from_cache_to_calc_input_latch;

        lookup_hit_from_cache_to_calc_input_latch                  <= lookup_hit_from_cache_to_calc;
        lookup_miss_from_cache_to_calc_input_latch                 <= lookup_miss_from_cache_to_calc;

        update_tag_en_from_cache_to_calc_input_latch               <= update_tag_en_from_cache_to_calc;
        update_tag_we_from_cache_to_calc_input_latch               <= update_tag_we_from_cache_to_calc;
        update_tag_new_DSid_vec_from_cache_to_calc_input_latch     <= update_tag_new_DSid_vec_from_cache_to_calc;
        update_tag_old_DSid_vec_from_cache_to_calc_input_latch     <= update_tag_old_DSid_vec_from_cache_to_calc;

        update_tag_en_from_cache_to_calc_input_latch_2             <= update_tag_en_from_cache_to_calc_input_latch;
        update_tag_we_from_cache_to_calc_input_latch_2             <= update_tag_we_from_cache_to_calc_input_latch;
        update_tag_new_DSid_vec_from_cache_to_calc_input_latch_2   <= update_tag_new_DSid_vec_from_cache_to_calc_input_latch;

    end
end

wire [DSID_WIDTH - 1 : 0] old_dsid_unselected [CACHE_ASSOCIATIVITY - 1 :0];
wire [DSID_WIDTH - 1 : 0] new_dsid_unselected [CACHE_ASSOCIATIVITY - 1 :0];
reg [31:0] sel;
integer index;

generate
    genvar i;
        assign old_dsid_unselected[0] = update_tag_old_DSid_vec_from_cache_to_calc_input_latch[DSID_WIDTH - 1 : 0];
        assign new_dsid_unselected[0] = update_tag_new_DSid_vec_from_cache_to_calc_input_latch_2[DSID_WIDTH - 1 : 0];
    for(i=1;i<CACHE_ASSOCIATIVITY;i=i+1)
    begin : dsid_vec
        assign old_dsid_unselected[i] = update_tag_old_DSid_vec_from_cache_to_calc_input_latch[(i+1) * DSID_WIDTH - 1 : i * DSID_WIDTH];
        assign new_dsid_unselected[i] = update_tag_new_DSid_vec_from_cache_to_calc_input_latch_2[(i+1) * DSID_WIDTH - 1 : i * DSID_WIDTH];
    end
endgenerate

always@*
begin : Find_Matched_DSid
sel <= 0;
for( index = 0; index < CACHE_ASSOCIATIVITY; index = index + 1)
   if(update_tag_we_from_cache_to_calc_input_latch_2[index] & update_tag_en_from_cache_to_calc_input_latch_2)
   begin
      sel <= index;
      disable Find_Matched_DSid; //TO exit the loop
   end
end
wire [DSID_WIDTH - 1 : 0] old_dsid_selected = old_dsid_unselected[sel];
wire [DSID_WIDTH - 1 : 0] new_dsid_selected = new_dsid_unselected[sel];

//latching all of the signals for timing
always@(posedge SYS_CLK or posedge DETECT_RST)
begin
    if(DETECT_RST)
    begin
        lookup_valid_from_calc_to_stab           <= 1'b0;
        lookup_DSid_from_calc_to_stab            <= {(DSID_WIDTH){1'b0}};
        lookup_hit_from_calc_to_stab             <= 1'b0;
        lookup_miss_from_calc_to_stab            <= 1'b0;

        update_tag_en_from_calc_to_stab          <= 1'b0;
        update_tag_we_from_calc_to_stab          <= {(CACHE_ASSOCIATIVITY){1'b0}};
        update_tag_old_DSid_from_calc_to_stab    <= {(DSID_WIDTH){1'b0}};
        update_tag_new_DSid_from_calc_to_stab    <= {(DSID_WIDTH){1'b0}};
    end
    else
    begin
        lookup_valid_from_calc_to_stab           <= lookup_valid_from_cache_to_calc_input_latch_2;
        lookup_DSid_from_calc_to_stab            <= lookup_DSid_from_cache_to_calc_input_latch_2;
        lookup_hit_from_calc_to_stab             <= lookup_hit_from_cache_to_calc_input_latch;
        lookup_miss_from_calc_to_stab            <= lookup_miss_from_cache_to_calc_input_latch;

        update_tag_en_from_calc_to_stab          <= update_tag_en_from_cache_to_calc_input_latch_2;
        update_tag_we_from_calc_to_stab          <= update_tag_we_from_cache_to_calc_input_latch_2;
        update_tag_new_DSid_from_calc_to_stab    <= new_dsid_selected;
        update_tag_old_DSid_from_calc_to_stab    <= old_dsid_selected;
    end
end
endmodule
