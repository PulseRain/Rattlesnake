set_device \
    -family  IGLOO2 \
    -die     PA4MGL2500_N \
    -package vf256 \
    -speed   STD \
    -tempr   {COM} \
    -voltr   {COM}
set_def {VOLTAGE} {1.2}
set_def {VCCI_1.2_VOLTR} {COM}
set_def {VCCI_1.5_VOLTR} {COM}
set_def {VCCI_1.8_VOLTR} {COM}
set_def {VCCI_2.5_VOLTR} {COM}
set_def {VCCI_3.3_VOLTR} {COM}
set_def {PLL_SUPPLY} {PLL_SUPPLY_33}
set_def {VPP_SUPPLY_25_33} {VPP_SUPPLY_25}
set_def {PA4_URAM_FF_CONFIG} {SUSPEND}
set_def {PA4_SRAM_FF_CONFIG} {SUSPEND}
set_def {PA4_MSS_FF_CLOCK} {RCOSC_1MHZ}
set_def USE_CONSTRAINTS_FLOW 1
set_netlist -afl {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.afl} -adl {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.adl}
set_placement   {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.loc}
set_routing     {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.seg}
set_sdcfilelist -sdc {C:\GitHub\Rattlesnake\build\par\constraints\Microchip\creative\Rattlesnake.sdc}
