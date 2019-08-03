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

module mul_div_32(
      
//=======  clock and reset ======
        input  wire                              clk,
        input  wire                              reset_n,
//========== INPUT ==========

        input  wire                              enable_in,
        
        input  wire signed [31 : 0]              x,
        input  wire signed [31 : 0]              y,
        
        input  wire                              mul0_div1,
        input  wire                              x_signed0_unsigned1,
        input  wire                              y_signed0_unsigned1,
        
//========== OUTPUT ==========
        output wire                              enable_out,
        output reg [63 : 0]                      z,
        
        output wire [31 : 0]                     q,
        output wire [31 : 0]                     r,
        
        output wire                              ov
);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire signed [31 : 0]        x_abs;
        wire signed [31 : 0]        y_abs;
        
        reg [31 : 0]                x_mul;
        reg [31 : 0]                y_mul;
        
        
        wire                        x_max_neg_flag;
        
        reg                         enable_in_d1;
        reg                         enable_in_d2;
        reg                         enable_in_d3;
        
        
        reg                         mul0_div1_reg;
        
        wire                        div_enable_out;
        
        reg [63 : 0]                z_i;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // mul
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        assign x_max_neg_flag = x[31] & (~(|x[30 : 0]));
       
        absolute_value #(.DATA_WIDTH (32)) abs_x_i (
            
            .data_in (x),
            .data_out (x_abs));

        absolute_value #(.DATA_WIDTH (32)) abs_y_i (
            
            .data_in (y),
            .data_out (y_abs));

        
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                x_mul <= 0;
                y_mul <= 0;
            
                z <= 0;
                z_i <= 0;
                mul0_div1_reg <= 0;
                
                enable_in_d1 <= 0;
                enable_in_d2 <= 0;
                enable_in_d3 <= 0;
                
            end else begin
                enable_in_d1 <= enable_in;
                enable_in_d2 <= enable_in_d1;
                enable_in_d3 <= enable_in_d2;
                
                if (enable_in) begin
                    if (!x_signed0_unsigned1) begin
                        x_mul <= x_abs;
                    end else begin
                        x_mul <= x;
                    end
                    
                    if (!y_signed0_unsigned1) begin
                        y_mul <= y_abs;
                    end else begin
                        y_mul <= y;
                    end

                    
                    mul0_div1_reg <= mul0_div1;
                    
                end
                
                z_i <= x_mul * y_mul;
                z <= z_i;
                
            end    
        end
    
        assign enable_out = mul0_div1_reg ? div_enable_out : enable_in_d3;

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // div
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   /*     SRT_Radix4_division32 SRT_Radix4_division32_i (
            .clk     (clk),
            .reset_n (reset_n),
            
            .enable_in (enable_in),
            .dividend  (x),
            .divisor   (y),
            
            .ov_flag  (ov),
            .quotient (q),
            .enable_out (div_enable_out));         
*/
          long_slow_div_denom_reg #(.DATA_WIDTH (32)) long_slow_div_denom_reg_i (
              .clk (clk),
              .reset_n (reset_n),
              
              .enable_in (enable_in_d1 & mul0_div1_reg),
              .numerator   (x_mul),
              .denominator (y_mul),
        
              .enable_out (div_enable_out),
              .quotient   (q),
              .remainder  (r),
              .div_by_zero (),
              .error (ov)
            );  

endmodule

`default_nettype wire
