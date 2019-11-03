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
//   Serial port for TX
//=============================================================================


`default_nettype none

module UART_RX #(parameter STABLE_TIME, BAUD_PERIOD_BITS) (
    
    //=======================================================================
    // clock / reset
    //=======================================================================
        
        input   wire                                clk,
        input   wire                                reset_n,
        input   wire                                sync_reset,

    //=======================================================================
    // host interface
    //=======================================================================
    
        input   wire                                           start_RX,
        input   wire unsigned [BAUD_PERIOD_BITS - 1 : 0]       baud_rate_period_m1,
        output  logic unsigned [`UART_DEFAULT_DATA_LEN - 1 : 0] SBUF_out,
        output  logic                                          RI, // RX interrupt

    //=======================================================================
    // device interface
    //=======================================================================
        
        input   wire                                           RXD
    
);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        logic unsigned [$clog2(STABLE_TIME + 1) - 1 : 0]                    stable_counter;
        logic unsigned [BAUD_PERIOD_BITS - 1 : 0]                           baud_rate_counter;
        logic                                                               baud_rate_pulse;
        logic unsigned [BAUD_PERIOD_BITS - 1 : 0]                           counter, counter_save;
        logic                                                               ctl_reset_stable_counter;
        logic                                                               ctl_save_counter;
        logic unsigned [$clog2 (`UART_DEFAULT_DATA_LEN + 4) - 1 : 0]        data_counter;
        logic                                                               ctl_reset_data_counter;
        logic                                                               ctl_inc_data_counter;

        logic                                                               ctl_shift_rx_data;
        logic                                                               ctl_set_RI;
        logic                                                               ctl_counter_reset;
        logic unsigned [2 : 0]                                              rxd_sr;
        
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // RI 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk, negedge reset_n) begin : RI_proc
            if (!reset_n) begin
                RI <= 0;
            end else if (ctl_set_RI) begin
                RI <= 1'b1;
            end else if (start_RX) begin
                RI <= 0;
            end
        end : RI_proc
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // baud_rate_pulse
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        
        always_ff @(posedge clk, negedge reset_n) begin : baud_rate_counter_proc
            if (!reset_n) begin
                baud_rate_counter <= 0;                
            end else if (sync_reset) begin
                baud_rate_counter <= 0;
            end else if (baud_rate_counter == baud_rate_period_m1) begin
                baud_rate_counter <= 0;
            end else begin
                baud_rate_counter <= baud_rate_counter + ($size(baud_rate_counter))'(1);
            end
        end : baud_rate_counter_proc
                
        
        always_ff @(posedge clk, negedge reset_n) begin : baud_rate_pulse_proc
            if (!reset_n) begin
                baud_rate_pulse <= 0;
            end else if (baud_rate_counter == 1) begin
                baud_rate_pulse <= 1'b1;
            end else begin
                baud_rate_pulse <= 0;
            end
        end : baud_rate_pulse_proc
    
    
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // rxd_sr
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk, negedge reset_n) begin : rxd_sr_proc
            if (!reset_n) begin
                rxd_sr <= 0;
            end else  begin
                rxd_sr <= {rxd_sr [$high(rxd_sr) - 1 : 0] , RXD};
            end
        end : rxd_sr_proc
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // rx_data
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk, negedge reset_n) begin : SBUF_out_proc
            if (!reset_n) begin
                SBUF_out <= 0;
            end else if (ctl_shift_rx_data) begin
                SBUF_out <= {rxd_sr[2], SBUF_out [$high(SBUF_out) : 1]};
            end
        end : SBUF_out_proc
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // counter
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk, negedge reset_n) begin : counter_proc
            if (!reset_n) begin
                counter <= 0;
            end else if (sync_reset | ctl_counter_reset) begin
                counter <= 0;
            end else if (baud_rate_pulse) begin
                counter <= 0;
            end else begin
                counter <= counter + ($size(counter))'(1);
            end
        end : counter_proc
        
        always_ff @(posedge clk, negedge reset_n) begin : counter_save_proc
            if (!reset_n) begin
                counter_save <= 0;
            end else if (sync_reset | ctl_counter_reset) begin
                counter_save <= 0;
            end else if (ctl_save_counter) begin
                counter_save <= counter;
            end         
        end : counter_save_proc
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // data_counter
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk, negedge reset_n) begin : data_counter_proc
            if (!reset_n) begin
                data_counter <= 0;
            end else if (ctl_reset_data_counter) begin
                data_counter <= 0;
            end else if (ctl_inc_data_counter) begin
                data_counter <= data_counter + ($size(data_counter))'(1);
            end
        end : data_counter_proc
        
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // stable_counter
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk, negedge reset_n) begin : stable_counter_proc
            if (!reset_n) begin
                stable_counter <= 0;
            end else if (ctl_reset_stable_counter) begin
                stable_counter <= 0;
            end else begin
                stable_counter <= stable_counter + ($size(stable_counter))'(1);
            end         
        end : stable_counter_proc
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                
        enum {S_IDLE, S_RX_START, S_RX_START_BIT, S_RX_DATA, S_RX_STOP_BIT} states = S_IDLE;
                
        localparam FSM_NUM_OF_STATES = states.num();
        logic [FSM_NUM_OF_STATES - 1:0] current_state = 0, next_state;
                
        // Declare states
        always_ff @(posedge clk, negedge reset_n) begin : state_machine_reg
            if (!reset_n) begin
                current_state <= 0;
            end else if (sync_reset) begin 
                current_state <= 0;
            end else begin
                current_state <= next_state;
            end
        end : state_machine_reg
            
        // state cast for debug, one-hot translation, enum value can be shown in the simulation in this way
        // Hopefully, synthesizer will optimize out the "states" variable
            
        // synthesis translate_off
        ///////////////////////////////////////////////////////////////////////
            always_comb begin : state_cast_for_debug
                for (int i = 0; i < FSM_NUM_OF_STATES; ++i) begin
                    if (current_state[i]) begin
                        $cast(states, i);
                    end
                end
            end : state_cast_for_debug
        ///////////////////////////////////////////////////////////////////////
        // synthesis translate_on   
            
        // FSM main body
        always_comb begin : state_machine_comb

            next_state = 0;
            
            ctl_reset_stable_counter = 0;
            ctl_save_counter = 0;
            ctl_reset_data_counter = 0;
            
            ctl_inc_data_counter = 0;
            
            ctl_shift_rx_data = 0;
                        
            ctl_set_RI = 0;
            ctl_counter_reset = 0;
            
            
            case (1'b1) // synthesis parallel_case 
                
                current_state[S_IDLE]: begin
                
                    ctl_reset_data_counter = 1'b1;
                    ctl_counter_reset = 1'b1;
                    
                    if (start_RX) begin
                        next_state [S_RX_START] = 1'b1;
                    end else begin
                        next_state [S_IDLE] = 1'b1;
                    end
                end
                                
                current_state [S_RX_START] : begin
                    ctl_reset_stable_counter = 1'b1;
                
                    if (rxd_sr[2] & (~rxd_sr[1])) begin
                        next_state [S_RX_START_BIT] = 1'b1;
                    end else begin
                        next_state [S_RX_START] = 1'b1;
                    end

                end
                                
                current_state [S_RX_START_BIT] : begin

                    if (!rxd_sr[2]) begin
                        if (stable_counter == STABLE_TIME) begin
                            ctl_save_counter = 1'b1;
                            ctl_reset_data_counter = 0;
                            next_state [S_RX_DATA] = 1;
                        end else begin
                            next_state [S_RX_START_BIT] = 1;
                        end
                    end else begin
                        next_state [S_RX_START] = 1'b1;
                    end

                end

                current_state [S_RX_DATA] : begin

                    if (counter == counter_save) begin
                        ctl_inc_data_counter = 1'b1;
                        ctl_shift_rx_data = 1'b1;
                    end 

                    if (data_counter == `UART_DEFAULT_DATA_LEN) begin
                        next_state [S_RX_STOP_BIT] = 1'b1;
                    end else begin
                        next_state [S_RX_DATA] = 1;
                    end

                end

                current_state [S_RX_STOP_BIT] : begin
                    if (counter == counter_save) begin
                        ctl_set_RI = 1'b1;
                        next_state [S_IDLE] = 1;
                    end else begin
                        next_state [S_RX_STOP_BIT] = 1;
                    end
                end
                
                
                default: begin
                    next_state[S_IDLE] = 1'b1;
                end
                
            endcase
              
        end : state_machine_comb    

endmodule : UART_RX

`default_nettype wire
