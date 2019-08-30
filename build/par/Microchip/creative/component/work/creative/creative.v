//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Thu Aug 29 21:03:32 2019
// Version: v12.1 12.600.0.14
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// creative
module creative(
    // Inputs
    RXD,
    osc_in,
    // Outputs
    LED_GREEN,
    LED_RED,
    TXD
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  RXD;
input  osc_in;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output LED_GREEN;
output LED_RED;
output TXD;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   FCCC_C0_0_GL0;
wire   FCCC_C0_0_LOCK;
wire   LED_GREEN_net_0;
wire   LED_RED_net_0;
wire   osc_in;
wire   RXD;
wire   TXD_net_0;
wire   LED_GREEN_net_1;
wire   LED_RED_net_1;
wire   TXD_net_1;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign LED_GREEN_net_1 = LED_GREEN_net_0;
assign LED_GREEN       = LED_GREEN_net_1;
assign LED_RED_net_1   = LED_RED_net_0;
assign LED_RED         = LED_RED_net_1;
assign TXD_net_1       = TXD_net_0;
assign TXD             = TXD_net_1;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------FCCC_C0
FCCC_C0 FCCC_C0_0(
        // Inputs
        .CLK0_PAD ( osc_in ),
        // Outputs
        .GL0      ( FCCC_C0_0_GL0 ),
        .LOCK     ( FCCC_C0_0_LOCK ) 
        );

//--------Rattlesnake
Rattlesnake Rattlesnake_0(
        // Inputs
        .clk              ( FCCC_C0_0_GL0 ),
        .reset_n          ( FCCC_C0_0_LOCK ),
        .RXD              ( RXD ),
        // Outputs
        .TXD              ( TXD_net_0 ),
        .processor_active ( LED_GREEN_net_0 ),
        .processor_paused ( LED_RED_net_0 ) 
        );


endmodule
