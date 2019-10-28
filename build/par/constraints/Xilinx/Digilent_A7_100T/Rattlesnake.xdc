

##################################################################################################
# Timing Constraint
##################################################################################################


create_clock -period 10.000 [get_ports OSC_IN]











##################################################################################################
# IO Constraint
##################################################################################################


set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports OSC_IN]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports CK_RST]


set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports BTN0]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports BTN1]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports BTN2]
set_property -dict {PACKAGE_PIN B8 IOSTANDARD LVCMOS33} [get_ports BTN3]

set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports SW0]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports SW1]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports SW2]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports SW3]

set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports LD0_RED]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports LD0_GREEN]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports LD0_BLUE]

set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports LD1_RED]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports LD1_GREEN]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports LD1_BLUE]

set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports LD2_RED]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports LD2_GREEN]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports LD2_BLUE]

set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports LD3_RED]
set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports LD3_GREEN]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports LD3_BLUE]

set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports LD4]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports LD5]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports LD6]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports LD7]

set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports TXD]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports RXD]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
