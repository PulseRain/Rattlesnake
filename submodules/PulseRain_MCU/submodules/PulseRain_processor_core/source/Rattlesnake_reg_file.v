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
//    To save space, the register file of PulseRain RV2T is implemented with
//    block RAM (BRAM). 
//    To support two read and one write simultaneously, two BRAMs are used
//
//    Another option is to use only one BRAM, with extra clock cycle as penalty
//=============================================================================

`include "common.vh"

`default_nettype none

module Rattlesnake_reg_file (

    //=======================================================================
    // clock / reset
    //=======================================================================
        input   wire                                            clk,
        input   wire                                            reset_n,
        input   wire                                            sync_reset,

    //=======================================================================
    //  register read / write
    //=======================================================================
        input   wire                                            read_enable,
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  read_rs1_addr,
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  read_rs2_addr,
        
        output  reg                                             read_en_out,
        output  wire  [`XLEN - 1 : 0]                           read_rs1_data_out,
        output  wire  [`XLEN - 1 : 0]                           read_rs2_data_out,
        
        input   wire                                            write_enable,
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  write_addr,
        input   wire  [`XLEN - 1 : 0]                           write_data_in

);

   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Signals
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire   [`XLEN - 1 : 0]                                  read_rs1_data_out_i;
        wire   [`XLEN - 1 : 0]                                  read_rs2_data_out_i;
        reg                                                     write_enable_d1;
        reg    [`XLEN - 1 : 0]                                  write_data_in_d1;
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // datapath
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        dual_port_ram #(.ADDR_WIDTH (`REG_ADDR_BITS), .DATA_WIDTH (`XLEN)) single_clk_ram_rs1 (
            .waddr (write_addr),
            .raddr (read_rs1_addr),
            .din (write_data_in),
            .write_en (write_enable),
            .clk (clk),
            .dout (read_rs1_data_out_i) );
            
        dual_port_ram #(.ADDR_WIDTH (`REG_ADDR_BITS), .DATA_WIDTH (`XLEN)) single_clk_ram_rs2 (
            .waddr (write_addr),
            .raddr (read_rs2_addr),
            .din (write_data_in),
            .write_en (write_enable),
            .clk (clk),
            .dout (read_rs2_data_out_i) );
           
        assign read_rs1_data_out = (|read_rs1_addr) ? (((write_enable_d1 == 1'b1) && (read_rs1_addr == write_addr)) ? write_data_in_d1 : read_rs1_data_out_i) : 0;
        assign read_rs2_data_out = (|read_rs2_addr) ? (((write_enable_d1 == 1'b1) && (read_rs2_addr == write_addr)) ? write_data_in_d1 : read_rs2_data_out_i) : 0;
        
        always @(posedge clk, negedge reset_n) begin : output_proc
            if (!reset_n) begin
                read_en_out     <= 0;
                write_enable_d1 <= 0;
                write_data_in_d1  <= 0;
            end else begin
                read_en_out      <= read_enable;
                write_enable_d1  <= write_enable;
                write_data_in_d1 <= write_data_in;
            end
        end
 
endmodule

`default_nettype wire
