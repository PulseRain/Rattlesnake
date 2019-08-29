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

module Rattlesnake_block_write_detect (

    //=====================================================================
    // clock and reset
    //=====================================================================
        input   wire                                            clk,                          
        input   wire                                            reset_n,                      
        input   wire                                            sync_reset,

    
    //=====================================================================
    // Interface for memory
    //=====================================================================
        
        input   wire [`XLEN_BYTES - 1 : 0]                      mem_write_en,
        input   wire  [`MEM_ADDR_BITS - 1 : 0]                  mem_addr,
        
        input   wire                                            exception_handler_active,
        
    //=====================================================================
    // Interface for memory
    //=====================================================================
        output  reg  [`MEM_ADDR_BITS - 1 : 0]                   mem_addr_blk_wr_start = 0,
        output  reg  [`MEM_ADDR_BITS - 1 : 0]                   mem_addr_blk_wr_end = 0,
        output  wire                                            blk_write_active
       
);
     
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg                                                     ctl_load_start_addr;
        reg                                                     ctl_load_end_addr;
        
        reg  [`MEM_ADDR_BITS - 1 : 0]                           mem_wr_len;
        
        reg  [$clog2(`BLOCK_WRITE_THRESHOLD) : 0]               write_cnt = 0;
        
        reg  [`MEM_ADDR_BITS - 1 : 0]                           mem_addr_blk_wr_start_i = 0;
        reg  [`MEM_ADDR_BITS - 1 : 0]                           mem_addr_blk_wr_end_i = 0;
        
        reg                                                     blk_write_active_i = 0;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Data Path
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        assign blk_write_active = blk_write_active_i & (~ctl_load_start_addr);
        
        always @(posedge clk, negedge reset_n) begin : blk_wr_proc
            if (!reset_n) begin
                mem_addr_blk_wr_start_i <= 0;
                mem_addr_blk_wr_end_i   <= 0;
                write_cnt <= 0;
                
                mem_addr_blk_wr_start <= 0;
                mem_addr_blk_wr_end   <= 0;
                
                blk_write_active_i      <= 0;
            end else begin
                if (ctl_load_start_addr) begin
                    mem_addr_blk_wr_start_i <= mem_addr;
                end
        
                if (ctl_load_start_addr | ctl_load_end_addr) begin
                    mem_addr_blk_wr_end_i <= mem_addr;
                end
                
                if (ctl_load_start_addr) begin
                    write_cnt <= 0;
                end else if (ctl_load_end_addr && (write_cnt < `BLOCK_WRITE_THRESHOLD)) begin
                    write_cnt <= write_cnt + 1;
                end
                
                if (write_cnt == `BLOCK_WRITE_THRESHOLD) begin
                    mem_addr_blk_wr_start <= mem_addr_blk_wr_start_i;
                    mem_addr_blk_wr_end   <= mem_addr_blk_wr_end_i + (`MEM_ADDR_BITS)'(2);
                 end
                
                if (ctl_load_start_addr) begin
                    blk_write_active_i <= 0;
                end else if (write_cnt == `BLOCK_WRITE_THRESHOLD) begin
                    blk_write_active_i <= 1'b1;
                end 
                
            end
        end

        always @(*) begin
            case (mem_write_en) // synthesis parallel_case 
                4'b1111 : begin
                    mem_wr_len = (`MEM_ADDR_BITS)'(2);
                end
                
                4'b0011, 4'b1100 : begin
                    mem_wr_len = (`MEM_ADDR_BITS)'(1);
                end
                
                default: begin
                    if (mem_write_en[0] | mem_write_en[2]) begin
                        mem_wr_len = (`MEM_ADDR_BITS)'(1);
                    end else begin
                        mem_wr_len = (`MEM_ADDR_BITS)'(0);
                    end
                end
            endcase
            
        end
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        localparam S_1ST_WRITE = 0, S_NEXT_WRITES = 1;
                   
        reg [1 : 0] current_state, next_state;
                  
        // Declare states
        always @(posedge clk, negedge reset_n) begin : state_machine_reg
            if (!reset_n) begin
                current_state <= 0;
            end else if (sync_reset) begin 
                current_state <= 0;
            end else begin
                current_state <= next_state;
            end
        end
            
        // FSM main body
        always @(*) begin : state_machine_comb

            next_state = 0;
            
            ctl_load_start_addr = 0;
            ctl_load_end_addr = 0;
            
            case (1'b1) // synthesis parallel_case 
                
                current_state[S_1ST_WRITE]: begin
                    if ((|mem_write_en) & (~exception_handler_active)) begin
                        ctl_load_start_addr = 1'b1;
                        next_state [S_NEXT_WRITES] = 1'b1;
                    end else begin
                        next_state [S_1ST_WRITE] = 1'b1;
                    end
                end
                
                current_state[S_NEXT_WRITES]: begin
                
                    next_state [S_NEXT_WRITES] = 1'b1;
                    
                    if ((|mem_write_en) & (~exception_handler_active)) begin
                        if ((mem_addr_blk_wr_end_i + mem_wr_len) == mem_addr) begin
                            ctl_load_end_addr = 1'b1;
                            
                        end else begin
                            ctl_load_start_addr = 1'b1;
                        end
                        
                    end
                end
                
                default: begin
                    next_state[S_1ST_WRITE] = 1'b1;
                end
                
            endcase
              
        end  

endmodule

`default_nettype wire
