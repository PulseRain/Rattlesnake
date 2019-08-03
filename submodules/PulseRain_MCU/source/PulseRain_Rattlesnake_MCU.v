/*
###############################################################################
# Copyright (c) 2018, PulseRain Technology LLC 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
*/

`include "common.vh"

`default_nettype none

module PulseRain_Rattlesnake_MCU #(parameter sim = 0) (

    //=====================================================================
    // clock and reset
    //=====================================================================
        input   wire                                            clk,                          
        input   wire                                            reset_n,                      
        input   wire                                            sync_reset,

    //=====================================================================
    // Interface Onchip Debugger
    //=====================================================================
        input   wire                                            ocd_read_enable,
        input   wire                                            ocd_write_enable,
        
        input   wire  [`MEM_ADDR_BITS - 1 : 0]                  ocd_rw_addr,
        input   wire  [`XLEN - 1 : 0]                           ocd_write_word,
        
        output  wire                                            ocd_mem_enable_out,
        output  wire  [`XLEN - 1 : 0]                           ocd_mem_word_out,        
        
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  ocd_reg_read_addr,
        input   wire                                            ocd_reg_we,
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  ocd_reg_write_addr,
        input   wire  [`XLEN - 1 : 0]                           ocd_reg_write_data,

    //=====================================================================
    // UART
    //=====================================================================
        input   wire                                            RXD,
        output  wire                                            TXD,
    
    //=====================================================================
    // Interface for init/start
    //=====================================================================
        input   wire                                            start,
        input   wire  [`PC_BITWIDTH - 1 : 0]                    start_address,
        
        output  wire                                            processor_paused,

        
        output  wire  [`XLEN - 1 : 0]                           peek_pc,
        output  wire  [`XLEN - 1 : 0]                           peek_ir,
        
        output  wire  [`XLEN_BYTES - 1 : 0]                     peek_mem_write_en,
        output  wire  [`XLEN - 1 : 0]                           peek_mem_write_data,
        output  wire [`MEM_ADDR_BITS - 1 : 0]                   peek_mem_addr
        
);
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
        wire [`MEM_ADDR_BITS - 1 : 0]                           mem_addr;
        
        wire                                                    mem_read_en;
        wire [`XLEN_BYTES - 1 : 0]                              mem_write_en;
        wire [`XLEN - 1 : 0]                                    mem_write_data;
        wire [`XLEN - 1 : 0]                                    mem_read_data;
        wire                                                    mem_write_ack;
        wire                                                    mem_read_ack;
                        
        wire                                                    start_TX;
        wire [7 : 0]                                            tx_data;
        wire                                                    tx_active;
        
        wire  [`MEM_ADDR_BITS - 1 : 0]                          mem_addr_ack;
        
        wire                                                    WB_RD_CYC;
        wire                                                    WB_RD_STB;
        wire  unsigned [`MM_REG_ADDR_BITS - 1 : 0]              WB_RD_ADR;
        wire  unsigned [`XLEN - 1 : 0]                          WB_RD_DAT;
        wire                                                    WB_RD_ACK;
        
        wire                                                    WB_WR_CYC;
        wire                                                    WB_WR_STB;
        wire                                                    WB_WR_WE;
        wire unsigned [`XLEN_BYTES - 1 : 0]                     WB_WR_SEL;
        wire unsigned [`MM_REG_ADDR_BITS - 1 : 0]               WB_WR_ADR;
        wire unsigned [`XLEN - 1 : 0]                           WB_WR_DAT;
        wire                                                    WB_WR_ACK;
        
        wire                                                    int_gen;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // processor core
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
         
         PulseRain_Rattlesnake_core PulseRain_Rattlesnake_core_i (
                .clk        (clk),
                .reset_n    (reset_n),
                .sync_reset (sync_reset),
                
                .ocd_read_enable  (ocd_read_enable),
                .ocd_write_enable (ocd_write_enable),
                
                .ocd_rw_addr (ocd_rw_addr),
                .ocd_write_word (ocd_write_word),
                
                .ocd_mem_enable_out (ocd_mem_enable_out),
                .ocd_mem_word_out (ocd_mem_word_out),        
                
                .ocd_reg_read_addr (ocd_reg_read_addr),
                .ocd_reg_we (ocd_reg_we),
                .ocd_reg_write_addr (ocd_reg_write_addr),
                .ocd_reg_write_data (ocd_reg_write_data),
                
                .ext_int_triggered (int_gen),
                
                .WB_RD_CYC_O (WB_RD_CYC),
                .WB_RD_STB_O (WB_RD_STB),
                .WB_RD_ADR_O (WB_RD_ADR),
                .WB_RD_DAT_I (WB_RD_DAT),
                .WB_RD_ACK_I (WB_RD_ACK),
                
                .WB_WR_CYC_O (WB_WR_CYC),
                .WB_WR_STB_O (WB_WR_STB),
                .WB_WR_WE_O  (WB_WR_WE),
                .WB_WR_SEL_O (WB_WR_SEL),
                .WB_WR_ADR_O (WB_WR_ADR),
                .WB_WR_DAT_O (WB_WR_DAT),
                .WB_WR_ACK_I (WB_WR_ACK),
    
                .start (start),
                .start_address (start_address),
                
                .peek_pc (peek_pc),
                .peek_ir (peek_ir),
                
                .mem_addr (mem_addr),
                .mem_read_en (mem_read_en),
                .mem_write_en (mem_write_en),
                .mem_write_data (mem_write_data),
                .mem_read_data (mem_read_data),
                .mem_write_ack (mem_write_ack),
                .mem_read_ack (mem_read_ack),
                .processor_paused (processor_paused),
                .mem_addr_ack (mem_addr_ack));

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // memory 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        mem_controller #(.sim(sim)) mem_controller_i (
            .clk        (clk),
            .reset_n    (reset_n),
            .sync_reset (sync_reset),
            
            .mem_addr       (mem_addr),
            .mem_read_en    (mem_read_en),
            .mem_write_en   (mem_write_en),
            .mem_write_data (mem_write_data),
            .mem_read_data  (mem_read_data),
            
            .mem_write_ack  (mem_write_ack),
            .mem_read_ack   (mem_read_ack),
            
            .mem_addr_ack (mem_addr_ack));  
        
           
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // peripherals 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        genvar i;
        generate 
            for (i = 0; i < `INCLUDE_PERIPHERAL ; i = i + 1) begin : gen_peripheral
               peripherals peripherals_i (
                    .clk                (clk),
                    .reset_n            (reset_n),
                    .sync_reset         (sync_reset),
                
                
                    .WB_RD_STB_I (WB_RD_STB),
                    .WB_RD_ADR_I (WB_RD_ADR),
                    .WB_RD_DAT_O (WB_RD_DAT),
                    .WB_RD_ACK_O (WB_RD_ACK),
                    
                    .WB_WR_STB_I (WB_WR_STB),
                    .WB_WR_WE_I  (WB_WR_WE),
                    .WB_WR_SEL_I (WB_WR_SEL),
                    .WB_WR_ADR_I (WB_WR_ADR),
                    .WB_WR_DAT_I (WB_WR_DAT),
                    .WB_WR_ACK_O (WB_WR_ACK),
                    
                    .int_gen     (int_gen),
                
                    .RXD         (RXD),
                    .TXD         (TXD)
                
                );
            end
        endgenerate
        
        assign  peek_mem_write_en   = mem_write_en;
        assign  peek_mem_write_data = mem_write_data;
        assign  peek_mem_addr       = mem_addr;    
            
endmodule

`default_nettype wire
