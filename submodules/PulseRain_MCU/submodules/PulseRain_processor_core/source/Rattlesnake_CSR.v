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

module Rattlesnake_CSR (

    //=======================================================================
    // clock / reset
    //=======================================================================
        input   wire                                            clk,
        input   wire                                            reset_n,
        input   wire                                            sync_reset,

    //=======================================================================
    //  from pipeline
    //=======================================================================
        input   wire                                            exe_enable,
    //=======================================================================
    //  register read / write
    //=======================================================================
        input   wire                                            read_enable,
        input   wire  [`CSR_ADDR_BITS - 1 : 0]                  read_addr,
        
        output  wire                                            read_en_out,
        output  wire  [`XLEN - 1 : 0]                           read_data_out,
           
        input   wire                                            write_enable,
        input   wire  [`CSR_ADDR_BITS - 1 : 0]                  write_addr,
        input   wire  [`XLEN - 1 : 0]                           write_data_in,

    //=======================================================================
    //  interrupt
    //=======================================================================
        input   wire                                            timer_triggered,
        input   wire                                            ext_int_triggered,
        input   wire                                            csr_mret_active,
        
    //=======================================================================
    //  exception
    //=======================================================================
        input   wire                                            activate_exception,
        input   wire                                            is_interrupt,
        input   wire  [`EXCEPTION_CODE_BITS - 1 : 0]            exception_code,
        input   wire  [`PC_BITWIDTH - 1 : 0]                    exception_PC,
        input   wire  [`PC_BITWIDTH - 1 : 0]                    exception_addr,
        
         
        output  reg                                             exception_storage_page_fault,
        output  wire  [`XLEN - 1 : 0]                           mtvec_out,
        output  wire  [`XLEN - 1 : 0]                           mepc_out,
        output  wire                                            mtie_out,
        output  wire                                            meie_out,
        output  wire                                            mie_out,
        output  wire                                            mtip_out,
        output  wire                                            meip_out
        
);

   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Signals
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg [`XLEN - 1 : 0]                             mtvec = 0;
        reg [`XLEN - 1 : 0]                             mscratch = 0;
        reg [`XLEN - 1 : 0]                             mepc = 0;
        reg [`XLEN - 1 : 0]                             mtval = 0;
        reg [`XLEN - 1 : 0]                             mcause = 0;
        
        reg                                             read_en_out_i;
        reg [`XLEN - 1 : 0]                             read_data_out_i;
        
        reg [`XLEN * 2 - 1 : 0]                         mcycle_i;
        reg [`XLEN - 1 : 0]                             mcycleh;
        
        reg [`XLEN * 2 - 1 : 0]                         minstret_i;
        reg [`XLEN - 1 : 0]                             minstreth;
        
        reg                                             mie_mtie;
        reg                                             mie_meie;
        reg                                             mstatus_mpie;
        reg                                             mstatus_mie;
        reg                                             timer_triggered_d1;
        reg                                             ext_int_triggered_d1;
        reg                                             mtip;
        reg                                             meip;
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // datapath
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        assign read_en_out = read_en_out_i;
        assign read_data_out = read_data_out_i;
        
        assign mtvec_out = mtvec;
        assign mepc_out  = mepc;
        
        assign meie_out = mie_meie;
        assign mtie_out = mie_mtie;
        assign mie_out = mstatus_mie;
        assign mtip_out = mtip;
        assign meip_out = meip;
        
        always @(posedge clk, negedge reset_n) begin : output_proc
            if (!reset_n) begin
                read_en_out_i   <= 0;
                read_data_out_i <= 0;
                
                mtvec           <= 0;
                mscratch        <= 0;
                mepc            <= 0;
                mtval           <= 0;
                
                           
                mcause          <= 0;
                
                exception_storage_page_fault <= 0;
                
                if (`SMALL_CSR_SET == 0) begin
                    mcycle_i        <= 0;
                    mcycleh         <= 0;
                    
                    minstret_i      <= 0;
                    minstreth       <= 0;
                end
                
                mie_mtie        <= 0;
                mie_meie        <= 0;
        
                mstatus_mpie    <= 0;
                mstatus_mie     <= 0;
                
                timer_triggered_d1   <= 0;
                ext_int_triggered_d1 <= 0;
                
                mtip <= 0;
                meip <= 0;
        
            end else begin
            
                timer_triggered_d1   <= timer_triggered;
                ext_int_triggered_d1 <= ext_int_triggered;
                
                read_en_out_i   <= read_enable;
                
                exception_storage_page_fault <= 0;
                
                if (`SMALL_CSR_SET == 0) begin
                    mcycle_i <= mcycle_i + 1;
                    
                    if (exe_enable) begin
                        minstret_i <= minstret_i + 1;
                    end
                end
                
                if ((~timer_triggered_d1) & timer_triggered) begin
                    mtip <= 1'b1;
                end else if (!timer_triggered) begin
                    mtip <= 0;
                end
                
                if ((~ext_int_triggered_d1) & ext_int_triggered) begin
                    meip <= 1'b1;
                end else if (!ext_int_triggered) begin
                    meip <= 0;
                end
                
                
                if (activate_exception) begin
                    mcause <= {is_interrupt, 27'd0, exception_code};
                    mepc   <= exception_PC;
                    mtval  <= exception_addr;
                    mstatus_mpie <= mstatus_mie;
                end else begin
                    
                    //if (csr_mret_active) begin
                    //    mstatus_mie <= mstatus_mpie;
                    //end
                    
                    if (read_enable) begin
                        case (read_addr) // synthesis parallel_case
                            `CSR_MVENDORID  : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    read_data_out_i <= `PULSERAIN_JEDEC_VENDOR_ID;
                                end
                            end
                            
                            `CSR_MARCHID   : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    read_data_out_i <= `PULSERAIN_RV2T_ARCH_ID;
                                end
                            end
                            
                            `CSR_MIMPID    : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    read_data_out_i <= `PULSERAIN_RV2T_IMPLEMENT_ID;
                                end
                            end
                            
                            `CSR_HARTID    : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    read_data_out_i <= `PULSERAIN_RV2T_HART_ID;
                                end
                            end
                            
                            `CSR_MISA      : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    read_data_out_i <= `PULSERAIN_RV2T_ISA;
                                end
                            end
                            
                            `CSR_MTVEC     : begin
                                read_data_out_i <= mtvec;
                            end 

                            `CSR_MSCRATCH  : begin
                                read_data_out_i <= mscratch;
                            end
                            
                            `CSR_MEPC      : begin
                                read_data_out_i <= mepc;
                            end
                            
                            `CSR_MTVAL     : begin
                                read_data_out_i <= mtval;
                            end
                            
                            `CSR_MSTATUS   : begin
                                read_data_out_i <= {19'd0, 2'b11, 2'b00, 1'b0, mstatus_mpie, 1'b0, 1'b0, 1'b0, mstatus_mie, 3'd0};
                            end
                            
                            `CSR_MCAUSE    : begin
                                read_data_out_i <= mcause;
                            end
                            
                            `CSR_MCYCLE    : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    mcycleh             <= mcycle_i [`XLEN * 2 - 1 : `XLEN];
                                    read_data_out_i     <= mcycle_i [`XLEN - 1 : 0];
                                end
                                
                            end
                            
                            `CSR_MCYCLEH    : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    read_data_out_i <= mcycleh;
                                end
                            end
                            
                            `CSR_MINSTRET   : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    minstreth           <= minstret_i [`XLEN * 2 - 1 : `XLEN];
                                    read_data_out_i     <= minstret_i [`XLEN - 1 : 0];
                                end
                            end
                            
                            `CSR_MINSTRETH  : begin
                                if (`SMALL_CSR_SET == 0) begin
                                    read_data_out_i <= minstreth;
                                end
                            end
                            
                            `CSR_MIP : begin
                                read_data_out_i <= {20'd0, meip, 3'd0, mtip, 3'd0, 4'd0};
                            end
                            
                            `CSR_MIE :begin
                                read_data_out_i <= {20'd0, mie_meie, 3'b000, mie_mtie, 7'd0};
                            end
                            
                            default :  begin
                                exception_storage_page_fault <= 1'b1;
                            end
                            
                        endcase
                        
                    end else if (write_enable) begin
                        case (write_addr) // synthesis parallel_case
                            
                            `CSR_MSTATUS   : begin
                                mstatus_mie <= write_data_in[3];
                                mstatus_mpie <= write_data_in[7];
                            end
                            
                            `CSR_MTVEC     : begin
                                mtvec <= write_data_in;
                            end 

                            `CSR_MSCRATCH  : begin
                                mscratch <= write_data_in;
                            end

                            `CSR_MEPC      : begin
                                mepc <= write_data_in;
                            end

                            `CSR_MTVAL     : begin
                                mtval <= write_data_in;
                            end
                            
                            `CSR_MCAUSE    : begin
                                mcause <= write_data_in;
                            end
                            
                            `CSR_MISA      : begin
                                // do nothing
                            end
                         
                            `CSR_MIE       : begin
                                mie_mtie    <= write_data_in[7];
                                mie_meie    <= write_data_in[11];
                            end
                            
                            `CSR_MIP       : begin
                                mtip        <= write_data_in[7];
                                meip        <= write_data_in[11];
                            end
                            
                            default :  begin
                                exception_storage_page_fault <= 1'b1;
                            end

                        endcase

                    end 
                end 
            end
        end

endmodule

`default_nettype wire
