read_sdc -scenario "place_and_route" -netlist "optimized" -pin_separator "/" -ignore_errors {C:/GitHub/Rattlesnake/build/par/Microchip/creative/designer/creative/place_route.sdc}
set_options -tdpr_scenario "place_and_route" 
save
set_options -analysis_scenario "place_and_route"
report -type combinational_loops -format xml {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative_layout_combinational_loops.xml}
report -type slack {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\pinslacks.txt}
set coverage [report \
    -type     constraints_coverage \
    -format   xml \
    -slacks   no \
    {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative_place_and_route_constraint_coverage.xml}]
set reportfile {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\coverage_placeandroute}
set fp [open $reportfile w]
puts $fp $coverage
close $fp