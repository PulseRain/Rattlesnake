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


`default_nettype none

`include "file_compare.svh"

module file_compare (
//========== INPUT ==========

    //=======  clock and reset ======
        input wire clk,                             // clock input
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
    
     bit done_i = 0;
     file_compare_c fc;
     
     assign single_file_done = done_i;
     
     initial begin : initial_proc
        all_done = 1'b0;
        file_index = 0;
        pass1_fail0 = 0;
      
        @(posedge clk);
         
        for (int i = 0; i < num_of_files; ++i) begin 
            fc = new(files[i]);
            file_index = i;
             
            @(posedge done_i);
        end 
        
        fc = null;
        all_done = 1'b1;
        
     end : initial_proc
     
      always @(posedge clk or negedge reset_n) begin : always_compare_proc
         if (!all_done) begin
             if (!reset_n) begin
                 fc.reset();
                 done_i = 0;
                 pass1_fail0 = 1;
             end else if(fc) begin
                 done_i = fc.run(.enable_in(enable_in), .data_to_cmp(data_to_cmp));
                 pass1_fail0 = pass1_fail0 & fc.pass1_fail0;
             end
         end
     end : always_compare_proc
    
endmodule : file_compare

`default_nettype wire
