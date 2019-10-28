// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Sat Oct 19 15:22:35 2019
// Host        : think running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/GitHub/Rattlesnake/build/par/Xilinx/Digilent_A7_100T/Digilent_A7_100T.srcs/ip/ila_uart/ila_uart_stub.v
// Design      : ila_uart
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100ticsg324-1L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2019.1" *)
module ila_uart(clk, probe0)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[63:0]" */;
  input clk;
  input [63:0]probe0;
endmodule
