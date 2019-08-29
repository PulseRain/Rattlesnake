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

module Rattlesnake_instruction_decode (

     //=====================================================================
     // clock and reset
     //=====================================================================
        input wire                                              clk,                          
        input wire                                              reset_n,                      
        input wire                                              sync_reset,
   
     //=====================================================================
     // interface from the controller   
     //=====================================================================
        input wire                                              decode_enable,
        
     //=====================================================================
     // interface for the instruction fetch
     //=====================================================================
        input wire                                              enable_in,
        input wire [`XLEN - 1 : 0]                              IR_in,
        input wire [`XLEN - 1 : 0]                              IR_original_in,
        input wire [`PC_BITWIDTH - 1 : 0]                       PC_in,

     //=====================================================================
     // interface for register read
     //=====================================================================
        output wire [`REG_ADDR_BITS - 1 : 0]                    rs1,
        output wire [`REG_ADDR_BITS - 1 : 0]                    rs2,
     
     //=====================================================================
     // interface for CSR read
     //=====================================================================
        output  wire [`CSR_BITS - 1 : 0]                        csr,
        output  reg                                             csr_read_enable,
         
     //=====================================================================
     // interface for next stage
     //=====================================================================

        output reg                                              enable_out,
        output reg [`XLEN - 1 : 0]                              IR_out,
        output reg [`XLEN - 1 : 0]                              IR_original_out,
        output reg [`PC_BITWIDTH - 1 : 0]                       PC_out,
        
        output reg                                              ctl_load_X_from_rs1,
        output reg                                              ctl_load_Y_from_rs2,
        output reg                                              ctl_load_Y_from_imm_12,
        output reg                                              ctl_save_to_rd,
        output reg                                              ctl_ALU_FUNCT3,
        output reg                                              ctl_MUL_DIV_FUNCT3,
        output reg                                              ctl_LUI,
        output reg                                              ctl_AUIPC,
        output reg                                              ctl_JAL,
        output reg                                              ctl_JALR,
        output reg                                              ctl_BRANCH,
        output reg                                              ctl_LOAD,
        output reg                                              ctl_STORE,
        output reg                                              ctl_SYSTEM,
        output reg                                              ctl_CSR,
        output reg                                              ctl_CSR_write,
        output reg                                              ctl_MISC_MEM,
        output reg                                              ctl_MRET,
        output reg                                              ctl_WFI
);
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire    [`REG_ADDR_BITS - 1 : 0]                        rs1_32;
        wire    [`REG_ADDR_BITS - 1 : 0]                        rs2_32;
        
        wire    [2 : 0]                                         funct3;
        wire    [11 : 0]                                        funct12;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // data path
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
        //---------------------------------------------------------------------
        // register read
        //---------------------------------------------------------------------
            
            assign rs1_32 = IR_in [19 : 15];
            assign rs2_32 = IR_in [24 : 20];

            assign rs1 = rs1_32;
            assign rs2 = rs2_32;

        //---------------------------------------------------------------------
        // CSR read
        //---------------------------------------------------------------------
            
            assign csr     = IR_in [31 : 20];
            assign funct3  = IR_in [14 : 12];
            assign funct12 = IR_in [31 : 20];
            
            // If rd=x0, then the instruction shall not read the CSR and shall
            // not cause any of the side-effects that might occur on a CSR read.

            always @(*) begin : csr_read_enable_proc
                csr_read_enable = ctl_SYSTEM & ctl_CSR;
            
            end
            
            
        //---------------------------------------------------------------------
        // output
        //---------------------------------------------------------------------
            
            
            always @(posedge clk, negedge reset_n) begin
                if (!reset_n) begin
                    IR_out <= 0;
                    IR_original_out <= 0;
                    PC_out <= 0;
                    enable_out <= 0;
                end else begin
                    enable_out <= enable_in;
                    IR_out <= IR_in;
                    IR_original_out <= IR_original_in;
                    PC_out <= PC_in;
                end
            end
            
        //---------------------------------------------------------------------
        // instruction decode
        //---------------------------------------------------------------------

            always @(*) begin : decode_proc
                ctl_load_X_from_rs1 = 0;
                ctl_load_Y_from_rs2 = 0;
                ctl_load_Y_from_imm_12 = 0;
                
                ctl_save_to_rd = 0;
                
                ctl_ALU_FUNCT3 = 0;
                ctl_MUL_DIV_FUNCT3 = 0;
                ctl_LUI = 0;
                ctl_AUIPC = 0;
                
                ctl_JAL = 0;
                ctl_JALR = 0;
                
                ctl_BRANCH = 0;
                ctl_LOAD = 0;
                ctl_STORE = 0;
                ctl_SYSTEM = 0;
                ctl_CSR = 0;
                ctl_CSR_write = 0;
                ctl_MISC_MEM = 0;
                ctl_MRET = 0;
                ctl_WFI = 0;
                
                case (IR_out [6 : 2]) // synthesis parallel_case 
                    `CMD_OP_IMM : begin
                        ctl_load_X_from_rs1 = 1'b1;
                        ctl_load_Y_from_imm_12 = 1'b1;
                        ctl_save_to_rd = 1'b1;
                        ctl_ALU_FUNCT3 = 1'b1;
                    end
                        
                    `CMD_OP : begin
                        ctl_load_X_from_rs1 = 1'b1;
                        ctl_load_Y_from_rs2 = 1'b1;
                        ctl_save_to_rd = 1'b1;
                        ctl_ALU_FUNCT3 = ~IR_out[25];
                        ctl_MUL_DIV_FUNCT3 = IR_out[25];
                    end
                        
                    `CMD_LUI : begin
                        ctl_LUI = 1'b1;
                        ctl_save_to_rd = 1'b1;
                    end
                        
                    `CMD_AUIPC : begin
                        ctl_AUIPC = 1'b1;
                        ctl_save_to_rd = 1'b1;
                    end
                        
                    `CMD_JAL : begin
                        ctl_JAL = 1'b1;
                        ctl_save_to_rd = 1'b1;
                    end
                    
                    `CMD_JALR : begin
                        ctl_JALR = 1'b1;
                        ctl_save_to_rd = 1'b1;
                        ctl_load_X_from_rs1 = 1'b1;
                    end
                    
                    `CMD_BRANCH : begin
                        ctl_BRANCH = 1'b1;
                        ctl_load_X_from_rs1 = 1'b1;
                        ctl_load_Y_from_rs2 = 1'b1;
                    end
                    
                    `CMD_LOAD : begin
                        ctl_LOAD = 1'b1;
                        ctl_load_X_from_rs1 = 1'b1;
                      //  ctl_save_to_rd = 1'b1;
                    end

                    `CMD_STORE : begin
                        ctl_STORE = 1'b1;
                        ctl_load_X_from_rs1 = 1'b1;
                        ctl_load_Y_from_rs2 = 1'b1;
                    end
                    
                    `CMD_SYSTEM : begin
                        ctl_SYSTEM = 1'b1;
                        
                        if ((funct12 [4 : 0] == 5'b00010) && (funct3 == 3'b000)) begin
                            ctl_MRET = 1'b1;
                        end else if ((funct12 [4 : 0] == 5'b00101) && (funct3 == 3'b000)) begin
                            ctl_WFI = 1'b1;
                        end else begin
                            ctl_CSR = |funct3;
                        end 
                        
                        ctl_save_to_rd = ctl_CSR;
                        ctl_CSR_write = |rs1;
                        ctl_load_X_from_rs1 = 1'b1;
                        
                    end

                    `CMD_MISC_MEM : begin
                        ctl_MISC_MEM = 1'b1;
                    end
                        
                    default : begin

                    end
                        
                endcase

            end

endmodule

`default_nettype wire
 