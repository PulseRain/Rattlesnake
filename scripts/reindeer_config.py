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

            
class Reindeer_OCD:

    _OCD_DEBUG_SYNC = [0x5A, 0xA5, 0x01]
    _OCD_DEBUG_TYPE_PRAM_WRITE_4_BYTES_WITHOUT_ACK = 0x5C
    _OCD_DEBUG_TYPE_PRAM_WRITE_4_BYTES_WITH_ACK    = 0x5C | 1
    _OCD_DEBUG_TYPE_PRAM_WRITE_128_BYTES_WITH_ACK  = 0x5B
    
    _OCD_DEBUG_TYPE_PRAM_READ_4_BYTES  = 0x6D
    _OCD_DEBUG_TYPE_CPU_RESET_WITH_ACK = 0x4B
    
    _OCD_DEBUG_TYPE_PAUSE_ON_WITH_ACK  = 0x2D
    _OCD_DEBUG_TYPE_PAUSE_OFF_WITH_ACK = 0x3D
    
    _OCD_DEBUG_TYPE_READ_CPU_STATUS    = 0x2F
    
    _OCD_DEBUG_TYPE_COUNTER_CONFIG     = 0x6B
    
    _OCD_DEBUG_TYPE_BREAK_ON_WITH_ACK  = 0x7D
    _OCD_DEBUG_TYPE_BREAK_OFF_WITH_ACK = 0x1D
    
    _OCD_DEBUG_TYPE_RUN_PULSE_WITH_ACK = 0x49
    
    _OCD_DEBUG_TYPE_READ_DATA_MEM      = 0x6F; 
    _OCD_DEBUG_TYPE_WRITE_DATA_MEM     = 0x2B; 
    _OCD_DEBUG_TYPE_WRITE_DATA_MEM     = 0x2B; 
    _OCD_DEBUG_TYPE_UART_SEL           = 0x2A;
    
    _OCD_DEBUG_FRAME_REPLY_LEN = 13
    _OCD_SERIAL_TIME_OUT = 6
    
    _CONFIG_SYNC = [0x5A, 0xA5, 0x01]
    _CONFIG_TYPE_PRAM_WRITE_4_BYTES_WITHOUT_ACK = 0x5C
    _CONFIG_TYPE_PRAM_WRITE_4_BYTES_WITH_ACK    = 0x5C | 1
    _CONFIG_TYPE_PRAM_WRITE_128_BYTES_WITH_ACK  = 0x5B
    
    _crc16_ccitt = CRC16_CCITT()
    
    _toggle = 0
    
    #========================================================================
    #  _verify_crc
    #------------------------------------------------------------------------
    #  Remarks: calculate and check CRC16_CCITT for frames 
    #========================================================================
    def _verify_crc (self, data):
        data_list = [i for i in data]
        crc_data = Reindeer_OCD._crc16_ccitt.get_crc (data_list [0 : Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN - 2])
     
        if (crc_data == data_list [Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN - 2 : Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN]):
            return True
        else:
            return False

    #========================================================================
    #  uart_select
    #========================================================================
    def uart_select (self, ocd1_cpu0):
    
        frame_type_byte = Reindeer_OCD._OCD_DEBUG_TYPE_UART_SEL * 2 + Reindeer_OCD._toggle;
        Reindeer_OCD._toggle = 1 - Reindeer_OCD._toggle
            
        frame = Reindeer_OCD._OCD_DEBUG_SYNC + [frame_type_byte] + [0x99, 0x12, 0x34, 0xab, 0xcd, 0xab, ocd1_cpu0*2]
        frame = frame + Reindeer_OCD._crc16_ccitt.get_crc (frame)
        
        sleep(0.5)
        if (self._serial.in_waiting):
            r = self._serial.read (self._serial.in_waiting)  
      
        if (self._verbose):
            print ("send: ", [hex(i) for i in frame])
            
        self._serial.write (frame)
        
        
    
    #========================================================================
    #  cpu_reset
    #========================================================================
    def cpu_reset (self, show_crc_error=0):
    
        condition = True
        while (condition):
            frame_type_byte = Reindeer_OCD._OCD_DEBUG_TYPE_CPU_RESET_WITH_ACK * 2 + Reindeer_OCD._toggle;
            Reindeer_OCD._toggle = 1 - Reindeer_OCD._toggle
            
            frame = Reindeer_OCD._OCD_DEBUG_SYNC + [frame_type_byte] + [0x88, 0x12, 0x34, 0xab, 0xcd, 0xab, 0xcd]
            frame = frame + Reindeer_OCD._crc16_ccitt.get_crc (frame)
            
            if (self._verbose):
                print ("send: ", [hex(i) for i in frame])
   
            self._serial.write (frame)
            ret = self._serial.read (Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN)
     
            condition = not self._verify_crc (ret)
            if (condition):
                if (show_crc_error):
                    print ("cpu reset reply CRC fail")
    
        if (self._verbose):
            print ("receive: ", [hex(i) for i in ret])
    
    #========================================================================
    #  mem_read_32bit
    #========================================================================
    def mem_read_32bit (self, addr, show_crc_error=0):
        
        addr_write_low_byte  = addr & 0xFF
        addr_write_high_byte = (addr >> 8) & 0xFF
        addr_write_high_high_byte = (addr >> 16) & 0xFF
        
        condition = True
        
        #print ("read32bit, addr = ", addr)
        
        while (condition):
        
            frame_type_byte = Reindeer_OCD._OCD_DEBUG_TYPE_PRAM_READ_4_BYTES * 2 + Reindeer_OCD._toggle;
            Reindeer_OCD._toggle = 1 - Reindeer_OCD._toggle
            
            frame = Reindeer_OCD._OCD_DEBUG_SYNC + [frame_type_byte] + [addr_write_high_high_byte, addr_write_high_byte, addr_write_low_byte]
            
            fill_data = 0x00FF00FF
            for i in range(4):
                frame.append ((fill_data >> 24) & 0xFF)
                fill_data = fill_data << 8
            frame = frame + Reindeer_OCD._crc16_ccitt.get_crc (frame)
            
            if (self._verbose):
                print ("Asend: ", [hex(i) for i in frame])
            self._serial.write (frame)
            ret = self._serial.read (Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN)
            
            condition = not self._verify_crc (ret)
            if (condition):
                if (show_crc_error):
                    print ("addr=", addr, "\nread 32bit reply CRC failed, Retry!")
                                
        if (self._verbose):
            print ("receive: ", [hex(i) for i in ret])
            print ("====> ", [hex(i) for i in ret[Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN - 6 : Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN - 2]])
        
        
        return [i for i in ret[Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN - 6 : Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN - 2]]
        
    #========================================================================
    #  mem_read
    #========================================================================
    def mem_read (self, addr, length, show_crc_error=0):
    
        for i in range (length // 4):
            ret = self.mem_read_32bit (addr)
            print ("====> %08x %08x" % (addr, (ret[0] << 24) + (ret[1] << 16) +  (ret[2] << 8) + ret[3]))   
        
            addr = addr + 4
            
            
            
    #========================================================================
    #  mem_zero_fill_frame
    #========================================================================
    def mem_zero_fill_frame (self):
        frame = [0xFF, 0x00] * 64
        self._serial.write (frame)
    
    #========================================================================
    #  mem_write_32bit
    #========================================================================
    def mem_write_32bit (self, addr, data, ack=1, show_crc_error=0):
        addr_write_low_byte  = addr & 0xFF
        addr_write_high_byte = (addr >> 8) & 0xFF
        addr_write_high_high_byte = (addr >> 16) & 0xFF
        
        #print ("wr32bit, addr = 0x%x" % addr)
        
        condition = True
        
        while (condition):
            data_in = data
            if (ack):
                frame_type_byte = Reindeer_OCD._CONFIG_TYPE_PRAM_WRITE_4_BYTES_WITH_ACK * 2 + Reindeer_OCD._toggle
            else:
                frame_type_byte = Reindeer_OCD._CONFIG_TYPE_PRAM_WRITE_4_BYTES_WITHOUT_ACK * 2 + Reindeer_OCD._toggle
            
            Reindeer_OCD._toggle = 1 - Reindeer_OCD._toggle
            
            frame = Reindeer_OCD._CONFIG_SYNC + [frame_type_byte] + [addr_write_high_high_byte, addr_write_high_byte, addr_write_low_byte]
            
            for i in range(4):
                frame.append ((data_in >> 24) & 0xFF)
                data_in = data_in << 8
            
            frame = frame + self._crc16_ccitt.get_crc (frame)
            self._serial.write (frame)
            
            if (self._verbose):
                print ("Ysend: ", [hex(i) for i in frame])
            
            if (ack):
                ret = self._serial.read (Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN)
                condition = not self._verify_crc (ret)
                if (condition):
                    if (show_crc_error):
                        print ("\naddr=", addr, "Write 32bit reply CRC failed, Retry!")
                    self.mem_zero_fill_frame()
            else:
                condition = False    


    #========================================================================
    #  mem_write_128byte
    #========================================================================
    def mem_write_128byte (self, addr, data_list, show_crc_error=0):
    
        addr_write_low_byte  = addr & 0xFF
        addr_write_high_byte = (addr >> 8) & 0xFF
        addr_write_high_high_byte = (addr >> 16) & 0xFF
        
        condition = True
        #print ("wr128, addr = ", addr)
        
        while (condition):
            frame_type_byte = Reindeer_OCD._CONFIG_TYPE_PRAM_WRITE_128_BYTES_WITH_ACK * 2 + Reindeer_OCD._toggle
            Reindeer_OCD._toggle = 1 - Reindeer_OCD._toggle
            
            frame = Reindeer_OCD._OCD_DEBUG_SYNC + [frame_type_byte] + [addr_write_high_high_byte, addr_write_high_byte, addr_write_low_byte]
            frame = frame + (data_list [0:4])
            frame = frame + self._crc16_ccitt.get_crc (frame)
            frame = frame + data_list [4 : 128] + self._crc16_ccitt.get_crc (data_list [4 : 128])
            
            self._serial.write (frame)
            
            
            if (self._verbose):
                print ("Xsend: ", [hex(i) for i in frame])
            
            ret = self._serial.read (Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN)

            condition = not self._verify_crc (ret)
            if (condition):
                if (show_crc_error):
                    print ("\naddr=", addr, "Write 128byte reply CRC failed, Retry!")
                self.mem_zero_fill_frame()
            
    
    def _write_mem (self, addr, data):
        offset = 0
        length = len (data)
        addr_end = addr + length
        
        # assume it is always aligned to 32 bit boundary
        
        total_words = (addr_end - addr - offset) // 4
        total_128byte_frame = total_words //32
        
        for i in range (total_128byte_frame):
            #print ("write128 %x" % (addr + offset), [hex(k) for k in data[offset : offset + 128]])
            self.mem_write_128byte (addr + offset, data[offset : offset + 128])
            offset = offset + 128
            
        
        for i in range (total_words - total_128byte_frame * 32):
            data_int = (data[offset] << 24) + \
                       (data[offset + 1] << 16) + \
                       (data[offset + 2] << 8) + \
                       (data[offset + 3])
            
            #print ("write32bit addr = ", addr + offset, "data_int=", hex(data_int))            
            self.mem_write_32bit(addr + offset, data_int)
            offset = offset + 4
        
    
    #========================================================================
    #  load section
    #========================================================================
        
    def _load_section (self, all_sections, section_name, data_list, data_length):
        section_head = re.compile ("^Contents\sof\ssection\s([\.|\w]*)")
        data_regexp = re.compile ("^(\w*)\s(\w*)\s(\w*)\s(\w*)\s(\w*)")

        #print ("-------------- section_name = ", section_name, " data_length = ", data_length)
        
        data_capture = 0
        data_cnt = 0
        for line in all_sections:
            line_strip = line.strip()
            head_match = re.search (section_head, line_strip)
            data_match = re.search (data_regexp, line_strip)
        
                                
            if (head_match):
                data_capture = 0
                if (section_name == head_match.group(1)):
                    data_capture = 1
            
            elif (data_capture):
                if (data_match):
                    addr = int(data_match.group(1), 16)
                    #print ("-- %x " % addr)
            
                    for i in range(4):
                        if (data_match.group(i + 2) != ""):
                            data_val = int(data_match.group(i + 2), 16)
                            #print ("i = ", i, "data_val = %x" % data_val)
                            
                            for j in range(4):
                                
                                byte = (data_val >> ((3 - j) * 8)) & 0xFF
                                data_list += byte.to_bytes(1, byteorder="little")
                                data_cnt = data_cnt + 1
                                #print ("%x" % byte)
                                if (data_cnt == data_length):
                                    return
    #========================================================================
    #  load elf
    #========================================================================
    def load_elf (self, elf_file):
    
        sections_lines = subprocess.run([self.objdump, '-h', elf_file], stdout=subprocess.PIPE).stdout.decode('utf-8').splitlines()
        all_sections = subprocess.run([self.objdump, '-s', elf_file], stdout=subprocess.PIPE).stdout.decode('utf-8').splitlines()

        section_regexp = re.compile ("^\s*\d*\s([\.|\-|\w]*)\s*(\w*)\s*(\w*)\s*(\w*)")
        section_list = []
        section_property_list = []

        capture_next = 0
            
        for line in sections_lines:
            line_strip = line.strip()
            match = re.search (section_regexp, line_strip)
            #print (line_strip)

            if (capture_next):
                section_property_list.append(line_strip.split(", "))

            capture_next = 0
            if (match):
                capture_next = 1
                #print (line_strip)
                section_name = match.group(1)
                section_size = int(match.group(2), 16)
                section_vma =  int(match.group(3), 16)
                section_lma = int(match.group(4), 16)

                #print (section_name, section_size, section_vma, section_lma)
                section_list.append ([section_name, section_size, section_vma, section_lma])
        
        #############################################################################
        # load sections that have CODE or DATA property
        #############################################################################

        data_list = bytearray()
        addr_list = []
        size_list = []
        name_list = []

        total_sections = 0
        
        for section_name, section_size, section_vma, section_lma in section_list:
            
            ###bin_file = os.path.splitext(elf_file)[0] + section_name + '.bin'
            #print (bin_file)
            
            ###if (Path(bin_file).exists()):
            ###    os.remove(bin_file)
        
            
            ###with open(os.devnull, 'w')  as FNULL:       
            ###    subprocess.run([self.objcopy, '--dump-section', section_name + '=' + bin_file, elf_file], stdout=FNULL, stderr=FNULL )
                                
            if ('LOAD' in section_property_list[total_sections]):
                ###try:
                
                name_list.append(section_name)
                    
                    ###f = open(bin_file, 'rb')
                    ####byte = f.read(1)
                addr = section_lma
                addr_list.append (section_lma)
                size_list.append(section_size)
                    
                    ###while byte:
                    ###    data_list += byte
                    ###    addr = addr + 1
                    ###    byte = f.read(1)
                        
                    ###assert ((addr -  section_lma) ==  section_size)
                    
                self._load_section (all_sections, section_name, data_list, section_size) 
                                
                ####except IOError:
                ####    print ("Fail to open: ", self.file_name)
                ####    exit(1)

                ###f.close()
                total_sections = total_sections + 1

        
        
        byte_index = 0
        for i in range(total_sections):
            count = 0
            addr = addr_list[i]
            
            print (" ")
            print ("//================================================================")
            print ("//== Section ", name_list[i])
            print ("//================================================================")
            
            start_byte_index = byte_index
            for j in range (size_list[i]):
                
                if (count == 0):
                    data = 0
            
                data = data + (data_list[byte_index] << (count * 8))
                count = (count + 1) % 4
                byte_index = byte_index + 1
            
                if (count == 0):
                    #data = ((data & 0xFF) << 24) + (((data >> 8 )& 0xFF) << 16) + (((data >> 16 )& 0xFF) << 8) + (((data >> 24 )& 0xFF) << 0)  
                    # print ("    mem[%d] <= 32\'h%04x; // 0x%x" % (addr , data, addr))
                    addr = addr + 4
        
            print ("\taddr = 0x%08x, length = %d (0x%x)" % (addr_list[i], byte_index - start_byte_index, byte_index - start_byte_index))
            
            data_list_to_write = []
            for k in range (math.ceil(len(data_list[start_byte_index : byte_index]) / 4)):
                data_list_to_write = data_list_to_write + [data_list[start_byte_index + k * 4 + 3], data_list[start_byte_index + k * 4 + 2], data_list[start_byte_index + k * 4 + 1], data_list[start_byte_index + k * 4]] 
                
            self._write_mem (addr_list[i], data_list_to_write)
    
    #========================================================================
    #  load hex
    #========================================================================
    def load_hex (self, hex_file):
    
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
                #print ("----------------------------- ", [hex(k) for k in  data_list_to_write])
                count = count + 1
                #print ("%x, %x" % (addr, record.address))
                if ((count % 512) == 0):
                    print ("#", end="")
                    sys.stdout.flush()
            else:
                if (len(data_list_to_write) % 4):
                    data_list_to_write = data_list_to_write + [0] * (len(data_list_to_write) % 4)
                
                #print ("+++++++++++++++++++ ", [hex(k) for k in  data_list_to_write])
                data_list_to_write_reorder = [0] * len(data_list_to_write)
                for i in range (len(data_list_to_write) // 4):
                    data_list_to_write_reorder [i * 4]     = data_list_to_write [i * 4 + 3]
                    data_list_to_write_reorder [i * 4 + 1] = data_list_to_write [i * 4 + 2]
                    data_list_to_write_reorder [i * 4 + 2] = data_list_to_write [i * 4 + 1]
                    data_list_to_write_reorder [i * 4 + 3] = data_list_to_write [i * 4]
                    
                    
                    
                #print ("==> %x " % addr, [hex(k) for k in data_list_to_write_reorder])
                self._write_mem (addr, data_list_to_write_reorder)
                data_list_to_write = record.data_list
                addr = record.address
        
        return intel_hex_file.entry_addr
        
    #========================================================================
    #  start to run
    #========================================================================
    def start_to_run (self, start_address, show_crc_error=0):
        
        condition = True
        while (condition):
                
            frame_type_byte = Reindeer_OCD._OCD_DEBUG_TYPE_COUNTER_CONFIG * 2 + Reindeer_OCD._toggle;
            Reindeer_OCD._toggle = 1 - Reindeer_OCD._toggle
            
            
                  
            frame = Reindeer_OCD._OCD_DEBUG_SYNC + [frame_type_byte] + [0x77, 0x12, 0x34, (start_address >> 24) & 0xFF, (start_address >> 16) & 0xFF, (start_address >> 8) & 0xFF, (start_address >> 0) & 0xFF]
            frame = frame + Reindeer_OCD._crc16_ccitt.get_crc (frame)
            
            if (self._verbose):
                print ("Gsend: ", [hex(i) for i in frame])
            
            self._serial.write (frame)
            condition = 0
            #ret = self._serial.read (Reindeer_OCD._OCD_DEBUG_FRAME_REPLY_LEN)
            
            #condition = not self._verify_crc (ret)
            
            #if (condition):
            #    if (show_crc_error):
            #        print ("counter config reply CRC fail")
            
        if (self._verbose):
            print ("receive: ", [hex(i) for i in ret])
    


    
    #========================================================================
    #  __init__
    #========================================================================
    
    def __init__ (self, com_port, baud_rate, verbose=0):
        self._serial = serial.Serial(com_port, baud_rate, timeout=Reindeer_OCD._OCD_SERIAL_TIME_OUT)
        self._verbose = verbose
        
        
        self.uart_select(1)
        
        if (self._serial.in_waiting):
            r = self._serial.read (self._serial.in_waiting) # clear the uart receive buffer 
        
        self.toolchain = 'riscv-none-embed-'
        self.objdump = self.toolchain + 'objdump'
        self.objcopy = self.toolchain + 'objcopy'
        
        self.image_file = ""
        
#==============================================================================
# main            
#==============================================================================

if __name__ == "__main__":

    baud_rate = 115200
    com_port = "COM5"
    image_file = ""
    mem_test_length = 0
    
    toolchain = 'riscv-none-embed-'
    objdump = toolchain + 'objdump'
    objcopy = toolchain + 'objcopy'
    readelf = toolchain + 'readelf'
    
    cpu_reset = 0
    
    start_addr = 0x80000000
    use_default_start_addr = 1
    
    run = 0
    
    dump_mem = 0
    dump_addr = 0x80000000
    dump_length = 64
    
    console_enable = 0
    
    #=========================================================================
    # print banner
    #=========================================================================
    
    print ("===============================================================================")
    print ("# Copyright (c) 2019, PulseRain Technology LLC ")
    print ("# Reindeer Configuration Utility, Version 2.3")
    
    
    #=========================================================================
    # get command line options
    #=========================================================================
    
    try:
          opts, args = getopt.getopt(sys.argv[1:],"t:a:RrhP:b:i:d:l:c",["help", "run", "reset", "toolchain=", "port=", "start_addr=", "baud=", "image=", "dump_addr=", "dump_length=", "console_enable", "mem_test_len="])
    except (getopt.GetoptError, err):
          print (str(err))
          sys.exit(1)
    
    for opt, args in opts:
        if opt in ('-b', '--baud'): 
            baud_rate = int (args)
        elif opt in ('-a', "--start_addr"): 
            if (args.startswith("0x")):
                start_addr = int (args, 16)
            else:
                start_addr = int (args)
            use_default_start_addr = 0
        elif opt in ('-R', '--run'): 
            run = 1
        elif opt in ('-P', '--port'):
            com_port = args
        elif opt in ('-t', '--toolchain'):
            toolchain = args
            objdump = toolchain + 'objdump'
            objcopy = toolchain + 'objcopy'
            readelf = toolchain + 'readelf'
        elif opt in ('-i', '--image'):
            image_file = args
        elif opt in ('-r', '--reset'):
            cpu_reset = 1
        elif opt in ('-d', '--dump_addr'):
            dump_mem = 1
            
            if (args.startswith("0x")):
                dump_addr = int (args, 16)
            else:
                dump_addr = int (args)
                
        elif opt in ('-l', '--dump_length'):
            if (args.startswith("0x")):
                dump_length = int (args, 16)
            else:
                dump_length = int (args)
        elif opt in ('-c', '--console_enable'):
            console_enable = 1
        elif opt in ('--mem_test_len'):
            if (args.startswith("0x")):
                mem_test_length = int (args, 16)
            else:
                mem_test_length = int (args)
        else:
            print ("Usage:\n  ")
            print ("  Options: \n")
            print ("    -r, --reset          : reset the CPU")
            print ("    -a, --start_addr     : start address for execution")
            print ("    -R, --run            : execute from the start address. The start address can come from command line or image file.")
            print ("    -P, --port=          : the name of the COM port, such as COM7")
            print ("    -d, --baud=          : the baud rate, default to be 115200")
            print ("    -t, --toolchain=     : setup the toolchain. By default, ", toolchain, " is used")
            print ("    -i, --image=         : path and name to the image file")
            print ("    -d, --dump_addr      : start address for memory dumping")
            print ("    -l, --dump_length    : length of the memory dump")
            print ("    -c, --console_enable : switch to observe the CPU UART after image is loaded.")
            print ("    --mem_test_len=      : run memory test for the specified number of words.")
            print (" ")
            print ("    Example: To run the zephyr hello_world application")
            print ("     python reindeer_config.py --port=COM9 --reset --image=C:\GitHub\Reindeer\bitstream_and_binary\zephyr\hello_world.elf --console_enable --run")
            
            sys.exit(1)
            
    print ("===============================================================================")
    print ("baud_rate  = ", baud_rate)
    print ("com_port   = ", com_port)
    print ("toolchain  = ", toolchain)
    print ("===============================================================================")

    try:
        ocd = Reindeer_OCD (com_port, baud_rate, verbose=0)
        
        ocd.toolchain = toolchain
        ocd.objdump = objdump
        ocd.objcopy = objcopy
        ocd.readelf = readelf
        
    except:
        print ("Failed to open COM port.")
        print ("Please check the COM port connection is ok.")
        print ("And please make sure pyserial package is installed.")
        print ("To install pySerial package, use the command: pip3 install pyserial");
        sys.exit(1)
    
    if (cpu_reset):
        print ("Reseting CPU ...")
        ocd.uart_select(1)
            
        if (ocd._serial.in_waiting):
            r = ocd._serial.read (ocd._serial.in_waiting) # clear the uart receive buffer 
            
        ocd.cpu_reset()
        
    if (image_file) :
        print ("Loading ", image_file)
        
        if (image_file.endswith (".elf")):
            result_elf = subprocess.run([readelf, image_file, '-a'], stdout=subprocess.PIPE)
            
            elf_dump = result_elf.stdout.decode('utf-8')
            elf_dump_lines = elf_dump.splitlines() 
            
            if (toolchain == "riscv-none-embed-"):
                sym_regexp = re.compile ("^\S*\d*\:\s(\w{8})\s*\d*\s*(\w*\s*){4}(\w*)")
            else:
                sym_regexp = re.compile ("^\S*\d*\:\s(\w{8})\s*\d*\s*(\w*\s*){5}(\w*)")
                
            capture_next = 0
            for line in elf_dump_lines:
                line_strip = line.strip()
                match = re.search (sym_regexp, line_strip)
                #print (line_strip)
                if (match):
                    addr = int(match.group(1), 16)
                    symbol = match.group(3)
                    
                    if ((symbol == "_start") or (symbol == "__start")):
                        print ("%s %x" % (symbol, addr))
                        if (use_default_start_addr):
                            start_addr = addr
                   
                    if (symbol == "begin_signature"):
                        print ("begin_signature %x" % addr)
                        
                    if (symbol == "end_signature"):
                        print ("end_signature %x" % addr)
            
            ocd.load_elf (image_file)
        
        elif (image_file.endswith (".hex") or image_file.endswith (".ihx")):
            start_addr = ocd.load_hex (image_file)
            
        else:
            print ("unknown image type")
            sys.exit(1)
            
    if (dump_mem):
        print (" ")
        ocd.mem_read (dump_addr, dump_length)
    
    if (mem_test_length):
        print ("Starting Memory Test...")
        prbs = PRBS(31, 0x68888888)
        for i in range(mem_test_length):
            x = prbs.get_next()
            ocd.mem_write_32bit(i * 4, x)
            
            if ((i % 1024) == 0):
                print ("wr i = 0x%x, data = 0x%x" % (i, x))
        
        prbs.reset (31, 0x68888888)
        for i in range(mem_test_length):
            z = ocd.mem_read_32bit(i * 4)
            zz = (z[0] << 24) + (z[1] << 16) + (z[2] << 8) + z[3]
            x = prbs.get_next()
            if (zz != x):
                print ("mem rw error, addr 0x%x, expect 0x%x, got 0x%x" % (i, x, zz))
                exit(1)
            
            if ((i % 1024) == 0):
                print ("rd i = 0x%x, data = 0x%x" % (i, zz))
        
        print ("test Pass! Length = ", mem_test_length)
        
    ocd.uart_select(0)
    
    
    if (run):
        print ("\n===================> start the CPU, entry point = 0x%08x" % start_addr)
        print (" ")
        ocd.start_to_run (start_addr)
    
        if (console_enable):
            ocd._serial.close()
            ocd._serial = serial.Serial(com_port, 115200)
        
        while(console_enable):
            if (ocd._serial.in_waiting):
                r = ocd._serial.read (ocd._serial.in_waiting)  
                prt_out = ""
                for i in r:
                    if (i < 128):
                        prt_out = prt_out + chr(i) 
                print (prt_out, end="")
            