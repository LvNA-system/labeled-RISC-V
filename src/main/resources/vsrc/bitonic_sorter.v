module bitonic_sorter
#(
    parameter SINGLE_WAY_WIDTH_IN_BITS = 4,
    parameter NUM_WAY                  = 16 // must be a power of 2
)
(
    input                                                clk_in,
    input                                                reset_in,
    input  [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0]  pre_sort_flatted_in,
    output [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0]  post_sort_flatted_out
);

wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_0_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_1_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_2_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_3_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_4_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_5_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_6_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_7_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_8_flatted;
wire [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] cross_9_flatted;

reg [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] stage_1_flatted;
reg [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] stage_2_flatted;
reg [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0] stage_3_flatted;

always@(posedge clk_in)
begin
    if(reset_in)
    begin
        stage_1_flatted <= 0;
        stage_2_flatted <= 0;
        stage_3_flatted <= 0;
    end

    else
    begin
        stage_1_flatted <= cross_3_flatted; /**/
        stage_2_flatted <= cross_6_flatted; /**/
        stage_3_flatted <= cross_9_flatted; /**/
    end
end

assign post_sort_flatted_out = stage_3_flatted;

// cross 0  /**/
generate
genvar gen;
`define stride 2  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_0  /**/
    
    bitonic_sorter_orange  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (pre_sort_flatted_in[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out( cross_0_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 1  /**/
generate
`define stride 4  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_1  /**/
    
    bitonic_sorter_orange  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (cross_0_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_1_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 2  /**/
generate
`define stride 2  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_2  /**/
    
    bitonic_sorter_pink  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (cross_1_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_2_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 3  /**/
generate
`define stride 8  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_3  /**/
    
    bitonic_sorter_orange  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (cross_2_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_3_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 4  /**/
generate
`define stride 4  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_4  /**/
    
    bitonic_sorter_pink  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (stage_1_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_4_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 5  /**/
generate
`define stride 2  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_5  /**/
    
    bitonic_sorter_pink  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (cross_4_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_5_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 6  /**/
generate
`define stride 16  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_6  /**/
    
    bitonic_sorter_orange  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (cross_5_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_6_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 7  /**/
generate
`define stride 8  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_7  /**/
    
    bitonic_sorter_pink  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (stage_2_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_7_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 8  /**/
generate
`define stride 4  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_8  /**/
    
    bitonic_sorter_pink  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (cross_7_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_8_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

// cross 9  /**/
generate
`define stride 2  /**/
for(gen = 0; gen < NUM_WAY; gen = gen + `stride)
begin : cross_9  /**/
    
    bitonic_sorter_pink  /**/
    #(
        .SINGLE_WAY_WIDTH_IN_BITS(SINGLE_WAY_WIDTH_IN_BITS),
        .NUM_WAY(`stride)
    )
    bitonic_sorter_cell
    (
         /**/
        .pre_sort_flatted_in  (cross_8_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS]),
        .post_sort_flatted_out(cross_9_flatted[gen * SINGLE_WAY_WIDTH_IN_BITS +: `stride * SINGLE_WAY_WIDTH_IN_BITS])
    );
end
`undef stride
endgenerate

endmodule