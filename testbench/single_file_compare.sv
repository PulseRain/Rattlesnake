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


`include "file_compare.svh"


`default_nettype none

module single_file_compare #(parameter NUM_OF_COLUMNS, NUM_OF_COLUMNS_TO_DISPLAY, FILE_NAME, NUM_OF_LINES, BASE, LINES_TO_SKIP, VERBOSE,
                                       PAUSE_ON_MISMATCH, WILDCARD_COMPARE, CARRIAGE_RETURN) (
    //========== INPUT ==========

        //=======  clock and reset ======
        input wire clk,                             // clock input
        input wire reset_n,                         // reset, active low

    
        //====== data to compare
        input integer data_to_cmp[NUM_OF_COLUMNS],
        input wire enable_in,
        
        //========== OUTPUT ==========
        output wire pass1_fail0, 
        output wire all_done

        //========== IN/OUT ==========

);
    
    
    
     file_cmp_param_s file_to_cmp[1] = {
                                 {file_name : FILE_NAME,
                                  num_of_column : NUM_OF_COLUMNS,
                                  num_of_lines : NUM_OF_LINES,
                                  num_of_column_to_display : NUM_OF_COLUMNS_TO_DISPLAY,
                                  base : BASE,
                                  lines_to_skip : LINES_TO_SKIP,
                                  init_num_of_inputs_to_ignore : 0,
                                  verbose : VERBOSE,
                                  pause_on_mismatch :PAUSE_ON_MISMATCH,
                                  wildcard_compare : WILDCARD_COMPARE,
                                  carriage_return : CARRIAGE_RETURN}
                               };   
                                  
    
     file_compare file_compare_i (.*,
                                .files(file_to_cmp),
                                .num_of_files(1),
                                .data_to_cmp(data_to_cmp),
                                .enable_in (enable_in),
                                .pass1_fail0 (pass1_fail0),
                                .file_index (),
                                .single_file_done(),
                                .all_done(all_done));                           
    
endmodule : single_file_compare

`default_nettype wire
