`include "../include/axi.vh"

module cdma_addr(
   `axi_in_interface(S_AXI, s_axi, 4),
   `axi_out_interface(M_AXI, m_axi, 4)
);

    assign  m_axi_aw_bits_addr = {1'b1, s_axi_aw_bits_addr[30:0]};
    assign  m_axi_ar_bits_addr = {1'b1, s_axi_ar_bits_addr[30:0]};
    assign  m_axi_ar_bits_burst = s_axi_ar_bits_burst;
    assign  m_axi_ar_bits_cache = s_axi_ar_bits_cache;
    assign  m_axi_ar_bits_id    = s_axi_ar_bits_id   ;
    assign  m_axi_ar_bits_len   = s_axi_ar_bits_len  ;
    assign  m_axi_ar_bits_lock  = s_axi_ar_bits_lock ;
    assign  m_axi_ar_bits_prot  = s_axi_ar_bits_prot ;
    assign  s_axi_ar_ready = m_axi_ar_ready;
    assign  m_axi_ar_bits_size  = s_axi_ar_bits_size ;
    assign  m_axi_ar_valid = s_axi_ar_valid;
    assign  m_axi_aw_bits_burst = s_axi_aw_bits_burst;
    assign  m_axi_aw_bits_cache = s_axi_aw_bits_cache;
    assign  m_axi_aw_bits_id    = s_axi_aw_bits_id   ;
    assign  m_axi_aw_bits_len   = s_axi_aw_bits_len  ;
    assign  m_axi_aw_bits_lock  = s_axi_aw_bits_lock ;
    assign  m_axi_aw_bits_prot  = s_axi_aw_bits_prot ;
    assign  s_axi_aw_ready = m_axi_aw_ready;
    assign  m_axi_aw_bits_size  = s_axi_aw_bits_size ;
    assign  m_axi_aw_valid = s_axi_aw_valid;
    assign  s_axi_b_bits_id     = m_axi_b_bits_id    ;
    assign  m_axi_b_ready  = s_axi_b_ready ;
    assign  s_axi_b_bits_resp   = m_axi_b_bits_resp  ;
    assign  s_axi_b_valid  = m_axi_b_valid ;
    assign  s_axi_r_bits_data   = m_axi_r_bits_data  ;
    assign  s_axi_r_bits_id     = m_axi_r_bits_id    ;
    assign  s_axi_r_bits_last   = m_axi_r_bits_last  ;
    assign  m_axi_r_ready  = s_axi_r_ready ;
    assign  s_axi_r_bits_resp   = m_axi_r_bits_resp  ;
    assign  s_axi_r_valid  = m_axi_r_valid ;
    assign  m_axi_w_bits_data   = s_axi_w_bits_data  ;
    assign  m_axi_w_bits_last   = s_axi_w_bits_last  ;
    assign  s_axi_w_ready  = m_axi_w_ready ;
    assign  m_axi_w_bits_strb   = s_axi_w_bits_strb  ;
    assign  m_axi_w_valid  = s_axi_w_valid ;
    assign  m_axi_ar_bits_qos   = s_axi_ar_bits_qos  ;
    assign  m_axi_ar_bits_user  = s_axi_ar_bits_user ;
    assign  m_axi_aw_bits_qos   = s_axi_aw_bits_qos  ;
    assign  m_axi_aw_bits_user  = s_axi_aw_bits_user ;

endmodule
