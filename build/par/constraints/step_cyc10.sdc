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

#############################################################################################################################
# Base clocks
#############################################################################################################################

create_clock -name {clk_50mhz_fpga}         -period  50.000MHz    [get_ports {osc_in}]

#############################################################################################################################
# Generated clocks
#############################################################################################################################

derive_pll_clocks -create_base_clocks -use_net_name
derive_clock_uncertainty


#############################################################################################################################
# Asynchronous groups & False paths
#############################################################################################################################

set_clock_groups \
    -group {clk_50mhz_fpga} \
    -asynchronous

#############################################################################################################################
# Set False Path
#############################################################################################################################


#############################################################################################################################
# SDRAM IS42S16400J-7BL, CAS=3
#############################################################################################################################
#jitter margin = 0.05
# http://limerick.pulserain.com/2016/08/sdc-constraint-input-output-delay.html

######################################################################
# tcms = 1.5,  Command Setup Time (CS, RAS, CAS, WE, DQM)
# tcmh = 0.8,  Command Hold Time (CS, RAS, CAS, WE, DQM)
#
# tas = 1.5, Address Setup Time
# tah = 0.8  Address Hold Time
#
# tcks = 1.5, CKE Setup Time
# tckh = 0.8, CKE Hold Time
#
# tds = 1.5,  Input Data Setup Time 
# tdh = 0.8,  Input Data Hold Time
#
######################################################################

set_output_delay -clock [get_clocks {PLL:pll_i|altpll:altpll_component|PLL_altpll:auto_generated|wire_pll1_clk[1]}] \
        -max 1.55 -reference_pin [get_ports SDRAM_CLK] \
        [get_ports {SDRAM_CS_N SDRAM_RAS_N SDRAM_CAS_N SDRAM_WE_N SDRAM_DQM[*] SDRAM_ADDR[*] SDRAM_CKE SDRAM_BA[*] SDRAM_DQ[*]}]

set_output_delay -clock [get_clocks {PLL:pll_i|altpll:altpll_component|PLL_altpll:auto_generated|wire_pll1_clk[1]}] \
        -min -0.85 -reference_pin [get_ports SDRAM_CLK] \
        [get_ports {SDRAM_CS_N SDRAM_RAS_N SDRAM_CAS_N SDRAM_WE_N SDRAM_DQM[*] SDRAM_ADDR[*] SDRAM_CKE SDRAM_BA[*] SDRAM_DQ[*]}]
       

######################################################################       
# tac3 = 5.4 Access Time
# t_setup = clk - tac3 = 10 - 5.4 = 4.6
# tOH3 = 2.7 Output Data Hold Time 
######################################################################

set_input_delay -clock [get_clocks {PLL:pll_i|altpll:altpll_component|PLL_altpll:auto_generated|wire_pll1_clk[1]}] \
        -max 5.45 -reference_pin [get_ports SDRAM_CLK] \
        [get_ports {SDRAM_DQ[*]}]

set_input_delay -clock [get_clocks {PLL:pll_i|altpll:altpll_component|PLL_altpll:auto_generated|wire_pll1_clk[1]}] \
        -min 2.65 -reference_pin [get_ports SDRAM_CLK] \
        [get_ports {SDRAM_DQ[*]}]

        
######################################################################
#   CAS Latency = 3        
######################################################################

set_multicycle_path -from {SDRAM_DQ[*]} -to {sdram:sdram_i|sdram_ISSI_SDRAM:issi_sdram|za_data[*]} -setup -end 3
set_multicycle_path -from {SDRAM_DQ[*]} -to {sdram:sdram_i|sdram_ISSI_SDRAM:issi_sdram|za_data[*]} -hold -end 2
