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

`default_nettype none

module Rattlesnake_indirect_pointer_detect (

     //=====================================================================
     // clock and reset
     //=====================================================================
        input wire                                              clk,                          
        input wire                                              reset_n,                      
        input wire                                              sync_reset,

     //=====================================================================
     // interface from the controller   
     //=====================================================================
        input wire                                              exe_enable,
        input wire  [`EXT_BITS + `XLEN - 1 : 0]                 rs1_in_copy,
        input wire  [`EXT_BITS + `XLEN - 1 : 0]                 rs2_in_copy,
                 
     //=====================================================================
     // interface for the instruction decode
     //=====================================================================

        input wire [`XLEN - 1 : 0]                              IR_in,
        input wire [`XLEN - 1 : 0]                              IR_original_in,
        input wire [`PC_BITWIDTH - 1 : 0]                       PC_in,
       
        input   wire                                            exception_handler_active,
        
        input wire [`MEM_ADDR_BITS - 1 : 0]                     mem_addr_blk_wr_start,
        input wire [`MEM_ADDR_BITS - 1 : 0]                     mem_addr_blk_wr_end,
        
        output reg                                              indirect_protect_active
); 

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg [4 : 0]                                     rd_save;
        reg [4 : 0]                                     rd_aux_save;
        
        reg [`EXT_BITS +`XLEN - 1 : 0]                  rs1_in_copy_save;
        reg [`XLEN - 1 : 0]                             s0_offset_save;
        
        wire [`MEM_ADDR_BITS - 1 : 0]                   rs1_in_copy_save_addr;
        wire [`MEM_ADDR_BITS - 1 : 0]                   s0_offset_save_addr;
        
        reg                                             ctl_save_rd;
        reg                                             ctl_save_rd_aux;
    
        reg                                             ctl_indirect_protect_active;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Data Path
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                rd_save <= 0;
                rs1_in_copy_save <= 0;
            end else if (ctl_save_rd) begin
                rd_save <= IR_in[11 : 7];
                rs1_in_copy_save <= rs1_in_copy;
            end
        end
    
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                rd_aux_save <= 0;
                s0_offset_save <= 0;
            end else if (ctl_save_rd_aux) begin
                rd_aux_save <= IR_in[11 : 7];
                s0_offset_save <= rs1_in_copy [`XLEN - 1 : 0] + {{21{IR_in[31]}}, IR_in[30 : 25], 5'd0};
            end
        end
        
        assign rs1_in_copy_save_addr = rs1_in_copy_save [`MEM_ADDR_BITS : 1];
        assign s0_offset_save_addr   = s0_offset_save [`MEM_ADDR_BITS : 1];
        
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                indirect_protect_active <= 0;
            end else if (exe_enable) begin
                indirect_protect_active <= ctl_indirect_protect_active;
            end
        end 
    
//                            *(uint32_t *) (*(uint32_t *) target_addr) =
// 8004328e:	93042783          	lw	a5,-1744(s0)
// 80043292:	439c                	lw	a5,0(a5)
//                          (uintptr_t) stack_mem_ptr_aux;
// 80043294:	ea442703          	lw	a4,-348(s0)
//                        *(uint32_t *) (*(uint32_t *) target_addr) =
// 80043298:	c398                	sw	a4,0(a5)

     //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        localparam S_1ST_LW = 0, S_2ND_LW = 1, S_3RD_LW = 2, S_SW = 3, S_DETECT = 4;
                   
        reg [4 : 0] current_state, next_state;
                  
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
            
            ctl_save_rd = 0;
            ctl_save_rd_aux = 0;
            
            ctl_indirect_protect_active = 0;
               
            case (1'b1) // synthesis parallel_case 
                
                current_state[S_1ST_LW]: begin
                    if (exe_enable & (~exception_handler_active)) begin
                        if ((IR_in[6 : 2] == `CMD_LOAD) && (IR_in[14 : 12] == 3'b010) && (IR_in[19 : 15] == 5'b01000)) begin // LW ... , xxx(s0)
                            next_state [S_2ND_LW] = 1'b1;
                            ctl_save_rd = 1'b1;
                        end else begin
                            next_state [S_1ST_LW] = 1'b1;
                        end
                    end else begin
                        next_state [S_1ST_LW] = 1'b1;
                    end
                end
                
                current_state[S_2ND_LW]: begin
                
                    if (exe_enable & (~exception_handler_active)) begin
                        if ((IR_in[6 : 2] == `CMD_LOAD) && (IR_in[14 : 12] == 3'b010) && (IR_in[19 : 15] == rd_save)) begin // LW ... , xxx(rd)
                            next_state [S_3RD_LW] = 1'b1;
                            ctl_save_rd = 1'b1;
                        end else begin
                            next_state [S_1ST_LW] = 1'b1;
                        end
                    end else begin
                        next_state [S_2ND_LW] = 1'b1;
                    end
                end
                
                current_state [S_3RD_LW] : begin
                
                    if (exe_enable & (~exception_handler_active)) begin
                        if ((IR_in[6 : 2] == `CMD_LOAD) && (IR_in[14 : 12] == 3'b010) && (IR_in[19 : 15] == 5'b01000)) begin /// LW ... , xxx(s0)
                            next_state[S_SW] = 1'b1;
                            ctl_save_rd_aux = 1'b1;
                        end else begin
                            next_state [S_1ST_LW] = 1'b1;
                        end
                    end else begin
                        next_state [S_3RD_LW] = 1'b1;
                    end
                    
                end
                
                current_state [S_SW] : begin
                    if (exe_enable & (~exception_handler_active)) begin
                        if (((IR_in[6 : 2] == `CMD_STORE) && (IR_in[14 : 12] == 3'b010) && (IR_in[19 : 15] == rd_save) && (IR_in[24 : 20] == rd_aux_save) ) &&  
                            (rs1_in_copy [`XLEN]  || rs2_in_copy [`XLEN])) begin /// SW
                       
                     //  if (((IR_in[6 : 2] == `CMD_STORE) && (IR_in[14 : 12] == 3'b010) && (IR_in[19 : 15] == rd_save) && (IR_in[24 : 20] == rd_aux_save) ) &&  
                     //       (((mem_addr_blk_wr_start <=  rs1_in_copy_save_addr) && (mem_addr_blk_wr_end >  rs1_in_copy_save_addr)) ||
                     //        ((mem_addr_blk_wr_start <=  s0_offset_save_addr) && (mem_addr_blk_wr_end >  s0_offset_save_addr)) )) begin /// SW
                             
                            ctl_indirect_protect_active = 1'b1;
                            next_state [S_DETECT] = 1'b1;
                        end else begin
                            next_state [S_1ST_LW] = 1'b1;
                        end
                    end else begin
                        next_state [S_SW] = 1'b1;
                    end
                
                end
                
                current_state [S_DETECT] : begin
                    next_state [S_1ST_LW] = 1'b1;
                end
                
                default: begin
                    next_state[S_1ST_LW] = 1'b1;
                end
                
            endcase
              
        end  

endmodule

`default_nettype wire
