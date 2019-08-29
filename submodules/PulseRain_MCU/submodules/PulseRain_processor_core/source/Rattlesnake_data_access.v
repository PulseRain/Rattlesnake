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

module Rattlesnake_data_access (
    //=====================================================================
    // clock and reset
    //=====================================================================
        input wire                                              clk,                          
        input wire                                              reset_n,                      
        input wire                                              sync_reset,

    //=====================================================================
    // interface from controller
    //=====================================================================
        input wire                                              data_access_enable,
   
    //=====================================================================
    // interface for the execution unit
    //=====================================================================
        input wire                                              ctl_CSR,
        input wire                                              ctl_CSR_write,
        
        input wire [`XLEN - 1 : 0]                              csr_new_value,
        input wire [`XLEN - 1 : 0]                              csr_old_value,
        
        input wire [`CSR_BITS - 1 : 0]                          csr_addr,
        
        input wire                                              ctl_save_to_rd,
        
        input wire [`REG_ADDR_BITS - 1 : 0]                     rd_addr_in,
        input wire [`XLEN - 1 : 0]                              rd_data_in,
        
        input wire                                              mul_div_active,
        input wire                                              load_active,
        input wire                                              store_active,
        input wire [2 : 0]                                      width_load_store,
        input wire [`XLEN - 1 : 0]                              data_to_store,
        input wire                                              indirect_protect_active,
        
        input wire [`XLEN - 1 : 0]                              mem_write_addr,
        input wire [`XLEN - 1 : 0]                              mem_read_addr,
        input wire                                              unaligned_write,
        input wire                                              unaligned_read,
        
        input wire                                              mul_div_done,
        
    //=====================================================================
    // interface to write to the register file
    //=====================================================================
        output wire                                             ctl_reg_we,
        output wire [`EXT_BITS + `XLEN - 1 : 0]                 ctl_reg_data_to_write,
        output wire [`REG_ADDR_BITS - 1 : 0]                    ctl_reg_addr,
    
    //=====================================================================
    // interface for CSR
    //=====================================================================
        output wire                                             ctl_csr_we,
        output wire [`CSR_ADDR_BITS - 1 : 0]                    ctl_csr_write_addr,
        output wire [`XLEN - 1 : 0]                             ctl_csr_write_data,
        
    //=====================================================================
    // interface for memory
    //=====================================================================
        input  wire                                             mem_enable_in,
        input  wire [`EXT_BITS + `XLEN - 1 : 0]                 mem_data_in,
        
        input  wire                                             mm_reg_enable_in,
        input  wire [`XLEN - 1 : 0]                             mm_reg_data_in,
        
        
        output wire                                             mem_re,
        output reg [`XLEN_BYTES - 1 : 0]                        mem_we,
        output reg [`EXT_BITS + `XLEN - 1 : 0]                  mem_data_to_write,
        output reg [`XLEN - 1 : 0]                              mem_addr_rw_out,
        output reg                                              store_done,
        output reg                                              write_active,
        
        input  wire                                             mem_read_ack,
        input  wire                                             mem_write_ack,
        
        output wire                                             load_done,
        output wire                                             exception_alignment,
        
        output reg                                              mm_reg_re,
        output reg [`XLEN_BYTES - 1 : 0]                        mm_reg_we,
        
        output wire [`XLEN - 1 : 0]                             mm_reg_data_to_write,
        output reg [`MM_REG_ADDR_BITS - 1 : 0]                  mm_reg_addr_rw_out
         
);


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg                                                     ctl_mem_we;
        reg                                                     ctl_mem_re;
        reg                                                     ctl_mem_we_d1;
        
        reg                                                     ctl_load_exception;
        reg                                                     ctl_store_exception;
        reg                                                     ctl_load_exception_d1;
        
        reg                                                     ctl_store_done;
        reg                                                     ctl_load_done;
        reg                                                     ctl_load_reg_write;
        
        reg [2 : 0]                                             width_reg;
        reg [3 : 0]                                             width_mask;
        
        wire [`EXT_BITS +`XLEN - 1 : 0]                         mem_data_in_reg;
        reg [`EXT_BITS + `XLEN - 1 : 0]                         load_masked_data;
        
        reg [1 : 0]                                             mem_addr_rw_out_tail_reg;
        
        wire [`EXT_BITS + `XLEN - 1 : 0]                        mem_data_in_mux;
        reg [`XLEN - 1 : 0]                                     mem_write_addr_d1;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // data path
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        //---------------------------------------------------------------------
        //  register write back
        //---------------------------------------------------------------------
            assign ctl_reg_we            = (data_access_enable & ctl_save_to_rd) | ctl_load_reg_write | mul_div_done;
            assign ctl_reg_data_to_write = ctl_CSR ? {1'b0, csr_old_value} : (ctl_load_reg_write ? load_masked_data : {1'b0, rd_data_in});
            assign ctl_reg_addr          = rd_addr_in;

        //---------------------------------------------------------------------
        //  CSR write back
        //---------------------------------------------------------------------
            assign ctl_csr_we            = data_access_enable & ctl_CSR_write;
            assign ctl_csr_write_addr    = csr_addr;
            assign ctl_csr_write_data    = csr_new_value;
        
        //---------------------------------------------------------------------
        //  memory read / write
        //---------------------------------------------------------------------
            
   /*         always @(*) begin
                case (mem_write_addr[1 : 0]) // synthesis parallel_case 
                    2'b01 : begin
                        mem_data_to_write = {data_to_store[23 : 0], 8'd0};
                    end

                    2'b10 : begin
                        mem_data_to_write = {data_to_store[15 : 0], 16'd0};
                    end
                            
                    2'b11 : begin
                        mem_data_to_write = {data_to_store[7 : 0], 24'd0};
                    end
                            
                    default : begin
                        mem_data_to_write = data_to_store;
                    end
                endcase
            end
     */       
            
            always @(posedge clk, negedge reset_n) begin
                if (!reset_n) begin
                    write_active <= 0;
                end else if ((|mem_we) & (~mem_write_ack)) begin
                    write_active <= 1'b1;
                end else if (mem_write_ack) begin
                    write_active <= 1'b1;
                end
                
            end
     
            always @(*) begin
                if (width_load_store [1 : 0] == 2'b00) begin
                    width_mask = 4'b0001 << (mem_write_addr[1 : 0]);
                end else if (width_load_store [1 : 0] == 2'b01) begin
                    width_mask = 4'b0011 << (mem_write_addr[1 : 0]);
                end else begin
                    width_mask = 4'b1111;
                end
            end
             
           // assign mem_we ={ctl_mem_we, ctl_mem_we, ctl_mem_we, ctl_mem_we} & width_mask;
            assign mem_re = ctl_mem_re & (mem_read_addr [`MEM_SPACE_BIT]);
            
            always @(*) begin
                if (ctl_mem_we_d1) begin
                    mem_addr_rw_out = mem_write_addr_d1;
                end else begin
                    mem_addr_rw_out = mem_read_addr;
                end
            end
            
            assign mem_data_in_mux = mem_enable_in ? mem_data_in : {1'b0, mm_reg_data_in};
            assign mem_data_in_reg [`EXT_BITS + `XLEN - 1 : 8] = mem_data_in_mux [`EXT_BITS + `XLEN - 1 : 8];
            assign mem_data_in_reg [7 : 0] = (mem_addr_rw_out_tail_reg[0]) ? mem_data_in_mux[15 : 8] : mem_data_in_mux [7 : 0];
           
            always @(*) begin
                case (width_reg)
                    3'b000 : begin  // LB
                        load_masked_data = {1'b0, {24{mem_data_in_reg[7]}}, mem_data_in_reg[7 : 0]};
                    end
                    
                    3'b001 : begin // LH
                        load_masked_data = {1'b0, {16{mem_data_in_reg[15]}}, mem_data_in_reg[15 : 0]};
                    end
                    
                    3'b100 : begin  // LBU
                        load_masked_data = {1'b0, 24'd0, mem_data_in_reg[7 : 0]};
                    end
                    
                    3'b101 : begin // LHU
                        load_masked_data = {1'b0, 16'd0, mem_data_in_reg[15 : 0]};
                    end
                    
                    default : begin
                        load_masked_data = mem_data_in_reg;
                    end
                    
                endcase
            end
            
            assign load_done = ctl_load_done;
            assign mm_reg_data_to_write = mem_data_to_write[`XLEN - 1 : 0];
            
            always @(posedge clk, negedge reset_n) begin
                if (!reset_n) begin
                 //   mem_re <= 0;
                    mem_we <= 0;
                    mm_reg_re <= 0;
                    mm_reg_we <= 0;
                    mem_data_to_write <= 0;
                 //   mem_addr_rw_out <= 0;
                    
                    width_reg  <= 0;
                //    width_mask <= 0;
                    
                 //   mem_data_in_reg <= 0;
                    
                    ctl_mem_we_d1 <= 0;
                    
                    store_done <= 0;
                  //  load_done  <= 0;
                    
                //    load_masked_data <= 0;
                    
                    mm_reg_addr_rw_out <= 0;
                    
                    mem_addr_rw_out_tail_reg <= 0;
                    
                    mem_write_addr_d1 <= 0;
                    
                    ctl_load_exception_d1 <= 0;
                    
                end else begin
                    
                    mem_write_addr_d1 <= mem_write_addr;
                    ctl_load_exception_d1 <= ctl_load_exception;
                    
                    mm_reg_we <= {(`XLEN_BYTES){ctl_mem_we & mem_write_addr [`REG_SPACE_BIT]}} & width_mask;
                    mm_reg_re <= ctl_mem_re & mem_read_addr [`REG_SPACE_BIT];
                    
                    mm_reg_addr_rw_out <= ctl_mem_we ? mem_write_addr [`MM_REG_ADDR_BITS + 1 : 2] : mem_read_addr [`MM_REG_ADDR_BITS + 1 : 2];
                    
                    ctl_mem_we_d1 <= ctl_mem_we;
                    
                    store_done <= ctl_store_done;
                    
                    mem_we <= {(`XLEN_BYTES){ctl_mem_we & (mem_write_addr [`MEM_SPACE_BIT])}} & width_mask;
                    
                    mem_data_to_write[`XLEN] <= indirect_protect_active;
                    
                    case (mem_write_addr[1 : 0]) // synthesis parallel_case 
                        2'b01 : begin
                              mem_data_to_write [`XLEN - 1 : 0] <= {data_to_store[23 : 0], 8'd0};
                        end

                        2'b10 : begin
                              mem_data_to_write [`XLEN - 1 : 0] <= {data_to_store[15 : 0], 16'd0};
                        end
                      
                        2'b11 : begin
                              mem_data_to_write [`XLEN - 1 : 0] <= {data_to_store[7 : 0], 24'd0};
                        end
                      
                        default : begin
                              mem_data_to_write [`XLEN - 1 : 0] <= data_to_store;
                        end
                          
                    endcase
                                        

                    if (data_access_enable) begin
                        width_reg <= width_load_store;
                        mem_addr_rw_out_tail_reg <= mem_addr_rw_out [1 : 0];
                      
                    end
                    
                end 
            end
            
        //---------------------------------------------------------------------
        //  exception
        //---------------------------------------------------------------------
 
            assign exception_alignment = ctl_store_exception | ctl_load_exception_d1;
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            localparam S_IDLE = 0, S_EXCEPTION = 1, S_LOAD = 2, S_STORE = 3, S_MUL_DIV = 4; 
            
            reg [4 : 0] current_state, next_state;
                    
            // Declare states
            always @(posedge clk, negedge reset_n) begin : state_machine_reg
                if (!reset_n) begin
                    current_state <= 0;
                end else if (sync_reset) begin 
                    current_state <= 0;
                end else begin
                    current_state <= next_state;
                end
            end
                
            // FSM main body
            always @(*) begin : state_machine_comb
    
                next_state = 0;
                
                ctl_mem_we               = 0;
                ctl_mem_re               = 0;
                ctl_load_exception       = 0;
                ctl_store_exception      = 0;
                ctl_store_done           = 0;
                ctl_load_done            = 0;
                ctl_load_reg_write       = 0;
                
                case (1'b1) // synthesis parallel_case 
                    
                    current_state[S_IDLE]: begin
                        if (data_access_enable) begin
                            if (store_active) begin
                                if (unaligned_write) begin
                                    ctl_store_exception = 1'b1;
                                    next_state [S_EXCEPTION] = 1'b1;
                                end else begin
                                    ctl_mem_we = 1'b1;
                                    if (`STORE_WAIT_FOR_ACK) begin
                                        if (mem_write_addr [`REG_SPACE_BIT]) begin
                                            ctl_store_done = 1'b1;
                                            next_state [S_IDLE] = 1'b1;
                                        end else begin
                                            next_state [S_STORE] = 1'b1;
                                        end
                                        
                                    end else begin
                                        next_state [S_IDLE] = 1'b1;
                                    end
                                end
                            end else if (load_active) begin
                                if (unaligned_read) begin
                                    ctl_load_exception = 1'b1;
                                    next_state [S_EXCEPTION] = 1'b1;
                                end else begin
                                    ctl_mem_re = 1'b1;
                                    next_state [S_LOAD] = 1'b1;
                                end
                            end else if (mul_div_active) begin
                                next_state [S_MUL_DIV] = 1'b1;
                            end else begin
                                next_state [S_IDLE] = 1'b1;
                            end
                        end else begin
                            next_state [S_IDLE] = 1'b1;
                        end
                    end
                    
                    current_state [S_EXCEPTION] : begin
                        next_state [S_IDLE] = 1'b1;
                    end
                    
                    current_state [S_LOAD] : begin
                        if (mem_enable_in | mm_reg_enable_in) begin
                            //==next_state [S_LOAD_SHIFT_IN] = 1'b1;
                            
                            ctl_load_reg_write = 1'b1;
                            ctl_load_done = 1'b1;
                            next_state [S_IDLE] = 1'b1;
                        end else begin
                            next_state [S_LOAD] = 1'b1;
                        end
                    end
                    
                    current_state [S_STORE] : begin
                        if (mem_write_ack) begin
                            ctl_store_done = 1'b1;
                            next_state [S_IDLE] = 1'b1;
                        end else begin
                            next_state [S_STORE] = 1'b1;
                        end
                    end
                    
                    current_state [S_MUL_DIV] : begin
                        if (mul_div_done) begin
                            next_state [S_IDLE] = 1'b1;
                        end else begin
                            next_state[S_MUL_DIV] = 1'b1;
                        end
                    end
                    
                    default: begin
                        next_state[S_IDLE] = 1'b1;
                    end
                    
                endcase
                  
            end  
        
endmodule

`default_nettype wire
