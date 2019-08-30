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
`include "debug_coprocessor.vh"
`include "config.vh"

`default_nettype none

module Rattlesnake #(parameter sim = 0) (

    //=====================================================================
    // clock and reset
    //=====================================================================
        input   wire                                            clk,                          
        input   wire                                            reset_n,                      
  

    //=====================================================================
    // UART
    //=====================================================================
        output  reg                                             TXD, 
        input   wire                                            RXD,
    
    //=====================================================================
    // status
    //=====================================================================
        output wire                                             processor_active,
        output wire                                             processor_paused        
);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire                                                    debug_uart_tx_sel_ocd1_cpu0;
        wire                                                    cpu_reset;
        wire [`DEBUG_PRAM_ADDR_WIDTH - 3 : 0]                   pram_read_addr;
        wire [`DEBUG_PRAM_ADDR_WIDTH - 3 : 0]                   pram_write_addr;
        
        wire                                                    ocd_read_enable;
        wire                                                    ocd_write_enable;
        
        wire  [`MEM_ADDR_BITS - 1 : 0]                          ocd_rw_addr;
        wire  [`XLEN - 1 : 0]                                   ocd_write_word;
        
        wire                                                    ocd_mem_enable_out;
        wire  [`XLEN - 1 : 0]                                   ocd_mem_word_out;      
        
        wire                                                      cpu_start;
        wire [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN - 1 : 0]  cpu_start_addr;
       
        wire                                                      uart_tx_cpu;
        wire                                                      uart_tx_ocd;
       
        wire                                                                preg_write_enable;
        wire [`DEBUG_PRAM_ADDR_WIDTH - 3 : 0]                               preg_write_addr;
        wire [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN - 1 : 0]            preg_write_data;
        
         
        logic unsigned [1 : 0]                                      init_start = 0;
        
        logic                                                       actual_cpu_start;
        logic unsigned [`XLEN - 1 : 0]                              actual_start_addr;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // MCU
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                init_start <= 0;
                actual_cpu_start <= 0;
                actual_start_addr <= 0;
                
            end else begin
                init_start <= {init_start [$high(init_start) - 1 : 0], 1'b1};
                actual_cpu_start <= cpu_start; // | ((~init_start [$high(init_start)]) & init_start [$high(init_start) - 1]);
         
                if (cpu_start) begin
                    actual_start_addr <= cpu_start_addr;
                end else begin
                    actual_start_addr <= `DEFAULT_START_ADDR;
                end
                
            
            end
        end
     
        PulseRain_Rattlesnake_MCU #(.sim(sim)) PulseRain_Rattlesnake_MCU_i  (
            .clk (clk),
            .reset_n ((~cpu_reset) & reset_n),
            .sync_reset (1'b0),

            .ocd_read_enable (ocd_read_enable),
            .ocd_write_enable (ocd_write_enable),
            
            .ocd_rw_addr (ocd_rw_addr),
            .ocd_write_word (ocd_write_word),
            
            .ocd_mem_enable_out (ocd_mem_enable_out),
            .ocd_mem_word_out (ocd_mem_word_out),        
        
            .ocd_reg_read_addr (5'd2),
            .ocd_reg_we (cpu_start),
            .ocd_reg_write_addr (5'd2),
            .ocd_reg_write_data (`DEFAULT_STACK_ADDR),
            
            .peripheral_reg_we          (preg_write_enable),
            .peripheral_reg_write_addr  (preg_write_addr),
            .peripheral_reg_write_data  (preg_write_data),
        
            .RXD (RXD),
            .TXD (uart_tx_cpu),
   
            .start (actual_cpu_start),
            .start_address (actual_start_addr),
        
            .processor_paused (processor_paused),
            
            .peek_pc (),
            .peek_ir (),
            .peek_mem_write_en   (),
            .peek_mem_write_data (),
            .peek_mem_addr       ());
     
        assign processor_active = ~processor_paused;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // OCD
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
    
        debug_coprocessor_wrapper #(.BAUD_PERIOD (`UART_BAUD_PERIOD)) ocd_i (
            .clk (clk),
            .reset_n (reset_n),
            
            .RXD (RXD),
            .TXD (uart_tx_ocd),
                
            .pram_read_enable_in (ocd_mem_enable_out),
            .pram_read_data_in (ocd_mem_word_out),
            
            .pram_read_enable_out (ocd_read_enable),
            .pram_read_addr_out (pram_read_addr),
            
            .pram_write_enable_out (ocd_write_enable),
            .pram_write_addr_out (pram_write_addr),
            .pram_write_data_out (ocd_write_word),
            
            .preg_write_enable_out (preg_write_enable),
            .preg_write_addr_out   (preg_write_addr),
            .preg_write_data_out   (preg_write_data),

            .cpu_reset (cpu_reset),
            
            .cpu_start (cpu_start),
            .cpu_start_addr (cpu_start_addr),        
            
            .debug_uart_tx_sel_ocd1_cpu0 (debug_uart_tx_sel_ocd1_cpu0));
        
        assign ocd_rw_addr = ocd_read_enable ? {pram_read_addr [$high(ocd_rw_addr) - 1 : 0], 1'b0} : {pram_write_addr [$high(ocd_rw_addr) - 1 : 0], 1'b0};
        
        always @(posedge clk, negedge reset_n) begin : uart_proc
            if (!reset_n) begin
                TXD <= 0;
            end else if (!debug_uart_tx_sel_ocd1_cpu0) begin
                TXD <= uart_tx_cpu;
            end else begin
                TXD <= uart_tx_ocd;
            end
        end
        
endmodule

`default_nettype wire
