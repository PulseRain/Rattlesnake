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
//     UART for OCD
//=============================================================================


`include "debug_coprocessor.vh"

`default_nettype none

module debug_UART #(parameter BAUD_PERIOD = 868) (
    input   wire                                clk,
    input   wire                                reset_n,
    
    input   wire                                sync_reset,
    input   wire                                UART_enable,
    
    input   wire                                TX_enable_in,
    
    input   wire                                RXD,
    input   wire  [`DEBUG_DATA_WIDTH - 1 : 0]   SBUF_in,
    input   wire                                REN,
    output  wire                                TXD,
    output  wire  [`DEBUG_DATA_WIDTH - 1 : 0]   SBUF_out,
    output  reg                                 TX_done_pulse,
    output  wire                                TI,
    output  wire                                RI
);
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg  [$clog2(BAUD_PERIOD + 1) - 1 : 0]              baud_counter;
        wire                                                baud_pulse;
        reg                                                 ctl_uart_rx_enable;
        reg                                                 ctl_uart_tx_start;
        reg                                                 ctl_tx_done;
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // baud counter
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : baud_counter_proc
            if (!reset_n) begin
                baud_counter <= 0;
            end else if (sync_reset) begin
                baud_counter <= 0;
            end else if (UART_enable) begin
                if (baud_counter == (BAUD_PERIOD - 1)) begin
                    baud_counter <= 0;
                end else begin
                    baud_counter <= baud_counter + ($size(baud_counter))'(1);
                end
            end
        end 
    
        assign baud_pulse = (baud_counter == (BAUD_PERIOD - 1)) ? 1'b1 : 1'b0;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // UART 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            
        Serial_RS232 #(.STABLE_TIME (50), 
                      .MAX_BAUD_PERIOD (10000)) 
                UART_i (
                    .clk (clk),
                    .reset_n (reset_n), 
                    .start_TX (ctl_uart_tx_start),
                    .start_RX (ctl_uart_rx_enable),
                    .class_8051_unit_pulse (1'b0),
                    .timer_trigger (baud_pulse),
                    .RXD (RXD),
                    .SBUF_in (SBUF_in),
                    .SM (3'b011),
                    .REN (REN & ctl_uart_rx_enable),
                    .TXD (TXD),
                    .TI (TI),
                    .RI (RI),
                    .SBUF_out (SBUF_out));
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // TX Done
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
        always @(posedge clk, negedge reset_n) begin : TX_done_pulse_proc
            if (!reset_n) begin
                TX_done_pulse <= 0;
            end else begin
                TX_done_pulse <= ctl_tx_done;
            end
        end
        
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                
        localparam S_RX = 0, S_TX = 1; 
                
        reg [1:0] current_state = 0, next_state;
            
        // Declare states
        always @(posedge clk, negedge reset_n) begin : state_machine_reg
            if (!reset_n) begin
                current_state <= 0;
            end else begin
                current_state <= next_state;
            end
        end 
        
        // FSM main body
        always @(*) begin : state_machine_comb

            next_state = 0;
            
            ctl_uart_rx_enable = 0;
            ctl_uart_tx_start = 0;
    
            ctl_tx_done = 0;
            
            case (1'b1) // synthesis parallel_case 
                
                current_state[S_RX]: begin
                    
                    if (TX_enable_in) begin
                        ctl_uart_tx_start = 1'b1;
                        next_state [S_TX] = 1;
                    end else begin
                        ctl_uart_rx_enable = 1'b1;
                        next_state [S_RX] = 1;
                    end
                end
                
                current_state [S_TX] : begin
                    if (TI) begin
                        ctl_tx_done = 1'b1;
                        next_state [S_RX] = 1;
                    end else begin
                        next_state [S_TX] = 1;
                    end
                end
                                
                default: begin
                    next_state[S_RX] = 1'b1;
                end
                
            endcase
            
        end 
endmodule 

`default_nettype wire
