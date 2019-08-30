set_family {IGLOO2}
read_adl {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.adl}
read_afl {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.afl}
map_netlist
read_sdc {C:\GitHub\Rattlesnake\build\par\constraints\Microchip\creative\Rattlesnake.sdc}
check_constraints {C:\GitHub\Rattlesnake\build\par\Microchip\creative\constraint\placer_sdc_errors.log}
write_sdc -strict -afl {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\place_route.sdc}
