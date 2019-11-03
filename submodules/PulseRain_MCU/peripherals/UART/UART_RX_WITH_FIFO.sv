
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

`include "config.vh"

//=============================================================================
// Remarks:
//   Serial port for RX
//=============================================================================


`default_nettype none

module UART_RX_WITH_FIFO #(parameter STABLE_TIME, BAUD_PERIOD_BITS, FIFO_SIZE = 4) (
    
    //=======================================================================
    // clock / reset
    //=======================================================================
        
        input   wire                                clk,
        input   wire                                reset_n,
        input   wire                                sync_reset,

    //=======================================================================
    // host interface
    //=======================================================================
        input   wire                                            fifo_read_req,
        output  logic                                           enable_out,
        output  logic unsigned [`UART_DEFAULT_DATA_LEN - 1 : 0]  data_out,
        
        input   wire unsigned [BAUD_PERIOD_BITS - 1 : 0]        baud_rate_period_m1,
        
    //=======================================================================
    // device interface
    //=======================================================================
        output  wire                                           fifo_full,
        output  wire                                           fifo_not_empty,
        input   wire                                           RXD
    
);

        
        wire                                                    ri;
        logic [1 : 0]                                           ri_sr;
        wire unsigned [`UART_DEFAULT_DATA_LEN - 1 : 0]           fifo_data_out;
        
        wire unsigned [`UART_DEFAULT_DATA_LEN - 1 : 0]           SBUF_out;
        
        UART_RX #(.STABLE_TIME (STABLE_TIME), .BAUD_PERIOD_BITS (BAUD_PERIOD_BITS)) rx_uart (.*,
                .sync_reset (sync_reset),
                .start_RX (1'b1),
                .baud_rate_period_m1 (baud_rate_period_m1),
                .SBUF_out (SBUF_out),
                .RI (ri),
                .RXD (RXD)
            );


        UART_FIFO #(.FIFO_SIZE (FIFO_SIZE), .WIDTH (`UART_DEFAULT_DATA_LEN)) fifo (.*,
            .fifo_write ((~ri_sr[1]) & ri_sr[0]),
            .fifo_data_in (SBUF_out),

            .fifo_read (fifo_read_req),
            .fifo_top_data_out (fifo_data_out),
            .fifo_not_empty (fifo_not_empty),
            .fifo_full (fifo_full),
            .fifo_count ()
        );        
       
        
        always_ff @(posedge clk, negedge reset_n) begin : shift_proc
            if (!reset_n) begin
                ri_sr            <= 0;
                enable_out       <= 0;
                data_out         <= 0;
            end else begin
                ri_sr            <= {ri_sr [$high(ri_sr) - 1 : 0], ri};
                enable_out       <= fifo_read_req;
                if (fifo_read_req) begin
                    data_out         <= fifo_data_out;
                end
            end
        end : shift_proc
       
        
endmodule : UART_RX_WITH_FIFO

`default_nettype wire
