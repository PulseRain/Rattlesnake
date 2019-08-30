//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Thu Aug 29 21:03:26 2019
// Version: v12.1 12.600.0.14
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// FCCC_C0
module FCCC_C0(
    // Inputs
    CLK0_PAD,
    // Outputs
    GL0,
    LOCK
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  CLK0_PAD;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output GL0;
output LOCK;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   CLK0_PAD;
wire   GL0_net_0;
wire   LOCK_net_0;
wire   GL0_net_1;
wire   LOCK_net_1;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire   GND_net;
wire   [7:2]PADDR_const_net_0;
wire   [7:0]PWDATA_const_net_0;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign GND_net            = 1'b0;
assign PADDR_const_net_0  = 6'h00;
assign PWDATA_const_net_0 = 8'h00;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign GL0_net_1  = GL0_net_0;
assign GL0        = GL0_net_1;
assign LOCK_net_1 = LOCK_net_0;
assign LOCK       = LOCK_net_1;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------FCCC_C0_FCCC_C0_0_FCCC   -   Actel:SgCore:FCCC:2.0.201
FCCC_C0_FCCC_C0_0_FCCC FCCC_C0_0(
        // Inputs
        .CLK0_PAD ( CLK0_PAD ),
        // Outputs
        .GL0      ( GL0_net_0 ),
        .LOCK     ( LOCK_net_0 ) 
        );


endmodule
