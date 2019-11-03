/*
###############################################################################
# Copyright (c) 2018, PulseRain Technology LLC 
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
//   FIFO for UART. 
//=============================================================================


`include "config.vh"

`default_nettype none

module UART_FIFO #(parameter FIFO_SIZE = 4, WIDTH = 8)(
        
    input   wire                                        clk,
    input   wire                                        reset_n,
    input   wire                                        sync_reset,
    
    input   wire                                        fifo_write,
    input   wire unsigned [WIDTH - 1 : 0]               fifo_data_in,
    
    input   wire                                        fifo_read,
    output  wire unsigned [WIDTH - 1 : 0]               fifo_top_data_out,
    
    output  logic                                       fifo_not_empty,
    output  logic                                       fifo_full,
    output  logic unsigned [$clog2(FIFO_SIZE) - 1 : 0]  fifo_count
);
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        logic  [0 : FIFO_SIZE - 1][WIDTH - 1 : 0]       mem  /* synthesis ramstyle = "logic" */;
          
        logic  unsigned [$clog2(FIFO_SIZE) - 1 : 0]     write_pointer = 0;
        logic  unsigned [$clog2(FIFO_SIZE) - 1 : 0]     read_pointer = 0;
       // wire   unsigned [$clog2(FIFO_SIZE) - 1 : 0]     next_write_pointer;
       // wire   unsigned [$clog2(FIFO_SIZE) - 1 : 0]     next_read_pointer;
        
        
        
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // read / write pointer
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
       // assign next_write_pointer = write_pointer + 1;
       // assign next_read_pointer  = read_pointer + 1;
        
        always_ff @(posedge clk, negedge reset_n) begin : rw_pointer_proc
            if (!reset_n) begin
                write_pointer <= 0;
                read_pointer  <= 0;
                fifo_count <= 0;
            end else begin
                if (sync_reset) begin
                    write_pointer <= 0;
                    read_pointer  <= 0;
                    fifo_count <= 0;
                end else if (fifo_write & fifo_read) begin
                    write_pointer <= write_pointer + ($size(write_pointer))'(1);
                    read_pointer <= read_pointer + ($size(read_pointer))'(1);
                end else if (fifo_write & (~fifo_full)) begin
                    write_pointer <= write_pointer + ($size(write_pointer))'(1);
                    fifo_count <= fifo_count + ($size(fifo_count))'(1);
                end else if (fifo_read & fifo_not_empty) begin
                    read_pointer <= read_pointer + ($size(read_pointer))'(1);
                    fifo_count <= fifo_count - ($size(fifo_count))'(1);
                end
                
            end
            
        end : rw_pointer_proc
        
        assign fifo_full = &fifo_count;
        assign fifo_not_empty = |fifo_count; 
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // mem
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk) begin : mem_write_proc
            if (fifo_write) begin
                mem [write_pointer] <= fifo_data_in;
            end
        end : mem_write_proc
        
        assign fifo_top_data_out = mem [read_pointer];
        
endmodule : UART_FIFO
    
`default_nettype wire
