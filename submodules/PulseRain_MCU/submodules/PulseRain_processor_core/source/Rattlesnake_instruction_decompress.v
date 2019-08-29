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
//    convert C extension to regular 32 bit instruction
//=============================================================================


`include "common.vh"

`default_nettype none


module Rattlesnake_instruction_decompress (

    //=====================================================================
    // clock and reset
    //=====================================================================
            
        input wire                                          clk,                          
        input wire                                          reset_n,                      
        input wire                                          sync_reset,

    //=====================================================================
    // data from memory
    //=====================================================================
    
        input wire                                          mem_read_done,
        input wire  [`XLEN - 1 : 0]                         mem_data_in,
        
        input  wire [`MEM_ADDR_BITS - 1 : 0]                mem_addr_ack_in,
    
    //=====================================================================
    // converted instruction output
    //=====================================================================
        
        output reg                                          enable_out,
        output reg [`XLEN - 1 : 0]                          instruction_out,
        output reg [`XLEN - 1 : 0]                          instruction_original,
        output reg [`MEM_ADDR_BITS - 1 : 0]                 mem_addr_ack_out
        
);
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Signal
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            wire [4 : 0]                                    rd_apostrophe;
            wire [4 : 0]                                    rs1_apostrophe;
            wire [4 : 0]                                    rs2_apostrophe;
            wire [4 : 0]                                    rs1_rd_apostrophe;
            
            wire [11 : 0]                                   CIW_imm12;
            wire [11 : 0]                                   CL_offset12;
            wire [2 : 0]                                    funct3;
            
            wire [4 : 0]                                    rd_rs1;
            wire [4 : 0]                                    rs2;
            
            wire [11 : 0]                                   CI_imm12;
            wire [19 : 0]                                   CI_imm20;
            wire [19 : 0]                                   CJ_imm20;
            
            wire [11 : 0]                                   CI_imm12_ADDI16SP;
            
            wire [11 : 0]                                   CB_offset12;
            
            wire [11 : 0]                                   CS_imm12;
            
            wire [11 : 0]                                   CI_LWSP_uimm12;
      
            
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // data path
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            
            
            assign rs1_apostrophe = {2'b01, mem_data_in[9 : 7]};
            assign rs2_apostrophe = {2'b01, mem_data_in[4 : 2]};
            assign rd_apostrophe  = rs2_apostrophe;
            
            assign rs1_rd_apostrophe = rs1_apostrophe;
            
            assign CIW_imm12 = {2'b00, mem_data_in[10 : 7], mem_data_in[12 : 11], mem_data_in[5], mem_data_in[6], 2'b00};
            assign funct3 = mem_data_in [15 : 13];
            
            assign CL_offset12 = {5'd0, mem_data_in[5], mem_data_in[12 : 10], mem_data_in[6], 2'b00};
            
            assign rd_rs1 = mem_data_in[11 : 7];
            assign rs2 = mem_data_in [6 : 2];
            
            assign CI_imm12 = {{7{mem_data_in[12]}}, mem_data_in[6 : 2]};
            assign CI_imm20 = {{8{CI_imm12[11]}}, CI_imm12};
            
            assign CJ_imm20 = {{10{mem_data_in[12]}}, mem_data_in[8], mem_data_in[10 : 9], mem_data_in[6], mem_data_in[7], mem_data_in[2], mem_data_in[11], mem_data_in[5 : 3]};
            
            assign CI_imm12_ADDI16SP = {{3{mem_data_in[12]}}, mem_data_in[4 : 3], mem_data_in[5], mem_data_in[2], mem_data_in[6], 4'd0};
            
            assign CB_offset12 = {{5{mem_data_in[12]}}, mem_data_in[6 : 5], mem_data_in[2], mem_data_in[11 : 10], mem_data_in[4 : 3]};
            
            assign CS_imm12 = {4'd0, mem_data_in[8 : 7], mem_data_in[12 : 9], 2'b00};
            
            assign CI_LWSP_uimm12 = {4'd0, mem_data_in[3 : 2], mem_data_in[12], mem_data_in[6 : 4], 2'b00};
     
            //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            // address
            //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            
                always @(posedge clk, negedge reset_n) begin : mem_addr_proc
                    if (!reset_n) begin
                        mem_addr_ack_out <= 0;
                    end else begin
                        mem_addr_ack_out <= mem_addr_ack_in;
                    end
                end
         
            //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            // C extension
            //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                always @(posedge clk, negedge reset_n) begin : c_extension_proc
                    if (!reset_n) begin
                        enable_out <= 0;
                        instruction_out <= 0;
                        instruction_original <= 0;
                        
                    end else begin
                        enable_out <= mem_read_done;
                        
                        instruction_out [1 : 0] <= mem_data_in[1 : 0];
                        
                        instruction_original <= mem_data_in;
                        
                        if (mem_data_in[1 : 0] == 2'b11) begin // 32 bit instruction
                            instruction_out [`XLEN - 1 : 2] <= mem_data_in [`XLEN - 1 : 2];
                        end else begin
                            case ({mem_data_in[15 : 13], mem_data_in[1 : 0]}) // synthesis parallel_case
                                `C_ADDI4SPN : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CIW_imm12, 5'd2, `ALU_ADD_SUB, rd_apostrophe, `CMD_OP_IMM};
                                end
                                
                                `C_LW : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CL_offset12, rs1_apostrophe, 3'b010, rd_apostrophe,`CMD_LOAD};
                                end
                                
                                `C_SW : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CL_offset12[11 : 5], rs2_apostrophe, rs1_apostrophe, 3'b010, CL_offset12[4 : 0], `CMD_STORE};
                                end
                                
                                `C_NOP_ADDI : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CI_imm12, rd_rs1, 3'd0, rd_rs1, `CMD_OP_IMM};
                                end
                                
                                `C_JAL, `C_J : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CJ_imm20[19], CJ_imm20[9 : 0], CJ_imm20[10], CJ_imm20[18 : 11], 4'd0, ~mem_data_in[15], `CMD_JAL};
                                end
                                
                                `C_LI : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CI_imm12, 5'd0, `ALU_ADD_SUB, rd_rs1, `CMD_OP_IMM};
                                end
                                
                                `C_ADDI16SP_LUI : begin
                                    if (mem_data_in[11 : 7] == 5'b00010) begin // C.ADDI16SP
                                        instruction_out [`XLEN - 1 : 2] <= {CI_imm12_ADDI16SP, 5'd2, `ALU_ADD_SUB, 5'd2, `CMD_OP_IMM};
                                    end else begin // C.LUI
                                        instruction_out [`XLEN - 1 : 2] <= {CI_imm20, rd_rs1, `CMD_LUI};
                                    end
                                end
                                
                                `C_BNEZ, `C_BEQZ : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CB_offset12[11], CB_offset12[9 : 4], 5'd0, rs1_apostrophe, 2'b00, mem_data_in[13], CB_offset12[3 : 0], CB_offset12[10], `CMD_BRANCH};
                                end
                                
                                `C_SLLI : begin
                                    instruction_out [`XLEN - 1 : 2] <= {7'd0, CI_imm12[4 : 0], rd_rs1, `ALU_SLL, rd_rs1, `CMD_OP_IMM};
                                end
                                
                                `C_SWSP : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CS_imm12[11 : 5], rs2, 5'd2, 3'b010, CS_imm12[4 : 0], `CMD_STORE};
                                end
                                
                                `C_LWSP : begin
                                    instruction_out [`XLEN - 1 : 2] <= {CI_LWSP_uimm12, 5'd2, 3'b010, rd_rs1, `CMD_LOAD};
                                end
                                
                                `C_JR_JALR_MV_ADD : begin
                                    if (mem_data_in[12]) begin // C.ADD / C.JALR / C.EBREAK
                                        if (|rs2) begin // C.ADD
                                            instruction_out [`XLEN - 1 : 2] <= {7'd0, rs2, rd_rs1, `ALU_ADD_SUB, rd_rs1, `CMD_OP};
                                        end else if (|rd_rs1) begin // C.JALR
                                            instruction_out [`XLEN - 1 : 2] <= {12'd0, rd_rs1, 3'd0, 5'd1, `CMD_JALR};
                                        end else begin //C.EBREAK
                                            instruction_out [`XLEN - 1 : 2] <= {12'd1, 5'd0, 3'd0, 5'd0, `CMD_SYSTEM};
                                        end
                                    end else if (|rs2) begin // C.MV
                                        instruction_out [`XLEN - 1 : 2] <= {7'd0, rs2, 5'd0, `ALU_ADD_SUB, rd_rs1, `CMD_OP};
                                    end else begin // C.JR
                                        instruction_out [`XLEN - 1 : 2] <= {12'd0, rd_rs1, 3'd0, 5'd0, `CMD_JALR};
                                    end
                                end
                                
                                
                                default : begin //== `C_MISC_ALU 
                                    case (mem_data_in [11 : 10]) // synthesis parallel_case
                                        2'b11 : begin // C.SUB, C.XOR, C.OR, C.AND
                                            case (mem_data_in [6 : 5]) // synthesis parallel_case
                                                2'b11 : begin // C.AND
                                                    instruction_out [`XLEN - 1 : 2] <= {7'h0, rs2_apostrophe, rs1_rd_apostrophe, `ALU_AND, rs1_rd_apostrophe, `CMD_OP};
                                                end
                                                
                                                2'b00 : begin // C.SUB
                                                    instruction_out [`XLEN - 1 : 2] <= {7'h20, rs2_apostrophe, rs1_rd_apostrophe, `ALU_ADD_SUB, rs1_rd_apostrophe, `CMD_OP};
                                                end
                                                
                                                2'b10 : begin // C.OR
                                                    instruction_out [`XLEN - 1 : 2] <= {7'h0, rs2_apostrophe, rs1_rd_apostrophe, `ALU_OR, rs1_rd_apostrophe, `CMD_OP};
                                                end
                                                
                                                default : begin // C.XOR
                                                    instruction_out [`XLEN - 1 : 2] <= {7'h0, rs2_apostrophe, rs1_rd_apostrophe, `ALU_XOR, rs1_rd_apostrophe, `CMD_OP};
                                                end
                                                
                                            endcase
                                        end
                                        
                                        2'b10 : begin // C.ANDI
                                            instruction_out [`XLEN - 1 : 2] <= {CI_imm12, rs1_rd_apostrophe, `ALU_AND, rs1_rd_apostrophe, `CMD_OP_IMM};
                                        end
                                        
                                        2'b01 : begin // C.SRAI
                                            instruction_out [`XLEN - 1 : 2] <= {7'h20, CI_imm12 [4 : 0], rs1_rd_apostrophe, `ALU_SRL_SRA, rs1_rd_apostrophe, `CMD_OP_IMM};
                                        end
                                        
                                        default : begin // C.SRLI
                                            instruction_out [`XLEN - 1 : 2] <= {7'd0, CI_imm12 [4 : 0], rs1_rd_apostrophe, `ALU_SRL_SRA, rs1_rd_apostrophe, `CMD_OP_IMM};
                                        end
                                    
                                    endcase
                                    
                                end
                               
                            endcase
                            
                        end
                        
                        
                    end
                end

endmodule

`default_nettype wire

