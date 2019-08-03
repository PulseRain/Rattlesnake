/*
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
*/

`ifndef CONFIG_VH
`define CONFIG_VH

`define INCLUDE_PERIPHERAL (0)

//----------------------------------------------------------------------------
//  default start address 
//----------------------------------------------------------------------------
`define DEFAULT_START_ADDR   (32'h80000000)

//----------------------------------------------------------------------------
//  memory size 
//----------------------------------------------------------------------------

`define SRAM_SIZE_IN_BYTES   (64 * 1024)
`define DRAM_SIZE_IN_BYTES   (8 * 1024 * 1024)
`define DRAM_RW_BUFFER_SIZE  (1024/4)

`define SRAM_ADDR_BITS       ((`SRAM_SIZE_IN_BYTES == 0) ? 1 : ($clog2(`SRAM_SIZE_IN_BYTES / 4)))

`define DRAM_ADDR_BITS       ($clog2(`DRAM_SIZE_IN_BYTES / 4))

`define MEM_ADDR_BITS        (`DRAM_ADDR_BITS)


`define MM_REG_SIZE_IN_BYTES   (128)
`define MM_REG_ADDR_BITS       ($clog2(`MM_REG_SIZE_IN_BYTES / 4))

`define DEFAULT_STACK_ADDR    ((`SRAM_SIZE_IN_BYTES == 0) ? (((`DRAM_SIZE_IN_BYTES) - 8)| 32'h80000000)  : (((`SRAM_SIZE_IN_BYTES) - 8)| 32'h80000000)) 
//----------------------------------------------------------------------------
//  clock 
//----------------------------------------------------------------------------
`define MCU_MAIN_CLK_RATE                  100000000


//----------------------------------------------------------------------------
//  peripheral addresses
//----------------------------------------------------------------------------
    
    //------------------------------------------------------------------------
    //  Timer
    //------------------------------------------------------------------------

    `define MTIME_LOW_ADDR                     ((`MM_REG_ADDR_BITS)'(0))
    `define MTIME_HIGH_ADDR                    ((`MM_REG_ADDR_BITS)'(1))

    `define MTIMECMP_LOW_ADDR                  ((`MM_REG_ADDR_BITS)'(2))
    `define MTIMECMP_HIGH_ADDR                 ((`MM_REG_ADDR_BITS)'(3))


    //------------------------------------------------------------------------
    //  UART
    //------------------------------------------------------------------------

    `define UART_TX_ADDR                       ((`MM_REG_ADDR_BITS)'(4))
    `define UART_RX_ADDR                       ((`MM_REG_ADDR_BITS)'(5))

    `define UART_BAUD_RATE                      115200
    `define UART_BAUD_PERIOD                   (`MCU_MAIN_CLK_RATE / `UART_BAUD_RATE)
    `define UART_BAUD_PERIOD_BITS              ($clog2(`UART_BAUD_PERIOD))
    `define UART_STABLE_COUNT                  (`MCU_MAIN_CLK_RATE  / `UART_BAUD_RATE / 2)
    `define UART_DEFAULT_DATA_LEN               8
    `define UART_RX_FIFO_SIZE                   1024
    
    `define UART_RX_READ_REQ_BIT                31
    `define UART_RX_SYNC_RESET_BIT              28
    
    //------------------------------------------------------------------------
    //  GPIO
    //------------------------------------------------------------------------	
    `define GPIO_ADDR                          ((`MM_REG_ADDR_BITS)'(6))
    `define NUM_OF_GPIOS                       32 
    
    //------------------------------------------------------------------------
    // Interrupt
    //------------------------------------------------------------------------
    `define INT_SOURCE_ADDR                    ((`MM_REG_ADDR_BITS)'(7))
    `define INT_ENABLE_ADDR                    ((`MM_REG_ADDR_BITS)'(8))
    
    // Interrupt external to the MCU
    `define NUM_OF_INTx                        2
    
    // Num of total Interrupts, including Timer
    `define NUM_OF_TOTAL_INT                   (`NUM_OF_INTx + 2)
    
    `define INT_TIMER_INDEX                    0
    `define INT_UART_RX_INDEX                  1
    `define INT_EXT_INDEX_1ST                  (32 - `NUM_OF_INTx)
    `define INT_EXT_INDEX_LAST                 31
    

    //------------------------------------------------------------------------
    // I2C
    //------------------------------------------------------------------------
    `define I2C_CSR_ADDR                       ((`MM_REG_ADDR_BITS)'(9))
    `define I2C_DATA_ADDR                      ((`MM_REG_ADDR_BITS)'(10))
    
//----------------------------------------------------------------------------
//  hardware mul/div
//----------------------------------------------------------------------------
`define STORE_WAIT_FOR_ACK                  (1'b1)

`define DISABLE_OCD                         0

`define ENABLE_HW_MUL_DIV                   1

`define SMALL_MACHINE_TIMER                 0
`define SMALL_CSR_SET                       0

`endif
