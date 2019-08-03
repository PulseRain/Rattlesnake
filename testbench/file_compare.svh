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

`ifndef FILE_COMPARE_SVH
`define FILE_COMPARE_SVH
		
	import file_compare_pkg::*;

extern module file_compare (
//========== INPUT ==========

    //=======  clock and reset ======
        input wire clk,                             // clock input, 80 MHZ
        input wire reset_n,                         // reset, active low

    //====== parameters for files to compare 
        input file_cmp_param_s files[],
        input int num_of_files,
    
    //====== data to compare
        input integer data_to_cmp[],
        input wire enable_in,
        
//========== OUTPUT ==========
        output logic pass1_fail0, 
        output int file_index,
        output wire single_file_done,
        output logic all_done

//========== IN/OUT ==========
        
);
	
extern module single_file_compare #(parameter NUM_OF_COLUMNS, NUM_OF_COLUMNS_TO_DISPLAY, FILE_NAME, NUM_OF_LINES, BASE, LINES_TO_SKIP, VERBOSE,
		                               PAUSE_ON_MISMATCH, WILDCARD_COMPARE, CARRIAGE_RETURN) (
	//========== INPUT ==========

		//=======  clock and reset ======
		input wire clk,                             // clock input, 80 MHZ
		input wire reset_n,                         // reset, active low

	
		//====== data to compare
		input integer data_to_cmp[NUM_OF_COLUMNS],
		input wire enable_in,
        
		//========== OUTPUT ==========
		output wire pass1_fail0, 
		output wire all_done

		//========== IN/OUT ==========

);
		
`endif
