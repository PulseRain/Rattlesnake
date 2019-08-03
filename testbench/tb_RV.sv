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

`timescale 1ns/1ps 

`include "file_compare.svh"
`include "common.vh"


parameter OSC_PERIOD = 10ns;  // 100MHz oscillator

module tb_RV #(parameter string TV = "") ();
    
    //========================================================================
    // signals
    //========================================================================
        logic                                   osc = 0;
        wire                                    all_done;
    
        wire  unsigned [11 : 0] #(2)            SDRAM_ADDR;
        wire  unsigned [1 : 0]  #(2)            SDRAM_BA;
        wire                    #(2)            SDRAM_CAS_N;
        wire                    #(2)            SDRAM_CKE;
        wire                    #(2)            SDRAM_CS_N;     
        wire  [15 : 0]          #(2)            SDRAM_DQ;
        wire  unsigned [1 : 0]  #(2)            SDRAM_DQM;
        wire                    #(2)            SDRAM_RAS_N;
        wire                    #(2)            SDRAM_WE_N;
        wire                    #(1)            SDRAM_CLK;
        
        wire                                    cmp_enable;
        integer                                 exe_to_cmp [0 : 33];        
        
        logic                                   start = 0;
        logic                                   stack_init;
        
        
    //========================================================================
    // UUT
    //========================================================================

            PulseRain_Rattlesnake_MCU #(.sim(1)) uut (
                .clk (osc),
                .reset_n (1'b1),
                .sync_reset (1'b0),

                .ocd_read_enable  (1'b0),
                .ocd_write_enable (1'b0),
                
                .ocd_rw_addr (0),
                .ocd_write_word (0),
        
                .ocd_mem_enable_out (),
                .ocd_mem_word_out (),

                .ocd_reg_read_addr (5'd2),
                .ocd_reg_we (stack_init),
                .ocd_reg_write_addr (5'd2),
                .ocd_reg_write_data (`DEFAULT_STACK_ADDR),

                .RXD (1'b1),
                .TXD (),
         
                .start (start),
                .start_address (32'h80000000),
                
                .processor_paused (),

                .peek_pc (),
                .peek_ir (),
                
                .peek_mem_write_en (),
                .peek_mem_write_data (),
                .peek_mem_addr ()
            );

    //========================================================================
    // Test Vector compare
    //========================================================================
    
        assign cmp_enable = (TV == "") ? 1'b0 : 1'b1;
    
         genvar i;
         generate
            for (i = 1; i < 32; i = i + 1) begin
                assign exe_to_cmp[i + 2] = 'X;
            end
        
        endgenerate
        
        assign exe_to_cmp[0] = uut.PulseRain_Rattlesnake_core_i.Rattlesnake_execution_unit_i.PC_in;
        assign exe_to_cmp[1] = uut.PulseRain_Rattlesnake_core_i.Rattlesnake_execution_unit_i.IR_in;

        
        generate
            for (i = 0; i < ((TV == "") ? 0 : 1); i = i + 1) begin
                
                single_file_compare #( .NUM_OF_COLUMNS (34), 
                                        .NUM_OF_COLUMNS_TO_DISPLAY(2),
                                        .FILE_NAME({TV}), 
                                        .NUM_OF_LINES(0), 
                                        .BASE(16), 
                                        .LINES_TO_SKIP(0), 
                                        .VERBOSE(1),
                                        .PAUSE_ON_MISMATCH(1), 
                                        .WILDCARD_COMPARE(1),
                                        .CARRIAGE_RETURN(1) ) data_exe_cmp (
                         
                         .clk (uut.clk),
                         .reset_n (1'b1),
                    
                        //====== data to compare
                        .data_to_cmp(exe_to_cmp),
                        .enable_in (uut.PulseRain_Rattlesnake_core_i.Rattlesnake_execution_unit_i.exe_enable & cmp_enable & start),
                        
                        .pass1_fail0 (), 
                        .all_done(all_done)
                        ); 
            end
        endgenerate
    
    //========================================================================
    // clock
    //========================================================================
    
        initial begin
            forever begin 
                #(OSC_PERIOD/2);
                
                if ((all_done) && (TV != "")) begin
                    break;
                end else begin
                    osc = (~osc);
                end
            end
        end
        
        initial begin
        
            start = 0;
            stack_init = 0;
            #20ns;
            stack_init = 1;
            #20ns;
            stack_init = 0;
            
            start = 0;
            #20ns;
            start = 1'b1;
            
        
        end
    
endmodule 
    