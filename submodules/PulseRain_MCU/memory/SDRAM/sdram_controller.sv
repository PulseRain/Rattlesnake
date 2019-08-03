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
 
`include "sdram_controller.svh"


module sdram_controller (
    //=====================================================================
    // clock and reset
    //=====================================================================
        input wire                                          clk,                          
        input wire                                          reset_n,                      
        input wire                                          sync_reset,
    
    //=====================================================================
    // memory interface
    //=====================================================================
        input wire                                          mem_cs,
        input wire unsigned [SDRAM_DATA_BITS / 8 - 1 : 0]   mem_byteenable,
        input wire                                          mem_read0_write1,
        input wire unsigned [SDRAM_ADDR_BITS - 1 : 0]       mem_addr,   // address for 16 bit word
        input wire unsigned [SDRAM_DATA_BITS - 1 : 0]       mem_write_data,
        
        output wire                                         mem_ack,
        output wire unsigned [SDRAM_DATA_BITS - 1 : 0]      mem_read_data,

    //=====================================================================
    // SDRAM Avalon Bus
    //=====================================================================
        input wire  [SDRAM_BUS_BITS - 1 : 0]                sdram_av_readdata,
        input wire                                          sdram_av_readdatavalid, 
        input wire                                          sdram_av_waitrequest, 

        output logic [SDRAM_ADDR_BITS - 1 : 0]              sdram_av_address,    
        output wire [SDRAM_BUS_BITS / 8 - 1 : 0]            sdram_av_byteenable_n,  
        output wire                                         sdram_av_chipselect,  
        output wire [SDRAM_BUS_BITS - 1 : 0]                sdram_av_writedata, 
        output wire                                         sdram_av_read_n, 
        output wire                                         sdram_av_write_n

);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        logic unsigned [$clog2(SDRAM_CAS) - 1 : 0]      cas_count;
        logic unsigned [SDRAM_DATA_BITS / 8 - 1 : 0]    byteenable_n;
        logic unsigned [SDRAM_DATA_BITS - 1 : 0]        write_data;
        logic                                           mem_read0_write1_save;
        
        logic unsigned [SDRAM_DATA_BITS - 1 : 0]        mem_read_data_reg;
        logic                                           ctl_start_mem_rw;
        logic                                           ctl_mem_ack;        
        logic                                           ctl_load_data_reg;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Avalon Bus Interface
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk, negedge reset_n) begin : avalon_proc
            if (!reset_n) begin
                byteenable_n <= 0;
                sdram_av_address <= 0;
                write_data <= 0;
                
                mem_read0_write1_save <= 0;
            end else begin
                
                if (mem_cs) begin
                    byteenable_n            <= ~mem_byteenable;
                    mem_read0_write1_save   <= mem_read0_write1;
                    sdram_av_address        <= mem_addr;
                    write_data              <= mem_write_data;
                end else if (ctl_start_mem_rw) begin
                    byteenable_n            <= {2'b00, byteenable_n[$high(byteenable_n) : 2]};
                    write_data              <= {(SDRAM_BUS_BITS)'(0), write_data[$high(write_data) : SDRAM_BUS_BITS]}; 
                    sdram_av_address        <= sdram_av_address + ($size(sdram_av_address))'(1);
                end
                
            end
        
        end : avalon_proc

        assign sdram_av_byteenable_n = byteenable_n [$high(sdram_av_byteenable_n) : 0];
        assign sdram_av_writedata = write_data [SDRAM_BUS_BITS - 1 : 0];
        
        assign sdram_av_read_n  = (ctl_start_mem_rw) ? mem_read0_write1_save : 1'b1;
        assign sdram_av_write_n = (ctl_start_mem_rw) ? (~mem_read0_write1_save) : 1'b1;
        assign sdram_av_chipselect = ctl_start_mem_rw;
        
        assign mem_ack = ctl_mem_ack;
        assign mem_read_data = mem_read_data_reg;

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // memory read data register
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always_ff @(posedge clk) begin
            if (ctl_load_data_reg) begin
                mem_read_data_reg <= {sdram_av_readdata, mem_read_data_reg [$high(mem_read_data_reg) : SDRAM_BUS_BITS]};
            end
        end

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        enum {S_IDLE, S_WAIT_REQ, S_WAIT_REQ_WR, S_WAIT_RD_VALID, S_WAIT_REQ_RD, S_WAIT_RD_VALID_2ND, S_ACK} states = S_IDLE;
                    
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

            ctl_start_mem_rw = 0;
            ctl_load_data_reg = 0;         
            ctl_mem_ack = 0;
            
            case (1'b1) // synthesis parallel_case 

                current_state[S_IDLE]: begin
                    if (mem_cs) begin
                        next_state [S_WAIT_REQ] = 1'b1;
                    end else begin
                        next_state [S_IDLE] = 1'b1;
                    end
                end

                current_state [S_WAIT_REQ] : begin
                    
                    if (sdram_av_waitrequest) begin
                        next_state [S_WAIT_REQ] = 1'b1;
                    end else begin
                        ctl_start_mem_rw = 1'b1;
                        
                        if (mem_read0_write1_save) begin
                            next_state [S_WAIT_REQ_WR] = 1'b1;
                        end else begin
                            next_state [S_WAIT_RD_VALID] = 1'b1; 
                        end
                        
                    end

                end

                current_state [S_WAIT_REQ_WR] : begin
                    if (sdram_av_waitrequest) begin
                        next_state [S_WAIT_REQ_WR] = 1'b1;
                    end else begin
                        ctl_start_mem_rw = 1'b1;
                        ctl_mem_ack = 1'b1;
                        next_state [S_IDLE] = 1'b1;
                    end
                end
                
                current_state [S_WAIT_RD_VALID] : begin
                
                    ctl_load_data_reg = sdram_av_readdatavalid;
                    
                    if (sdram_av_readdatavalid) begin
                        next_state [S_WAIT_REQ_RD] = 1'b1;
                    end else begin
                        next_state [S_WAIT_RD_VALID] = 1'b1;
                    end
                end
                
                current_state [S_WAIT_REQ_RD] : begin
                    if (sdram_av_waitrequest) begin
                        next_state [S_WAIT_REQ_RD] = 1'b1;
                    end else begin
                        ctl_start_mem_rw = 1'b1;
                        next_state [S_WAIT_RD_VALID_2ND] = 1'b1; 
                    end
                end
                
                current_state [S_WAIT_RD_VALID_2ND] : begin
                    ctl_load_data_reg = sdram_av_readdatavalid;
                    
                    if (sdram_av_readdatavalid) begin
                        next_state [S_ACK] = 1'b1;
                    end else begin
                        next_state [S_WAIT_RD_VALID_2ND] = 1'b1;
                    end
                end

                current_state [S_ACK]: begin
                    ctl_mem_ack = 1'b1;
                    next_state [S_IDLE] = 1'b1;
                end
                
                default: begin
                    next_state[S_IDLE] = 1'b1;
                end

            endcase

        end : state_machine_comb  

endmodule : sdram_controller
