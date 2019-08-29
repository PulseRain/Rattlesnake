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


module mem_controller #(parameter sim = 0) (

    //=======================================================================
    // clock / reset
    //=======================================================================

        input   wire                                                    clk,
        input   wire                                                    reset_n,
        input   wire                                                    sync_reset,

    //=======================================================================
    // memory interface
    //=======================================================================
        input  wire  [`MEM_ADDR_BITS - 1 : 0]                           mem_addr,
        input  wire                                                     mem_read_en,
        input  wire  [`XLEN_BYTES - 1 : 0]                              mem_write_en,
        input  wire  [`EXT_BITS + `XLEN - 1 : 0]                        mem_write_data,
        
        output wire  [`EXT_BITS + `XLEN - 1 : 0]                        mem_read_data,
        output wire                                                     mem_write_ack,
        output wire                                                     mem_read_ack,
        
        
        output wire  [`MEM_ADDR_BITS - 1 : 0]                           mem_addr_ack
        
);
    //=======================================================================
    // signal
    //=======================================================================
        wire                                              mem_sram0_dram1; 
        wire [`EXT_BITS + 15 : 0]                         dout_high;
        wire [`EXT_BITS + 15 : 0]                         dout_low;
        
        reg [`EXT_BITS + 15 : 0]                          dout_high_d1;
        reg [`EXT_BITS + 15 : 0]                          dout_low_d1;
        
        reg [`EXT_BITS + 15 : 0]                          dout_high_d2;
        reg [`EXT_BITS + 15 : 0]                          dout_low_d2;
        
        reg                                               mem_sram0_dram1_d1;
        reg                                               mem_read_en_d1;
        
        reg                                               sram_read_ack_pre;
        reg                                               sram_read_ack_pre_pre;
        reg                                               sram_read_ack;
        
        reg                                               sram_write_ack_pre;
        
        reg                                               sram_write_ack;
                
        
        reg   [`MEM_ADDR_BITS - 1 : 0]                    mem_read_addr_reg;
        
        wire  [`SRAM_ADDR_BITS - 1 : 0]                   sram_addr_low;
                
    //=======================================================================
    // SRAM
    //=======================================================================
        /* verilator lint_off UNSIGNED */
        assign mem_sram0_dram1 = 0; 
           
        assign sram_addr_low = mem_addr[`SRAM_ADDR_BITS : 1] + {(`SRAM_ADDR_BITS - 1)'(0), mem_addr[0]};
        
        generate 
            
            if ((`SRAM_SIZE_IN_BYTES != 0) && (sim == 0)) begin 
                single_port_ram #(.ADDR_WIDTH (`SRAM_ADDR_BITS), .DATA_WIDTH (16), .EXT_WIDTH(`EXT_BITS) ) ram_high_i (
                    .addr (mem_addr [`SRAM_ADDR_BITS : 1]),
                    .din ({mem_write_data[`EXT_BITS + `XLEN - 1], mem_write_data [31 : 16]}),
                    .write_en (mem_write_en[3 : 2] & {~mem_sram0_dram1, ~mem_sram0_dram1} ),
                    .clk (clk),
                    .dout (dout_high));

                single_port_ram #(.ADDR_WIDTH (`SRAM_ADDR_BITS), .DATA_WIDTH (16), .EXT_WIDTH(`EXT_BITS) ) ram_low_i (
                    .addr (sram_addr_low),
                    .din ({mem_write_data[`EXT_BITS + `XLEN - 1], mem_write_data [15 : 0]}),
                    .write_en (mem_write_en[1 : 0] & {~mem_sram0_dram1, ~mem_sram0_dram1} ),
                    .clk (clk),
                    .dout (dout_low));
            end

            if (sim != 0) begin
                single_port_ram_sim_high #(.ADDR_WIDTH (`SRAM_ADDR_BITS), .DATA_WIDTH (16) ) ram_high_i (
                    .addr (mem_addr[`SRAM_ADDR_BITS  : 1]),
                    .din ({mem_write_data[32], mem_write_data [31 : 16]}),
                    .write_en (mem_write_en[3 : 2]),
                    .clk (clk),
                    .dout (dout_high));
                  
                single_port_ram_sim_low #(.ADDR_WIDTH (`SRAM_ADDR_BITS), .DATA_WIDTH (16) ) ram_low_i (
                    .addr (sram_addr_low),
                    .din ({mem_write_data[32], mem_write_data [15 : 0]}),
                    .write_en (mem_write_en[1 : 0]),
                    .clk (clk),
                    .dout (dout_low));
            end
        endgenerate




     //  assign mem_read_data = {dout_high, dout_low};
        assign mem_read_data = {dout_high_d1, dout_low_d1 [15 : 0]};
        // assign mem_read_data = {dout_high_d2, dout_low_d2};

       // assign sram_read_ack_pre = mem_read_en_d1 & (~mem_sram0_dram1_d1);
        
        always @(posedge clk, negedge reset_n) begin : ack_proc
            if (!reset_n) begin
                sram_read_ack <= 0;
                sram_read_ack_pre <= 0;
                sram_read_ack_pre_pre <= 0;
                dout_high_d1 <= 0;
                dout_low_d1  <= 0;
                dout_high_d2 <= 0;
                dout_low_d2  <= 0;
                
                sram_write_ack <= 0;
                sram_write_ack_pre <= 0;
                
                mem_sram0_dram1_d1 <= 0;
                mem_read_en_d1 <= 0;
                
                mem_read_addr_reg <= 0;
                
            end else begin
               
                mem_sram0_dram1_d1 <= mem_sram0_dram1;
                mem_read_en_d1 <= mem_read_en;
                
               // sram_read_ack_pre <= mem_read_en & (~mem_sram0_dram1);
         //       sram_read_ack <= sram_read_ack_pre;
         
                sram_read_ack_pre_pre <= mem_read_en & (~mem_sram0_dram1);
                sram_read_ack_pre <= sram_read_ack_pre_pre;
                sram_read_ack <= sram_read_ack_pre_pre;
                
             //   sram_read_ack <= mem_read_en & (~mem_sram0_dram1);
                
                if (mem_read_addr_reg[0] == 1'b0) begin
                    dout_high_d1 <= dout_high;
                    dout_low_d1  <= dout_low;
                end else begin
                    dout_high_d1 <= dout_low;
                    dout_low_d1  <= dout_high;
                end
                
                dout_high_d2 <= dout_high_d1;
                dout_low_d2  <= dout_low_d1;
                
                sram_write_ack <= (|mem_write_en) & (~mem_sram0_dram1);
               
             //  sram_write_ack_pre <= (|mem_write_en) & (~mem_sram0_dram1);
             //  sram_write_ack <= sram_write_ack_pre;
             
                if (mem_read_en) begin
                    mem_read_addr_reg <= mem_addr;
                end
                
            end
        end : ack_proc
        
        assign mem_addr_ack = mem_read_addr_reg;
        
       // assign sram_write_ack = (|mem_write_en) & (~mem_sram0_dram1);

    
        assign mem_write_ack = sram_write_ack;
        assign mem_read_ack  = sram_read_ack;

        
      /*  
         mon mon_i (
            .acq_clk (clk), 
            .acq_data_in ({2'b00, mem_read_addr_reg[0], mem_read_en}),    //     tap.acq_data_in 
            .acq_trigger_in ({mem_read_addr_reg[0], mem_read_en})  //        .acq_trigger_in 
        );
*/

endmodule

`default_nettype wire
