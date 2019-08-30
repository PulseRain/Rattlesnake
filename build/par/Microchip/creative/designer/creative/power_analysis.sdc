create_clock -name {osc_in} -period 20 [ get_ports { osc_in } ]
create_generated_clock -name {FCCC_C0_0/FCCC_C0_0/GL0} -multiply_by 120 -divide_by 50 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ]

set_false_path -from [get_ports RXD]

