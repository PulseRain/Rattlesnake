set_family {IGLOO2}
read_verilog -mode verilog_2k {C:\GitHub\Rattlesnake\build\par\Microchip\creative\component\work\creative\creative.v}
read_verilog -mode verilog_2k {C:\GitHub\Rattlesnake\build\par\Microchip\creative\component\work\FCCC_C0\FCCC_C0.v}
read_verilog -mode verilog_2k {C:\GitHub\Rattlesnake\build\par\Microchip\creative\component\work\FCCC_C0\FCCC_C0_0\FCCC_C0_FCCC_C0_0_FCCC.v}
read_verilog -mode verilog_2k {C:\GitHub\Rattlesnake\build\synth\Microchip\IGLOO2\Rattlesnake.vm}
set_top_level {creative}
map_netlist
read_sdc {C:\GitHub\Rattlesnake\build\par\constraints\Microchip\creative\Rattlesnake.sdc}
check_constraints {C:\GitHub\Rattlesnake\build\par\Microchip\creative\constraint\synthesis_sdc_check.log}
