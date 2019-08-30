read_sdc -scenario "timing_analysis" -netlist "optimized" -pin_separator "/" -ignore_errors {C:/GitHub/Rattlesnake/build/par/Microchip/creative/designer/creative/timing_analysis.sdc}
set_options -analysis_scenario "timing_analysis" 
save
