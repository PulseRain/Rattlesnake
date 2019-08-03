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


`include "common.vh"
`include "config.vh"

`default_nettype none

module Rattlesnake_machine_timer (

    //=======================================================================
    // clock / reset
    //=======================================================================
        input   wire                                            clk,
        input   wire                                            reset_n,
        input   wire                                            sync_reset,

    //=======================================================================
    //  control 
    //=======================================================================
        input wire                                              load_mtimecmp_low,
        input wire                                              load_mtimecmp_high,
        input wire [`XLEN - 1 : 0]                              mtimecmp_write_data,
        
        output reg                                              timer_triggered,
        
        input  wire [1 : 0]                                     reg_read_addr,
        output reg [`XLEN - 1 : 0]                              reg_read_data 

);

   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Signals
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg   [`MTIME_CYCLE_PERIOD_BITS - 1 : 0]                mtime_cycle_counter;
        reg                                                     mtime_cycle_pulse;
        
        reg   [`XLEN * (2 - `SMALL_MACHINE_TIMER) - 1 : 0]      mtime;
        reg   [`XLEN * (2 - `SMALL_MACHINE_TIMER) - 1 : 0]      mtimecmp;
        
        reg   [`XLEN - 1 : 0]                                   mtime_high; 
        
       
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // mtime_cycle_counter
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        /* verilator lint_off WIDTH */
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                mtime_cycle_counter <= 0;
                mtime_cycle_pulse <= 0;
   
            end else if (mtime_cycle_counter != (`MTIME_CYCLE_PERIOD - 1)) begin 
                mtime_cycle_counter <= mtime_cycle_counter + ($size(mtime_cycle_counter))'(1);
                mtime_cycle_pulse <= 0;
            end else begin
                mtime_cycle_counter <= 0;
                mtime_cycle_pulse   <= 1'b1; 
            end
        end
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // mtime
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
       
        generate 
            if (`SMALL_MACHINE_TIMER) begin
                
                always @(posedge clk, negedge reset_n) begin : mtime_proc
                    if (!reset_n) begin
                        mtime <= 0;
                    end else begin
                        mtime <= mtime + 1;
                    end
                end
            
            end else begin
            
                always @(posedge clk, negedge reset_n) begin : mtime_proc
                    if (!reset_n) begin
                        mtime <= 0;
                    end else if (mtime_cycle_pulse) begin
                        mtime <= mtime + 1;
                    end
                end
                
            end
        endgenerate
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // mtimecmp
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        generate 
            if (`SMALL_MACHINE_TIMER) begin
                
                always @(posedge clk, negedge reset_n) begin : mtimecmp_proc
                    if (!reset_n) begin
                        mtimecmp <= 0;
                    end else if (load_mtimecmp_low) begin
                        mtimecmp [`XLEN - 1 : 0] <= mtimecmp_write_data;
                    end
                end
                
            end else begin
                    
                always @(posedge clk, negedge reset_n) begin : mtimecmp_proc
                    if (!reset_n) begin
                        mtimecmp <= 0;
                    end else if (load_mtimecmp_low) begin
                        mtimecmp [`XLEN - 1 : 0] <= mtimecmp_write_data;
                    end else if (load_mtimecmp_high) begin
                        mtimecmp [`XLEN * 2 - 1 : `XLEN] <= mtimecmp_write_data;
                    end
                end 
            end
        endgenerate
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // timer trigger
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : timer_triggered_proc
            if (!reset_n) begin
                timer_triggered <= 0;
            end else if (load_mtimecmp_low | load_mtimecmp_high) begin
                timer_triggered <= 0;
            end else if (mtime >= mtimecmp) begin
                timer_triggered <= 1'b1;
            end
        end
        
        generate 
            if (`SMALL_MACHINE_TIMER) begin
                always @(posedge clk, negedge reset_n) begin
                    if (!reset_n) begin
                        reg_read_data <= 0;
                    end else begin
                        
                        case (reg_read_addr) 
                            2'b01 : begin
                                reg_read_data <= 0;
                            end
                            
                            2'b10 : begin
                                reg_read_data <= mtimecmp;
                            end
                        
                            2'b11 : begin
                                reg_read_data <= 0;
                            end
                            
                            default : begin
                                reg_read_data <= mtime;
                            end
                        endcase
                    end
                end
            end else begin
                always @(posedge clk, negedge reset_n) begin
                    if (!reset_n) begin
                        reg_read_data <= 0;
                        mtime_high <= 0;
                    end else begin
                        case (reg_read_addr) 
                            2'b01 : begin
                                reg_read_data <= mtime_high;
                            end
                            
                            2'b10 : begin
                                reg_read_data <= mtimecmp [`XLEN - 1 : 0];
                            end
                        
                            2'b11 : begin
                                reg_read_data <= mtimecmp [`XLEN * 2 - 1 : `XLEN];
                            end
                            
                            default : begin
                                reg_read_data <= mtime [`XLEN - 1 : 0];
                                mtime_high <= mtime [`XLEN * 2 - 1 : `XLEN];
                            end
                        
                        endcase

                    end
                end
            end
        endgenerate

endmodule

`default_nettype wire
