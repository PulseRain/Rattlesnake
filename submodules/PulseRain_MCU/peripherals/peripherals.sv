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
//      peripherals for Reindeer_Step
//=============================================================================


`include "common.vh"
`include "config.vh"


`default_nettype none
module peripherals (
    //=======================================================================
    // clock / reset
    //=======================================================================
        
        input wire                                          clk,                             // clock input
        input wire                                          reset_n,                         // reset, active low
        input wire                                          sync_reset,
    //=======================================================================
    // Interrupt
    //=======================================================================
                
        input wire  unsigned [`NUM_OF_INTx - 1 : 0]          INTx, // external interrupt 
        
    
    //=======================================================================
    // Wishbone Interface (FASM synchronous RAM dual port model)
    //=======================================================================
        input  wire                                         WB_RD_STB_I,
        input  wire  unsigned [`MM_REG_ADDR_BITS - 1 : 0]   WB_RD_ADR_I,
        output logic unsigned [`XLEN - 1 : 0]               WB_RD_DAT_O,
        output logic                                        WB_RD_ACK_O,
                
        input  wire                                         WB_WR_STB_I,
        input  wire                                         WB_WR_WE_I,
        input  wire unsigned [`XLEN_BYTES - 1 : 0]          WB_WR_SEL_I,
        input  wire unsigned [`MM_REG_ADDR_BITS - 1 : 0]    WB_WR_ADR_I,
        input  wire unsigned [`XLEN - 1 : 0]                WB_WR_DAT_I,
        output logic                                        WB_WR_ACK_O,
        
    //=======================================================================
    // Interrupt
    //=======================================================================
        output  logic                                       int_gen,
    
    //=======================================================================
    // UART
    //=======================================================================
        input wire                                          RXD,
        output wire                                         TXD
        
      
);

    //=======================================================================
    // signals
    //=======================================================================
       
        //-------------------------------------------------------------------
        //  UART TX
        //-------------------------------------------------------------------
            wire                                        start_TX;
            wire [7 : 0]                                tx_data;
            wire                                        tx_active;
        
        //-------------------------------------------------------------------
        //  UART RX
        //-------------------------------------------------------------------
            wire                                        uart_rx_fifo_read_req;
            wire                                        uart_rx_enable_out;
            wire [`UART_DEFAULT_DATA_LEN - 1 : 0]       uart_rx_data_out;
            wire                                        uart_rx_fifo_full;
            wire                                        uart_rx_fifo_not_empty;
            wire                                        uart_rx_sync_reset;
        
        //-------------------------------------------------------------------
        //  External interrupt
        //-------------------------------------------------------------------
            logic unsigned [`NUM_OF_INTx - 1 : 0]       INTx_meta;
            logic unsigned [`NUM_OF_INTx - 1 : 0]       INTx_stable;
            
            wire                                        ext_int_active;
            
            logic unsigned [`XLEN - 1 : 0]              int_enable;
            
      
            
    //=======================================================================
    // write ack
    //=======================================================================
        
        always_ff @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                WB_WR_ACK_O <= 0;
                WB_RD_ACK_O <= 0;
            end else begin
                WB_WR_ACK_O <= WB_WR_WE_I;
                WB_RD_ACK_O <= WB_RD_STB_I;
            end
        end


    //=======================================================================
    // output mux
    //=======================================================================
        always_ff @(posedge clk, negedge reset_n) begin : output_data_proc
            if (!reset_n) begin
                WB_RD_DAT_O <= 0;
                               
            end else begin
                case (WB_RD_ADR_I) 
                    `UART_TX_ADDR : begin
                        WB_RD_DAT_O <= {tx_active, 31'd0};
                    end
                    
                    `INT_SOURCE_ADDR : begin
                        WB_RD_DAT_O <= {INTx_stable, (32 - `NUM_OF_TOTAL_INT )'(0),  uart_rx_fifo_not_empty, 1'b0};
                    end
                    
                    `INT_ENABLE_ADDR : 
                        WB_RD_DAT_O <= int_enable;
                    
                 
                    default : begin
                        WB_RD_DAT_O <= 0;
                    end
                endcase
            end
        end : output_data_proc

    //=======================================================================
    // UART TX
    //=======================================================================

        /* verilator lint_off WIDTH */
        
        UART_TX #(.STABLE_TIME(`UART_STABLE_COUNT), .BAUD_PERIOD_BITS(`UART_BAUD_PERIOD_BITS)) UART_TX_i (
            .clk        (clk),
            .reset_n    (reset_n),
            .sync_reset (sync_reset),
            
            .start_TX (start_TX),
            .baud_rate_period_m1 ((`UART_BAUD_PERIOD_BITS)'(`UART_BAUD_PERIOD - 1)),
            .SBUF_in (tx_data),
            .tx_active (tx_active),
            .TXD (TXD));

        assign start_TX = ((WB_WR_ADR_I == `UART_TX_ADDR) && WB_WR_WE_I) ? 1'b1 : 1'b0;
        assign tx_data = WB_WR_DAT_I [7 : 0];

 
    //=======================================================================
    // Interrupt
    //=======================================================================
        
        assign ext_int_active = |(INTx_stable & int_enable[`INT_EXT_INDEX_LAST : `INT_EXT_INDEX_1ST]);
        
        always_ff @(posedge clk, negedge reset_n) begin : int_gen_proc
            if (!reset_n) begin
                int_gen <= 0;
                INTx_meta <= 0;
                INTx_stable <= 0;
                
                int_enable <= 0;
                
            end else begin
                INTx_meta <= INTx;
                INTx_stable <= INTx_meta;
                int_gen <= ext_int_active | (uart_rx_fifo_not_empty & int_enable[`INT_UART_RX_INDEX]);
                
                if ((WB_WR_ADR_I == `INT_ENABLE_ADDR) && WB_WR_WE_I) begin
                    int_enable <= WB_WR_DAT_I;
                end
                
            end 
        end
        
endmodule : peripherals




`default_nettype wire
