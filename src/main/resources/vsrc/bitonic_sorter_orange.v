module bitonic_sorter_orange
#(
    parameter SINGLE_WAY_WIDTH_IN_BITS = 32,
    parameter NUM_WAY                  = 16 // must be a power of 2
)
(
    input  [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0]  pre_sort_flatted_in,
    output [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0]  post_sort_flatted_out
);

generate
genvar gen;

for(gen = 0; gen < NUM_WAY / 2; gen = gen + 1)
begin
    assign post_sort_flatted_out[gen * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS] = 
    
   (pre_sort_flatted_in[gen * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS] <
    pre_sort_flatted_in[(NUM_WAY - gen - 1) * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS]) ?
    pre_sort_flatted_in[gen * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS]  :
    pre_sort_flatted_in[(NUM_WAY - gen - 1) * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS];

    assign post_sort_flatted_out[(NUM_WAY - gen - 1) * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS] = 
    
   (pre_sort_flatted_in[gen * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS] >
    pre_sort_flatted_in[(NUM_WAY - gen - 1) * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS]) ?
    pre_sort_flatted_in[gen * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS]  :
    pre_sort_flatted_in[(NUM_WAY - gen - 1) * SINGLE_WAY_WIDTH_IN_BITS +: SINGLE_WAY_WIDTH_IN_BITS];
end

endgenerate

endmodule