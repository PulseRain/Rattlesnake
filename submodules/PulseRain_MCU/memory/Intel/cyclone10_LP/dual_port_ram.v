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

module dual_port_ram #(parameter ADDR_WIDTH = 5, DATA_WIDTH = 32) (
          input wire [ADDR_WIDTH - 1 : 0]       waddr, 
          input wire [ADDR_WIDTH - 1 : 0]       raddr,
          
          input wire [DATA_WIDTH - 1 : 0]       din,
          input wire                            write_en, 
          input wire                            clk, 
          output reg [DATA_WIDTH - 1 : 0]       dout
);

    //    reg [ADDR_WIDTH - 1 : 0] raddr_reg;
        reg [DATA_WIDTH - 1 : 0] mem [(2**ADDR_WIDTH) - 1 : 0] /* synthesis syn_ramstyle="M9K" */;

    //    assign dout = mem[raddr_reg] ;
        
    //    always @(posedge rclk) begin
    //        raddr_reg <= raddr;
    //    end
        
        always @(posedge clk) begin
            if (write_en) begin
                mem[waddr] <= din;
            end
            
            dout <= mem[raddr] ;
        end
        
        initial begin
            mem[2] = 32'h807FFFF8;
        end
        

endmodule

`default_nettype wire