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
# https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence
###############################################################################

class PRBS:
    
    

    def reset(self, prbs_length, start_value):
        if (prbs_length == 7):
            self.poly = 0xC1 >> 1
        elif (prbs_length == 9):
            self.poly = 0x221 >> 1
        elif (prbs_length == 11):
            self.poly = 0xA01 >> 1
        elif (prbs_length == 15):
            self.poly = 0xC001 >> 1
        elif (prbs_length == 20):
            self.poly = 0x80005 >> 1
        elif (prbs_length == 23):
            self.poly = 0x840001 >> 1
        else:
            assert (prbs_length == 31)
            self.poly = 0xA0000001 >> 1
        self.state = start_value
        self.prbs_length = prbs_length
                
    def __init__ (self, prbs_length, start_value):
        self.reset (prbs_length, start_value)
    
    def get_next (self):
        next_bit = 0
        for i in range(self.prbs_length):
            if ((self.poly >> i) & 1):
                next_bit = next_bit ^ ((self.state >> i) & 1) 
        
        self.state = ((self.state << 1) | next_bit) & ((2**(self.prbs_length + 1)) - 1)
        
        return self.state
        
    
    
def main():
    init = 2
    p = PRBS (15, init)
    
    i = 0
    while(1):
        x = p.get_next()
        print ("%d 0x%x" % (i, x))
        
        if (x == init):
            print ("period = %d" % (i + 1))
            break
            
        
        i = i + 1
    
if __name__ == "__main__":
    main()
    