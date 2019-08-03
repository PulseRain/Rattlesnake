#!/usr/bin/python3
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

import os, sys, getopt
import math, time

from time import sleep
from CRC16_CCITT import CRC16_CCITT
from PRBS import PRBS

from ROM_Hex_Format import *

import serial

from pathlib import Path

import ctypes

import subprocess
import re

            
    
#==============================================================================
# main            
#==============================================================================

if __name__ == "__main__":

    hex_file = sys.argv[1]
    
    intel_hex_file =  Intel_Hex(hex_file)
        
    data_list_to_write = []
    addr = 0
        
    count = 0
    for record in intel_hex_file.data_record_list:
        #print ("=================================== ", [hex(k) for k in  record.data_list])
        
        if (len(data_list_to_write) == 0):
            data_list_to_write = record.data_list
            addr = record.address
        elif (((addr + len(data_list_to_write)) == record.address) and (len(data_list_to_write) < 8192)):
            data_list_to_write = data_list_to_write + record.data_list
            
            count = count + 1
            
            
        else:
            if (len(data_list_to_write) % 4):
                data_list_to_write = data_list_to_write + [0] * (len(data_list_to_write) % 4)
            
            #print ("+++++++++++++++++++ ", [hex(k) for k in  data_list_to_write])
            data_list_to_write_reorder = [0] * len(data_list_to_write)
            for i in range (len(data_list_to_write) // 4):
                value = data_list_to_write [i * 4 + 0] + (data_list_to_write [i * 4 + 1] << 8) + (data_list_to_write [i * 4 + 2] << 16) + (data_list_to_write [i * 4 + 3] << 24)
                
                print ("rom_mem[%d] <= 32\'h%08x;" % ((addr + (i * 4) - 0x80000000)/4, value))
                                
            data_list_to_write = record.data_list
            addr = record.address
    