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



###############################################################################
# References:
# http://stackoverflow.com/questions/25239423/crc-ccitt-16-bit-python-manual-calculation
###############################################################################

class CRC16_CCITT:
    
    _POLYNOMIAL = 0x1021
    _PRESET = 0xFFFF

    def _initial(self, c):
        crc = 0
        c = c << 8
        for j in range(8):
            if (crc ^ c) & 0x8000:
                crc = (crc << 1) ^ self._POLYNOMIAL
            else:
                crc = crc << 1
            c = c << 1
            
        return crc
   
    def _update_crc(self, crc, c):
        cc = 0xff & c

        tmp = (crc >> 8) ^ cc
        crc = (crc << 8) ^ self._tab[tmp & 0xff]
        crc = crc & 0xffff

        return crc
    
    def __init__ (self):
        self._tab = [ self._initial(i) for i in range(256) ]
    
    def get_crc (self, data_list):
        crc = self._PRESET
        for c in data_list:
            crc = self._update_crc(crc, c)
        return [(crc >> 8) & 0xFF, crc & 0xFF]     
    
    
def main():

    crc = CRC16_CCITT ()
    
    for i in range(256):
        print ("0x{0:08x},".format(crc._tab[i]))
    
if __name__ == "__main__":
    main()
    