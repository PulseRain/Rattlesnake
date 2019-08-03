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
//    PulseRain RV2T is a MCU core of Von Neumann architecture. 
//=============================================================================

`include "common.vh"

`default_nettype none

module Rattlesnake_controller (

    //=====================================================================
    // clock and reset
    //=====================================================================
            
        input wire                                          clk,                          
        input wire                                          reset_n,                      
        input wire                                          sync_reset,
    
    //=====================================================================
    // mem_ack
    //=====================================================================
        input wire                                          mem_read_ack,
        input wire                                          mem_write_ack,
        input wire                                          data_access_write_active,
        
    //=====================================================================
    // interface for PC init
    //=====================================================================
        input wire                                          start,
        input wire [`PC_BITWIDTH - 1 : 0]                   start_addr,
    
   
        
    //=====================================================================
    // interface for instruction fetch
    //=====================================================================
        output reg                                          fetch_init,
        output reg [`PC_BITWIDTH - 1 : 0]                   fetch_start_addr,
        output wire                                         fetch_next,
        
        
    //=====================================================================
    // JARL / BRANCH
    //=====================================================================
        input wire                                          branch_active,
        input wire [`PC_BITWIDTH - 1 : 0]                   branch_addr,
        input wire                                          jalr_active,
        input wire [`PC_BITWIDTH - 1 : 0]                   jalr_addr,
        input wire                                          jal_active,
        input wire [`PC_BITWIDTH - 1 : 0]                   jal_addr,
        
    //=====================================================================
    // LOAD / STORE
    //=====================================================================
        input wire                                          decode_enable_out,
        input wire                                          decode_ctl_LOAD,
        input wire                                          decode_ctl_STORE,
        input wire                                          decode_ctl_MISC_MEM,
        input wire                                          decode_ctl_MUL_DIV_FUNCT3,
        
        input wire                                          decode_ctl_WFI,
        
        input wire                                          mul_div_active,
        input wire                                          mul_div_done,
        
        input wire                                          load_active,
        input wire                                          store_active,
        
        input wire [`XLEN - 1 : 0]                          data_to_store,
        input wire [`XLEN - 1 : 0]                          mem_write_addr,
        input wire [`XLEN - 1 : 0]                          mem_read_addr,
        input wire                                          unaligned_write,
        
        input wire                                          store_done,
        input wire                                          load_done,
        
    //=====================================================================
    // MRET
    //=====================================================================
        
        input  wire                                         mret_active,
        output wire                                         csr_mret_active,
    //=====================================================================
    // interface for execution unit
    //=====================================================================
        output wire                                         exe_enable,
        output wire                                         data_access_enable,

    //=====================================================================
    // exception
    //=====================================================================
        input wire  [`PC_BITWIDTH - 1 : 0]                  PC_in,
        
        input wire  [`XLEN - 1 : 0]                         mtvec_in,
        input wire  [`XLEN - 1 : 0]                         mepc_in,
        
        input wire                                          exception_storage_page_fault,
        input wire                                          exception_ecall,
        input wire                                          exception_ebreak,
        input wire                                          exception_alignment,
        input wire                                          timer_triggered,
        input wire                                          ext_int_triggered,
         
        output reg                                          is_interrupt,
        output reg [`EXCEPTION_CODE_BITS - 1 : 0]           exception_code,
        output reg                                          activate_exception,
        output reg [`PC_BITWIDTH - 1 : 0]                   exception_PC,
        output reg [`PC_BITWIDTH - 1 : 0]                   exception_addr,
        
        output wire                                         paused
        
);

        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Signal
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            reg                                             ctl_pc_init;
            reg                                             ctl_fetch_enable;
            reg                                             ctl_exe_enable;
            reg                                             ctl_data_access_enable;
            reg                                             ctl_fetch_init_jal;
            reg                                             ctl_fetch_init_branch;
            reg                                             ctl_fetch_init_jalr;
            reg                                             ctl_fetch_init_exception;
            reg                                             ctl_fetch_init_mret_active;
            reg                                             ctl_disable_data_access;
            
            reg                                             ctl_disable_data_access_reg;
            reg                                             ctl_clear_exception;
            reg                                             ctl_activate_exception;
            reg                                             ctl_instruction_addr_misalign_exception;
            reg                                             ctl_load_active;
            reg                                             ctl_fetch_exe_active;
            reg                                             ctl_paused;
            
            reg                                             ctl_set_timer_interrupt_active;
            reg                                             ctl_interrupt_set_reg;
            reg                                             ctl_set_timer_interrupt_active_reg;
            reg                                             ctl_set_ext_interrupt_active;
            reg                                             ctl_set_ext_interrupt_active_reg;
            
            reg                                             ctl_back_to_exe;
            reg                                             ctl_back_to_exe_d1;
            reg                                             ctl_back_to_exe_d2;            
            
            reg                                             fetch_active;
            
            reg                                             load_active_reg;
           
           
           
            reg                                             first_exe;

            reg [`XLEN - 1 : 0]                             mem_read_addr_d1;
            
            wire                                            exception_active;
            wire                                            exception_active_reg;    
            reg                                             exception_storage_page_fault_reg;
            reg                                             exception_ecall_reg;
            reg                                             exception_ebreak_reg;
            reg                                             exception_instruction_addr_misalign_reg;
            reg                                             exception_alignment_reg;
            reg                                             timer_interrupt_active;
            reg                                             ext_interrupt_active;
                        
            reg                                             decode_ctl_WFI_d1;
            reg                                             ecall_active;
            
            reg                                             mem_read_ack_d1;
            reg                                             decode_enable_out_d1;
            
            reg [`PC_BITWIDTH - 1 : 0]                      PC_load_store;
            reg [`PC_BITWIDTH - 1 : 0]                      PC_save; 
        
            reg                                             load_active_d1;
            reg                                             store_active_d1;
                
            reg                                             fetch_init_active;
            
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // data path
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                assign exception_active     = exception_storage_page_fault | exception_ecall | exception_ebreak | ctl_instruction_addr_misalign_exception | exception_alignment;
                assign exception_active_reg = 
                            exception_storage_page_fault_reg | exception_ecall_reg | exception_ebreak_reg | exception_instruction_addr_misalign_reg | exception_alignment_reg;
                
                assign csr_mret_active = ctl_fetch_init_mret_active;
                
                always @(posedge clk, negedge reset_n) begin : fetch_proc
                    if (!reset_n) begin
                        fetch_init       <= 0;
                        fetch_start_addr <= 0;
                        
                        ctl_disable_data_access_reg <= 0;
                        
                        exception_storage_page_fault_reg <= 0;
                        exception_ecall_reg  <= 0;
                        exception_ebreak_reg <= 0;
                        exception_instruction_addr_misalign_reg <= 0;
                        
                        exception_code <= 0;
                        
                        activate_exception <= 0;
                        
                        exception_PC   <= 0;
                        exception_addr <= 0;
                        
                        load_active_reg  <= 0;
                        
                        exception_alignment_reg <= 0;
                        timer_interrupt_active <= 0;
                        ext_interrupt_active   <= 0;
                        
                        mem_read_addr_d1  <= 0;
            
                        ctl_set_timer_interrupt_active_reg <= 0;
                        ctl_set_ext_interrupt_active_reg <= 0;
                        
                        decode_ctl_WFI_d1 <= 0;
                        is_interrupt <= 0;
                        ecall_active <= 0;
                        
                        mem_read_ack_d1 <= 0;
                        decode_enable_out_d1 <= 0;
                        ctl_back_to_exe_d1 <= 0;
                        ctl_back_to_exe_d2 <= 0;
                        
                        fetch_active <= 0;
                        
                        PC_load_store <= 0;
                        
                        load_active_d1 <= 0;
                        store_active_d1 <= 0;
                        
                        fetch_init_active <= 0;
                        
                        ctl_interrupt_set_reg <= 0;
                        
                    end else begin
                                    
                        load_active_d1 <= load_active;
                        store_active_d1 <= store_active;
                        
                        decode_ctl_WFI_d1 <= decode_ctl_WFI;
                        
                        activate_exception <= ctl_activate_exception;
                        
                        mem_read_addr_d1  <= mem_read_addr;
            
                        mem_read_ack_d1      <= mem_read_ack;
                        decode_enable_out_d1 <= decode_enable_out;
                        ctl_back_to_exe_d1 <= ctl_back_to_exe;
                        ctl_back_to_exe_d2 <= ctl_back_to_exe_d1;
                        
                        if (((~load_active_d1) & load_active) | ((~store_active_d1) & store_active)) begin
                            PC_load_store <= PC_in;
                        end
                        
                        if (ctl_fetch_enable) begin
                            fetch_active <= 1'b1;
                        end else if (mem_read_ack) begin
                            fetch_active <= 0;
                        end
                        
                        if (fetch_init) begin
                            fetch_init_active <= 1'b1;
                        end else if (ctl_exe_enable) begin
                            fetch_init_active <= 1'b0;
                        end
                        
                        ctl_interrupt_set_reg <= ctl_set_timer_interrupt_active + ctl_set_ext_interrupt_active;
                        
                        if (exception_ebreak | exception_ecall | exception_storage_page_fault | ctl_instruction_addr_misalign_exception ) begin
                            exception_PC <= PC_in;
                        end else if (exception_alignment) begin
                        
                            if ((`STORE_WAIT_FOR_ACK) | load_active) begin
                                exception_PC <= PC_load_store;
                            end else begin
                                exception_PC <= PC_in;
                            end
                            
                        end else if (data_access_enable & decode_ctl_WFI_d1) begin
                            exception_PC <= PC_in + 4;
                        end else if (ctl_set_timer_interrupt_active | ctl_set_ext_interrupt_active) begin
                            
                            if (fetch_init_active | fetch_init) begin
                                exception_PC <= fetch_start_addr;
                            end else if (ctl_back_to_exe_d1) begin
                                exception_PC <= PC_in;
                            end else begin
                                exception_PC <= PC_in  + 4;
                            end
                        end else if (ctl_interrupt_set_reg & fetch_init) begin
                            // This could happen when the timer hits an active branch/jump instruction
                            exception_PC <= fetch_start_addr;
                        end 
                        
                        if (data_access_enable) begin
                            
                            if (exception_alignment) begin // store exception
                                exception_addr <= mem_write_addr;
                            end else begin
                                case (1'b1) // synthesis parallel_case 
                                    jal_active : begin
                                        exception_addr <= {jal_addr[`PC_BITWIDTH - 1 : 1], 1'b0};
                                    end
                                    
                                    jalr_active : begin
                                        exception_addr <= {jalr_addr[`PC_BITWIDTH - 1 : 1], 1'b0};
                                    end
                                    
                                    branch_active : begin
                                        exception_addr <= {branch_addr[`PC_BITWIDTH - 1 : 1], 1'b0};
                                    end
                                    
                                    default : begin
                                        exception_addr <= PC_in;
                                    end
                                    
                                endcase
                            end
                        end else if (exception_alignment) begin // load exception
                            exception_addr <= mem_read_addr_d1;
                        end 
                        
                                
                        if (ctl_set_timer_interrupt_active) begin
                            timer_interrupt_active <= 1'b1;
                        end else if (mret_active) begin
                            timer_interrupt_active <= 0;
                        end
                        
                        if (ctl_set_ext_interrupt_active) begin
                            ext_interrupt_active <= 1'b1;
                        end else if (mret_active) begin
                            ext_interrupt_active <= 0;
                        end
                                                
                        ctl_set_timer_interrupt_active_reg <= ctl_set_timer_interrupt_active;
                        ctl_set_ext_interrupt_active_reg <= ctl_set_ext_interrupt_active;
                                                
                        if (ctl_clear_exception) begin
                            exception_storage_page_fault_reg <= 0;
                        end else if (exception_storage_page_fault) begin
                            exception_storage_page_fault_reg <= 1'b1;
                        end 
                        
                        if (ctl_clear_exception) begin
                            exception_ecall_reg <= 0;
                        end else if (exception_ecall) begin
                            exception_ecall_reg <= 1'b1;
                        end
                        
                        if (ctl_clear_exception) begin
                            exception_ebreak_reg <= 0;
                        end else if (exception_ebreak) begin
                            exception_ebreak_reg <= 1'b1;
                        end
                        
                        if (ctl_clear_exception) begin
                            exception_instruction_addr_misalign_reg <= 0;
                        end else if (ctl_instruction_addr_misalign_exception) begin
                            exception_instruction_addr_misalign_reg <= 1'b1;
                        end
                        
                        if (ctl_clear_exception) begin
                            exception_alignment_reg <= 0;
                        end else if (exception_alignment) begin
                            exception_alignment_reg <= 1'b1;
                        end
                        
                        if (ctl_fetch_exe_active) begin
                            load_active_reg <= 0;
                        end else if (ctl_load_active) begin
                            load_active_reg <= 1'b1;
                        end
                        
                        if (exception_ecall) begin
                            ecall_active <= 1'b1;
                        end else if (mret_active) begin
                            ecall_active <= 1'b0;
                        end
                        
                        if (ctl_set_timer_interrupt_active_reg) begin
                            exception_code <= `INTERRUPT_MACHINE_TIMER;
                            is_interrupt <= 1'b1;
                        end else if (ctl_set_ext_interrupt_active_reg) begin
                            exception_code <= `INTERRUPT_MACHINE_EXTERNAL;
                            is_interrupt <= 1'b1;
                        end else begin
                            is_interrupt <= 0;
                            
                            case (1'b1) // synthesis parallel_case 
                                exception_storage_page_fault_reg : begin
                                    exception_code <= `EXCEPTION_STORE_PAGE_FAULT;
                                end

                                exception_ecall_reg : begin
                                    exception_code <= `EXCEPTION_ENV_CALL_FROM_M_MODE;
                                end
                                
                                exception_ebreak_reg : begin
                                    exception_code <= `EXCEPTION_BREAKPOINT;
                                end
                                
                                exception_instruction_addr_misalign_reg : begin
                                    exception_code <= `EXCEPTION_INSTRUCTION_ADDR_MISALIGN;
                                end
                                
                                exception_alignment_reg : begin
                                    if (load_active_reg) begin
                                        exception_code <= `EXCEPTION_LOAD_ADDR_MISALIGN;
                                    end else begin
                                        exception_code <= `EXCEPTION_STORE_ADDR_MISALIGN;
                                    end
                                end
                                
                                default : begin
                                
                                end
                                
                            endcase
                        end
                        
                        fetch_init <= ctl_pc_init | ctl_fetch_init_jal | ctl_fetch_init_branch | ctl_fetch_init_jalr | ctl_fetch_init_exception | ctl_fetch_init_mret_active;
                        
                        ctl_disable_data_access_reg <= ctl_disable_data_access;
                        
                        case (1'b1) // synthesis parallel_case 
                            ctl_pc_init : begin
                                fetch_start_addr <= {start_addr [`PC_BITWIDTH - 1 : 1], 1'b0};
                            end
                            
                            ctl_fetch_init_jal : begin
                                fetch_start_addr <= {jal_addr[`PC_BITWIDTH - 1 : 1], 1'b0};
                            end
                            
                            ctl_fetch_init_branch : begin
                                fetch_start_addr <= {branch_addr [`PC_BITWIDTH - 1 : 1], 1'b0};
                            end
                            
                            ctl_fetch_init_jalr : begin
                                fetch_start_addr <= {jalr_addr [`PC_BITWIDTH - 1 : 1], 1'b0};
                            end
                            
                            ctl_fetch_init_mret_active : begin
                                fetch_start_addr <= mepc_in;
                            end
                            
                            ctl_fetch_init_exception : begin
                                if (mtvec_in [1 : 0] == 2'b00) begin
                                    fetch_start_addr <= mtvec_in;
                                end else begin
                                    fetch_start_addr <= {mtvec_in [`XLEN - 1 : 2], 2'b00} + {{(30 - `EXCEPTION_CODE_BITS){1'b0}}, exception_code, 2'b00};
                                end
                            end
                            
                            default : begin
                            
                            end

                        endcase
                        
                    end
                    
                end
                
                assign fetch_next = ctl_fetch_enable;
                
                assign exe_enable = ctl_exe_enable;
                
                assign data_access_enable = ctl_data_access_enable;
                
                always @(posedge clk, negedge reset_n) begin : first_exe_proc
                    if (!reset_n) begin
                        first_exe <= 0;
                    end else if (fetch_init) begin
                        first_exe <= 0;
                    end else if (exe_enable) begin
                        first_exe <= 1'b1;
                    end
                end
                
                assign paused = ctl_paused;
           
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // FSM
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            localparam S_INIT = 0, S_INIT_WAIT1 = 1, S_FETCH = 2, 
                       S_DECODE = 3, S_FETCH_EXE = 4, S_DECODE_DATA = 5,
                       S_STORE = 6, S_STORE_WAIT = 7, S_LOAD = 8, S_LOAD_WAIT = 9,
                       S_EXCEPTION = 10, S_EXCEPTION_REINIT = 11, S_MUL_DIV = 12,
                       S_WFI = 13, S_WFI_WAIT = 14, S_PRE_WFI = 15;
                       
            reg [15 : 0] current_state, next_state;
                  
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
                
                ctl_pc_init = 0;
                ctl_fetch_enable = 0;
                ctl_exe_enable = 0;
                ctl_data_access_enable = 0;
                ctl_disable_data_access = 0;
                
                ctl_fetch_init_jal = 0;
                ctl_fetch_init_branch = 0;
                ctl_fetch_init_jalr = 0;
                ctl_fetch_init_mret_active = 0;
                
                ctl_clear_exception = 0;
                ctl_activate_exception = 0;
                
                ctl_fetch_init_exception = 0;
                
                ctl_instruction_addr_misalign_exception = 0;
                
                ctl_load_active = 0;
            
                ctl_fetch_exe_active = 0;
                
                ctl_paused = 0;
                
                ctl_set_timer_interrupt_active = 0;
                ctl_set_ext_interrupt_active = 0;
                
                ctl_back_to_exe = 0;
                
                case (1'b1) // synthesis parallel_case 
                    
                    current_state[S_INIT]: begin
                        ctl_paused = 1'b1;
                        
                        if (start) begin
                            ctl_pc_init = 1'b1;
                            next_state [S_INIT_WAIT1] = 1'b1;
                        end else begin
                            next_state [S_INIT] = 1'b1;
                        end
                        
                    end
                    
                    current_state[S_INIT_WAIT1]: begin
                        next_state [S_FETCH] = 1'b1;
                    end
                    
                    current_state [S_FETCH] : begin
                        next_state [S_DECODE] = 1'b1;
                    end
                    
                    current_state [S_DECODE] : begin
                        if (!mem_read_ack) begin
                            next_state [S_DECODE] = 1'b1;
                        end else begin
                            ctl_fetch_enable = 1;
                            next_state [S_FETCH_EXE] = 1'b1;
                        end 
                    end
                    
                    current_state [S_FETCH_EXE] : begin
                        
                        
                        ctl_fetch_exe_active = 1'b1;
                        
                        ctl_data_access_enable = first_exe & (~ctl_disable_data_access_reg);
                        ctl_fetch_init_jal = jal_active & (~(jal_addr[1]));
                        ctl_fetch_init_branch = branch_active & (~(branch_addr[1]));
                        ctl_fetch_init_jalr = jalr_active & (~(jalr_addr[1]));
                        ctl_fetch_init_mret_active = mret_active;
                        
                        if (timer_triggered & (~timer_interrupt_active) & (~ext_interrupt_active) & (~ecall_active)) begin
                            ctl_set_timer_interrupt_active = 1'b1;
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (ext_int_triggered & (~timer_interrupt_active) & (~ext_interrupt_active) & (~ecall_active)) begin
                            ctl_set_ext_interrupt_active = 1'b1;
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if ((jal_active & jal_addr[1]) | (jalr_active & jalr_addr[1]) | (branch_active & branch_addr[1])) begin
                            ctl_instruction_addr_misalign_exception = 1'b1;
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if ((exception_active | exception_active_reg) & data_access_enable) begin
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (jal_active | branch_active | jalr_active | mret_active) begin
                            next_state [S_INIT_WAIT1] = 1'b1;
                        end else begin
                            next_state [S_DECODE_DATA] = 1'b1;
                        end
                        
                    end
                    
                    current_state [S_DECODE_DATA] : begin
                        ctl_exe_enable = decode_enable_out | decode_enable_out_d1 | ctl_back_to_exe_d2; 
                        ctl_disable_data_access = ~ctl_exe_enable;
                                          
                        if (ctl_exe_enable) begin
                            if (decode_ctl_WFI) begin
                                next_state [S_PRE_WFI] = 1'b1;
                            end 
                            
                            else if (decode_ctl_STORE & (`STORE_WAIT_FOR_ACK) ) begin
                                next_state [S_STORE] = 1'b1;
                            end 
                            
                            else if (decode_ctl_LOAD) begin
                                next_state [S_LOAD] = 1'b1; 
                            end else if (decode_ctl_MUL_DIV_FUNCT3) begin
                                next_state [S_MUL_DIV] = 1'b1;
                            end else begin
                                next_state [S_FETCH_EXE] = 1'b1;
                            end 
                        end else begin
                            ctl_fetch_enable = mem_read_ack | mem_read_ack_d1;
                          //  ctl_fetch_enable = 1'b1;                            
                            next_state [S_FETCH_EXE] = 1'b1;
                        end 
                    end
                                        
                    current_state [S_PRE_WFI] : begin
                        
                        if (decode_enable_out) begin
                             ctl_exe_enable = 1'b1;
                             next_state [S_WFI] = 1'b1;
                        end else begin
                             ctl_data_access_enable = 1'b1;
                             next_state [S_WFI_WAIT] = 1'b1;
                        end
                    
                    end
                    
                    current_state [S_WFI] : begin
                        ctl_data_access_enable = 1'b1;
                        next_state [S_WFI_WAIT] = 1'b1;
                    end
                    
                    current_state [S_WFI_WAIT] : begin
                        if (timer_triggered & (~timer_interrupt_active) & (~ext_interrupt_active) ) begin
                            ctl_set_timer_interrupt_active = 1'b1;
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (ext_int_triggered & (~timer_interrupt_active) & (~ext_interrupt_active)) begin
                            ctl_set_ext_interrupt_active = 1'b1;
                            next_state [S_EXCEPTION] = 1'b1;
                        end else begin
                            next_state [S_WFI_WAIT] = 1'b1;
                        end
                    end
                    
                    current_state [S_STORE] : begin
                        if (!fetch_active)  begin
                            ctl_data_access_enable = 1'b1;
                            next_state [S_STORE_WAIT] = 1'b1;
                        end else begin
                            next_state [S_STORE] = 1'b1;
                        end
                    end
                    
                    current_state [S_STORE_WAIT] : begin
                        if (exception_alignment | exception_alignment_reg) begin
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (store_done) begin
                            ctl_fetch_enable = 1'b1; 
                            ctl_disable_data_access = 1'b1;
                            ctl_back_to_exe = 1'b1;
                            next_state [S_FETCH_EXE] = 1'b1;
                        end else begin
                            next_state [S_STORE_WAIT] = 1'b1;
                        end
                    end
                                        
                    current_state [S_LOAD] : begin
                        if (!fetch_active) begin 
                            ctl_data_access_enable = 1'b1;
                            ctl_load_active = 1'b1;
                            next_state [S_LOAD_WAIT] = 1'b1;
                        end else begin
                            next_state [S_LOAD] = 1'b1;
                        end
                    end
                    
                    current_state [S_LOAD_WAIT] : begin
                        if (exception_alignment | exception_alignment_reg) begin
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (load_done) begin
                            ctl_fetch_enable = 1'b1; 
                            ctl_disable_data_access = 1'b1;
                            ctl_back_to_exe = 1'b1;
                            next_state [S_FETCH_EXE] = 1'b1;
                        end else begin
                            next_state [S_LOAD_WAIT] = 1'b1;
                        end
                    end
                    
                    current_state [S_EXCEPTION] : begin
                        ctl_activate_exception = 1'b1;
                        next_state [S_EXCEPTION_REINIT] = 1'b1;
                    end
                    
                    current_state [S_EXCEPTION_REINIT] : begin
                        ctl_fetch_init_exception  = 1'b1;
                        ctl_clear_exception       = 1'b1;
                        next_state [S_INIT_WAIT1] = 1'b1;
                    end
                    
                    current_state [S_MUL_DIV] : begin
                        if (!mul_div_done) begin
                            next_state [S_MUL_DIV] = 1'b1;
                        end else begin
                            ctl_fetch_enable = 1'b1; 
                            ctl_disable_data_access = 1'b1;
                            ctl_back_to_exe = 1'b1;
                            next_state [S_FETCH_EXE] = 1'b1;
                        end
                    end
                    
                    default: begin
                        next_state[S_INIT] = 1'b1;
                    end
                    
                endcase
                  
            end  

endmodule

`default_nettype wire
