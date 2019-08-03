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

module absolute_value #(parameter DATA_WIDTH=32)(
      
//========== INPUT ==========

        input  wire signed [DATA_WIDTH - 1 : 0]  data_in,
            
        
//========== OUTPUT ==========
        output wire  signed [DATA_WIDTH - 1 : 0] data_out
        
//========== IN/OUT ==========
);
    wire signed [DATA_WIDTH - 1 : 0]    data_sign_ext, data_tmp;
    wire signed [DATA_WIDTH - 1 : 0]    abs_value;
    
    assign data_sign_ext = {(DATA_WIDTH){data_in[DATA_WIDTH - 1]}};
    assign data_tmp      = data_in ^ data_sign_ext;
    assign abs_value     = data_tmp - data_sign_ext;
    
    assign data_out = abs_value;
    
endmodule

`default_nettype wire
