module   cache_cp_ptab
#(
    parameter CACHE_ASSOCIATIVITY = 16,
    parameter DSID_WIDTH          = 16,
    parameter ENTRY_SIZE          = 64,
    parameter NUM_ENTRIES         =  4
)
(
    input                                          SYS_CLK,
    input                                          DETECT_RST,
    input                                          is_this_table,
    input      [14:0]                              col,
    input      [14:0]                              row,
    input      [63:0]                              wdata,
    input                                          wen,
    output reg [63:0]                              rdata,

    input      [NUM_ENTRIES * DSID_WIDTH - 1 : 0]  DSid_storage,
    input                                          lru_history_en_to_ptab,
    input                                          lru_dsid_valid_to_ptab,
    input      [DSID_WIDTH - 1 : 0]                lru_dsid_to_ptab,
    output reg [CACHE_ASSOCIATIVITY - 1 : 0]       way_mask_to_cache
);

  // col 0
  reg [ENTRY_SIZE - 1 : 0] way_mask [NUM_ENTRIES - 1 : 0];

  always @(posedge SYS_CLK or posedge DETECT_RST)
  begin
    if(DETECT_RST)
    begin // caution : 0 stands for an enabled cache way, 1 is disables
      for(index = 0; index < NUM_ENTRIES; index = index + 1)
      begin
        way_mask[index]  <= {(CACHE_ASSOCIATIVITY ){1'b0}};
      end
    end
    else if(wen & is_this_table)
    begin
      case(col)
        15'b0: way_mask[row] <= ~wdata[CACHE_ASSOCIATIVITY - 1 : 0];
      endcase
    end
  end

  always @(*)
  begin
    case(col)
      15'b0:
      begin
        rdata <= {{(64-CACHE_ASSOCIATIVITY){1'b0}}, ~way_mask[row]};
      end
      default:
      begin
        rdata <= 64'b0;
      end
    endcase
  end

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

  reg [31:0] sel;
  integer index;
  always@*
  begin : Find_Matched_DSid
    sel <= NUM_ENTRIES - 1;
    for( index = 0; index < NUM_ENTRIES; index = index + 1)
    if(lru_dsid_valid_to_ptab & (lru_dsid_to_ptab == dsid_unselected[index]))
    begin
      sel <= index;
      disable Find_Matched_DSid; //TO exit the loop
    end
  end

  always@(posedge SYS_CLK or posedge DETECT_RST)
  begin
    if(DETECT_RST)
      way_mask_to_cache <= {(CACHE_ASSOCIATIVITY){1'b0}};
    else if(lru_history_en_to_ptab)
      way_mask_to_cache <= way_mask[sel];
  end

endmodule
