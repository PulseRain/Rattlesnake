/*
###############################################################################
# Copyright (c) 2019, PulseRain Technology LLC 
#
# This program is distributed under a dual license: an open source license, 
# and a commercial license. 
# 
# The open source license under which this program is distributed is the 
# GNU Public License version 3 (GPLv3).
#
# And for those who want to use this program in ways that are incompatible
# with the GPLv3, PulseRain Technology LLC offers commercial license instead.
# Please contact PulseRain Technology LLC (www.pulserain.com) for more detail.
#
###############################################################################
*/


//=============================================================================
// Remarks:
//    PulseRain RV2T is a MCU core of Von Neumann architecture. 
//=============================================================================

`include "common.vh"

`default_nettype none

module Rattlesnake_mm_reg (
    
    //=======================================================================
    // clock / reset
    //=======================================================================

        input   wire                                                    clk,
        input   wire                                                    reset_n,
        input   wire                                                    sync_reset,

    //=======================================================================
    // data read / write
    //=======================================================================
        input   wire                                                    data_read_enable,
        input   wire  [`XLEN_BYTES - 1 : 0]                             data_write_enable,
        
        input   wire  [`MM_REG_ADDR_BITS - 1 : 0]                       data_rw_addr,
        input   wire  [`XLEN - 1 : 0]                                   data_write_word,
        
    //=======================================================================
    // Wishbone Host Interface 
    //=======================================================================
        output wire                                                     WB_RD_CYC_O,
        output wire                                                     WB_RD_STB_O,
        output wire  unsigned [`MM_REG_ADDR_BITS - 1 : 0]               WB_RD_ADR_O,
        input  wire  unsigned [`XLEN - 1 : 0]                           WB_RD_DAT_I,
        input  wire                                                     WB_RD_ACK_I,
        
        output wire                                                     WB_WR_CYC_O,
        output wire                                                     WB_WR_STB_O,
        output wire                                                     WB_WR_WE_O,
        output wire unsigned [`XLEN_BYTES - 1 : 0]                      WB_WR_SEL_O,
        output wire unsigned [`MM_REG_ADDR_BITS - 1 : 0]                WB_WR_ADR_O,
        output wire unsigned [`XLEN - 1 : 0]                            WB_WR_DAT_O,
        input  wire                                                     WB_WR_ACK_I,
    
    //=======================================================================
    // output
    //=======================================================================
        output  reg                                                     enable_out,
        output  wire  [`XLEN - 1 : 0]                                   word_out,
        
        output  wire                                                    timer_triggered
);

   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Signals
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire                                             load_mtimecmp_low;
        wire                                             load_mtimecmp_high;
        
        wire [`XLEN - 1 : 0]                             machine_timer_data_out;
        
        reg [`MM_REG_ADDR_BITS - 1 : 0]                  data_rw_addr_save;
        
        
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Input
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        assign load_mtimecmp_low  = ((data_write_enable != 0) && (data_rw_addr == `MTIMECMP_LOW_ADDR)) ? 1'b1 : 1'b0;
        assign load_mtimecmp_high = ((data_write_enable != 0) && (data_rw_addr == `MTIMECMP_HIGH_ADDR)) ? 1'b1 : 1'b0;
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Output
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                enable_out <= 0;
                data_rw_addr_save <= 0;
            end else begin
                
                if (data_read_enable && (data_rw_addr <= `MTIMECMP_HIGH_ADDR)) begin
                    enable_out <= 1'b1;
                end else begin
                    enable_out <= WB_RD_ACK_I;
                end
            
                if (data_read_enable) begin
                    data_rw_addr_save <= data_rw_addr;
                end
            end
        end
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // machine timer
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        Rattlesnake_machine_timer Rattlesnake_machine_timer_i (
            .clk (clk),
            .reset_n (reset_n),
            .sync_reset (sync_reset),
            
            .load_mtimecmp_low (load_mtimecmp_low),
            .load_mtimecmp_high (load_mtimecmp_high),
            .mtimecmp_write_data (data_write_word),
            
            .timer_triggered (timer_triggered),
            
            .reg_read_addr (data_rw_addr [1 : 0]),
            .reg_read_data (machine_timer_data_out));
   
   
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Wishbone
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        assign WB_RD_CYC_O = 1'b1;
        assign WB_RD_STB_O = (data_rw_addr <= `MTIMECMP_HIGH_ADDR) ? 1'b0 : data_read_enable;
        assign WB_RD_ADR_O = data_rw_addr;
        
        assign WB_WR_CYC_O = 1'b1;
        assign WB_WR_STB_O = 1'b1;
        assign WB_WR_WE_O  = |data_write_enable;
        assign WB_WR_ADR_O = data_rw_addr;
        assign WB_WR_DAT_O = data_write_word;
        assign WB_WR_SEL_O = data_write_enable;
            
            
        assign word_out = (data_rw_addr_save <= `MTIMECMP_HIGH_ADDR) ? machine_timer_data_out : WB_RD_DAT_I;
     
        
        
endmodule

`default_nettype wire
