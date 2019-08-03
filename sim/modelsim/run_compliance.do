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

###############################################################################
# list for test vectors
###############################################################################

array set Test_Vector_Path {
    0  "TV/i_add"
    1  "TV/i_addi"
    2  "TV/i_and"
    3  "TV/i_andi"
    4  "TV/i_auipc"
    5  "TV/i_beq"
    6  "TV/i_bge"
    7  "TV/i_bgeu"
    8  "TV/i_blt"
    9  "TV/i_bltu"
    10 "TV/i_bne"
    11 "TV/i_csrrc"
    12 "TV/i_csrrci"
    13 "TV/i_csrrs"
    14 "TV/i_csrrsi"
    15 "TV/i_csrrw"
    16 "TV/i_csrrwi"
    17 "TV/i_delay_slots"
    18 "TV/i_ebreak"
    19 "TV/i_ecall"
    20 "TV/i_endianess"
    21 "TV/i_fence"
    22 "TV/i_io"
    23 "TV/i_jal"
    24 "TV/i_jalr"
    25 "TV/i_lb"
    26 "TV/i_lbu"
    27 "TV/i_lh"
    28 "TV/i_lhu"
    29 "TV/i_lui"
    30 "TV/i_lw"
    31 "TV/i_misalign_jmp"
    32 "TV/i_misalign_ldst"
    33 "TV/i_nop"
    34 "TV/i_or"
    35 "TV/i_ori"
    36 "TV/i_rf_size"
    37 "TV/i_rf_width"
    38 "TV/i_rf_x0"
    39 "TV/i_sb"
    40 "TV/i_sh"
    41 "TV/i_sll"
    42 "TV/i_slli"
    43 "TV/i_slt"
    44 "TV/i_slti"
    45 "TV/i_sltiu"
    46 "TV/i_sltu"
    47 "TV/i_sra"
    48 "TV/i_srai"
    49 "TV/i_srl"
    50 "TV/i_srli"
    51 "TV/i_sub"
    52 "TV/i_sw"
    53 "TV/i_xor"
    54 "TV/i_xori"
 
      
};list


###############################################################################
# test main body
###############################################################################

set Num_Tests [array size Test_Vector_Path];list

for {set i 0} {$i < $Num_Tests} {incr i 1} { 
    puts "\n=================> Test Vector $i: $Test_Vector_Path($i) started!"
    file copy -force "$Test_Vector_Path($i).dat" sdram_ISSI_SDRAM_test_component.dat
    file copy -force "$Test_Vector_Path($i).v" ../../submodules/PulseRain_MCU/memory/sim/single_port_ram_sim.v
    eval [vlog ../../submodules/PulseRain_MCU/memory/sim/single_port_ram_sim.v ]
    eval [vsim -t ps -novopt tb_RV -gTV="$Test_Vector_Path($i).tv" -L work -L work_lib -L rst_controller \
           -L ISSI_SDRAM -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclone10lp_ver]
          
    set StdArithNoWarnings 1;list
    set NumericStdNoWarnings 1;list
    
    onbreak {pause}
    add log -r sim:/*
    
    run -all
    
    puts "=================> Test Vector $i : $Test_Vector_Path($i) finished!"
    
    quit -sim

}
    
puts "==================> test all done! Total $Num_Tests cases."
