# PulseRain Rattlesnake 
## &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;RISC-V RV32IMC Soft CPU, with a Security-Hardened Processor Core
------------------------------------------------
## Table of Contents
1. [Overview](#overview)
2. [Quick Start](#quickstart)
3. [Folder Structure of the Repository](#folder)
4. [Simulation with Verilator](#sim)
5. [Regenerate the Bitstream](#regen_bitstream)
6. [Zephyr](#zephyr)
7. **_[Security Strategy Details](#security)_**


## 1. Overview <a name="overview"></a>
PulseRain Rattlesnake is a RISC-V soft CPU with a Security-Hardened processor core. It supports RV32IMC instruction set, and carries a Von Neumann architecture. 


![Security-Hardened Processor Core](https://github.com/PulseRain/Rattlesnake/raw/master/docs/rattlesnake_core.png "Security-Hardened Processor Core")

As shown above, on top of a regular RV32IMC core (2 x 2 pipeline stage), 2 additional security units are added. They are:

*	ERPU (Execution Region Protection Unit)
*	DATU (Dirty Address Trace Unit)

These security units form two different security strategies: 
*	Execution Region Protection (ERP)
*	Dirty Address Trace (DAT), with extended memory/register width to store dirty address bit.

To verify the effectiveness of the above two strategies, 5 mock tests from ripe program (![https://github.com/Thales-RISC-V/RISC-V-IoT-Contest](https://github.com/Thales-RISC-V/RISC-V-IoT-Contest)) are used as a bench mark. **_The 5 mock tests are compiled without any change to the compiler_**. And the results are shown as following:

  
|      | NR1 | NR2 | NR3 | NR4 | NR5 |
| ---- |:---:|:---:|:---:|:---:|:---:|
| **ERP**  |  **_Pass_**  |  **_Pass_**  |  _Fail_  |  _Fail_  |  **_Pass_**  |
| **DAT**  |  **_Pass_**  |  **_Pass_**  |  **_Pass_**  |  **_Pass_**  |  **_Pass_**  |

As indicated by the above table, the ERP strategy (which is similar to Physical Memory Protection in other processors) can only thwart 3 out of the 5 attacks, while **_the DAT strategy can thwart all of them_**. The details of the DAT strategy will be discussed [at the end of this document](#security).

In addition, the PulseRain Rattlesnake has been successfully ported to [**Future Electronics Creative board (IGLOO2)**](https://www.futureelectronics.com/fr/p/development-tools--development-tool-hardware/futurem2gl-evb-future-electronics-dev-tools-7091559), with a clock rate of **_120MHz_** (for STD speed grade device), and a total power of **_199mW_**.

And the Resource Usage on IGLOO2 (M2GL025) is as following (with 48KB memory size):

| **Resource Name** | **Resource Usage** |
| ---- |:---:|
| _Fabric 4LUT_ | 4689 |
| _Fabric DFF_ | 3129 |
| _Interface 4LUT_ | 1224 |
| _Interface DFF_ | 1224 |
| _uSRAM 1K_ | 2 |
| _LSRAM 18K_ | 28 |
| _Math 18x18_ | 4 |

## 2. Quick Start <a name="quickstart"></a>
* ### Clone the GitHub Repository
Assume Windows Platform is used. And assume Cygwin is installed. To clone the GitHub Repository of PulseRain Rattlesnake, do the following in Cygwin:

    git clone https://github.com/PulseRain/Rattlesnake.git
    cd Rattlesnake
    git submodule update --init --recursive --progress
 
 And the following is a screen capture for Cygwin operations on Windows 10
 ![Clone the GitHub Repository](https://github.com/PulseRain/Rattlesnake/raw/master/docs/github_clone.png "Clone the GitHub Repository")
 
* ### Program the Creative Board
On Windows 10, Download and Install [Programming and Debug v12.1 for Windows](http://download-soc.microsemi.com/FPGA/v12.1/prod/Program_Debug_v12.1_win.exe). 

Connect the Creative Board to the host PC through USB cable

Launch **FPExpress v12.1**, and open **Rattlesnake\bitstream_and_binary\creative\Rattlesnake_flashpro_express\Rattlesnake_flashpro_express.pro**

Click **RUN** to program the Creative Board, as shown below:
![Program the Creative Board](https://github.com/PulseRain/Rattlesnake/raw/master/docs/flash_program.png "Program the Creative Board")

After the board is programmed, please **unplug and re-plug the USB cable** to make sure the board is properly re-initialized.

* ### Running Software on the soft CPU
As illustrated below, a python script called **rattlesnake_config.py** is provided to load software (.elf file) into the soft CPU and execute. At this point, this script has only been tested on Windows platform.


![Rattlesnake Config](https://github.com/PulseRain/Rattlesnake/raw/master/docs/rattlesnake_config.png "Rattlesnake Config")

Before using this script, the following should be done to setup the environment on Windows:

1. Install a RISC-V tool chain on Windows
  
     It is recommended to use [**the RISC-V Embedded GCC**](https://gnu-mcu-eclipse.github.io/toolchain/riscv/). And its [**v8.2.0-2.2 release**](https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/v8.2.0-2.2-20190521/gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-win64.zip) can be downloaded from [**here**](https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/v8.2.0-2.2-20190521/gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-win64.zip)

  2. After installation, add the RISC-V toolchain to system's $PATH
  
     If default installation path is used, most likely the following paths need to be added to system's $PATH:
     
     C:\GNU MCU Eclipse\RISC-V Embedded GCC\8.2.0-2.2-20190521-0004\bin
 
  3. Install python3 on Windows
  
     The latest python for Windows can be downloaded from https://www.python.org/downloads/windows/

  4. After installation, add python binary and pip3 binary into system's $PATH
  
     For example, if python 3.7.x is installed by user XYZ on Windows 10 in the default path, the following two folders might be added to $PATH:

         C:\Users\XYZ\AppData\Local\Programs\Python\Python37
        
         C:\Users\XYZ\AppData\Local\Programs\Python\Python37\Scripts


  5. Open a command prompt (You might need to Run as Administrator), and install the pyserial package for python:
  
     **pip3 install pyserial**

  6. Make sure the Creative Board is connected to the host PC, and is programmed with the Rattlesnake bitstream.
  
  7. Open the Device Manager in Windows to figure out which COM port is assigned to the Creative Board.
  
  8. Enter the Rattlesnake\scripts directory. Assume COM7 is used by the  hardware, then the following command can be used to load the ATTACK_NR1
  
     **python rattlesnake_config.py --port=COM7 --console_enable --reset --run --image=..\RISC-V-IoT-Contest\ATTACK_NR1\build\zephyr\zephyr.elf**
    
  ![Load elf file](https://github.com/PulseRain/Rattlesnake/raw/master/docs/run_script.png "Load elf file")

And ATTACK_NR1's output is as following:

![ATTACK_NR1](https://github.com/PulseRain/Rattlesnake/raw/master/docs/ATTACK_NR1_output.png "ATTACK_NR1")

The other 4 attacks' output are as following:

**_ATTACK_NR2:_** &nbsp;
   **python rattlesnake_config.py --port=COM7 --console_enable --reset --run --image=..\RISC-V-IoT-Contest\ATTACK_NR2\build\zephyr\zephyr.elf**

![ATTACK_NR2](https://github.com/PulseRain/Rattlesnake/raw/master/docs/ATTACK_NR2_output.png "ATTACK_NR2")


&nbsp;
&nbsp;
&nbsp;

**_ATTACK_NR3:_** &nbsp;
   **python rattlesnake_config.py --port=COM7 --console_enable --reset --run --image=..\RISC-V-IoT-Contest\ATTACK_NR3\build\zephyr\zephyr.elf**

![ATTACK_NR3](https://github.com/PulseRain/Rattlesnake/raw/master/docs/ATTACK_NR3_output.png "ATTACK_NR3")



&nbsp;
&nbsp;
&nbsp;

**_ATTACK_NR4:_** &nbsp;
   **python rattlesnake_config.py --port=COM7 --console_enable --reset --run --image=..\RISC-V-IoT-Contest\ATTACK_NR4\build\zephyr\zephyr.elf**

![ATTACK_NR4](https://github.com/PulseRain/Rattlesnake/raw/master/docs/ATTACK_NR4_output.png "ATTACK_NR4")


&nbsp;
&nbsp;
&nbsp;

**_ATTACK_NR5:_** &nbsp;
   **python rattlesnake_config.py --port=COM7 --console_enable --reset --run --image=..\RISC-V-IoT-Contest\ATTACK_NR5\build\zephyr\zephyr.elf**

![ATTACK_NR5](https://github.com/PulseRain/Rattlesnake/raw/master/docs/ATTACK_NR5_output.png "ATTACK_NR5")

&nbsp;
The details of the 5 attacks will be discussed [at the end of this document](#security).

## 3. Folder Structure of the Repository <a name="folder"></a>
The folder structure of the [GitHub Repository](https://github.com/PulseRain/Rattlesnake) is illustrated below:

![Folder Structure](https://github.com/PulseRain/Rattlesnake/raw/master/docs/folder_structure.png "Folder Structure")

## 4. Simulation with [Verilator](https://www.veripool.org/wiki/verilator) <a name="sim"></a>
The PulseRain Rattlesnake can be simulated with [Verialtor](https://www.veripool.org/wiki/verilator). To prepare the simulation and run the compliance test, the following steps (tested on Ubuntu and Debian hosts) can be followed:
  1. Install [zephyr-sdk 0.10.3](https://github.com/zephyrproject-rtos/sdk-ng/releases/tag/v0.10.3)
  2. Install Verilator from https://www.veripool.org/wiki/verilator (or use apt-get install verilator). At this point, only Verilator version 4.0 or later is supported
  3. **git clone https://github.com/PulseRain/Rattlesnake.git**
  4. **cd Rattlesnake**
  5. **git submodule update --init --recursive --progress**
  6. **cd sim/verilator**
  7. Build the verilog code and C++ test bench: **make**
  8. Run the simulation for compliance test: **make test_all**

If everything goes smooth, the final output of the compliance test may look like the following:
![verilator compliance test](https://github.com/PulseRain/Rattlesnake/raw/master/docs/verilator.png "verilator compliance test")

For the RV32IMC compliance test, there are total of 88 test cases. Among them, 55 are for RV32I, 25 are for C extension and 8 are for M extension.

## 5. Regenerate the Bitstream (SYN and PAR) <a name="regen_bitstream"></a>
To build bitstream for [**Future Electronics Creative board (IGLOO2)**](https://www.futureelectronics.com/fr/p/development-tools--development-tool-hardware/futurem2gl-evb-future-electronics-dev-tools-7091559), do the following:
  1. Install [Microsemi Libero SoC V12.1 for Windows](http://download-soc.microsemi.com/FPGA/v12.1/prod/Libero_SoC_v12.1_win.zip), and get a License for it if necessary.
  2. Use synplify_pro (part of  Microsemi Libero SoC V12.1) to open Rattlesnake\build\synth\Microchip\Rattlesnake.prj, and generate **Rattlesnake.vm**
  3. Use a text editor (such as Notepad++) to open the **Rattlesnake.vm** generated above, search for those lines that contain the text "**RAMINDEX**", and comment those lines out by putting a "//" at the beginning of the line. This step is just a way to circumvent a bug of the Libero SoC V12.1.
  4. Close synplify_pro and use Libero SoC V12.1 to open Rattlesnake\build\par\Microchip\creative\creative.prjx
  5. Generate bitstream with Libero SoC V12.1, and verify the timing is passed.
  
## 6. Zephyr <a name="zephyr"></a>
[zephyr 1.14.1-rc1](https://github.com/PulseRain/zephyr) ([https://github.com/PulseRain/zephyr](https://github.com/PulseRain/zephyr)) has been successfully ported to PulseRain Rattlesnake. Basically, a board called **rattlesnake** is created, and a SoC called **pulserain-rattlesnake** is added. The details of the porting job can be found [here](https://github.com/PulseRain/zephyr/commit/d84996362d748e84b22b8de2545f8bba96fab6b1). The OS infrastructure of zephyr has not been modified during the porting. Only a driver for UART and modifications to the Makefile were added.

To build applications for zephyr, please do the following under Linux:
  1. Follow the instructions [here](https://docs.zephyrproject.org/latest/getting_started/installation_linux.html) to setup development environment.
  
     The rest of the document assumes Linux is used as host for build, and Zephyr SDK 0.10.3 is used for toolchain.
  
  2. To build for sample applications, users can do the following: (take the sample application of philosophers for example)
     
    $ git clone https://github.com/PulseRain/zephyr.git
    $ cd zephyr;rm -rf build
    $ cmake -B build -DBOARD=rattlesnake -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON VERBOSE=1 samples/philosophers
    $ make -C build

    And the elf file can be found in build/zephyr/zephyr.elf
     
  3. In particular, to build the mock test from [RISC-V-IoT-Contest](https://github.com/PulseRain/RISC-V-IoT-Contest/tree/5fd366a0beec4b06054d38bcdca5e6fc5276de96), users can do the following: (take the ATTACK_NR1 for example)
  
    $ git clone https://github.com/PulseRain/Rattlesnake.git
    $ cd Rattlesnake
    $ git submodule update --init --recursive --progress
    $ cd RISC-V-IoT-Contest/ATTACK_NR1;rm -rf build
    $ cmake -B build -DBOARD=rattlesnake -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON VERBOSE=1 .
    $ make -C build
    
    And the elf file can be found in build/zephyr/zephyr.elf
        
     
## 7. Security Strategy Details <a name="security"></a>

As mentioned early, PulseRain Rattlesnake mainly carries two security strategies: **ERP** and **DAT**. The details of those two strategies are now discussed below:

### **_ERP (Executable Region Protection)_**

This strategy is similar to PMP (Physical Memory Protection) in other processors. Inside the Rattlesnake soft CPU, there is a module called ERPU (Executable Region Protection), which exposes two memory mapped registers:

| **0x2000002C** | **_Register for ERP Start Address_** |
| ---- |:---:|
| **0x20000030** | **_Register for ERP End Address_** |


Those two registers can only be written for once after reset. And usually those two registers are configured by bootloader. If the image is loaded from host PC, the loader script (In this case, rattlesnake_config.py) will configure them. 

During normal operation, if PC is moved out of the region marked by **ERP Start Address** and **ERP End Address**, an exception (illegal instruction) will be thrown to stop the execution of malicious code.

The plus side of ERP strategy is:

* easy to implement
* hardware overhead is low

The drawbacks of ERP are:

* Intrusive to software design. 
    The bootloader or the application itself has to figure out the protected region, and do the proper configuration right after reset.
* It can not defend against those attacks that invoke system code. 

In fact, among the 5 mock tests (attacks), only 3 out of the 5 attacks can be thwarted by ERP. In order to thwart all 5 attacks, a more sophisticated defense scheme is needed. And for PulseRain Rattlesnake, the answer is **DAT (Dirty Address Trace)**.


### **_DAT (Dirty Address Trace)_**
Through the analysis of existing attack schemes, it is noticed that:
  1.	The attacker will usually take advantage of a software loophole to carry out buffer-overflow attacks
  2.	The buffer-overflow attack will overwrite certain pointers. For example, some direct attack scheme will overwrite the return address on the stack, and re-point it to malicious code.
  3.	To circumvent Physical Memory Protection, a more sophisticated scheme will set the pointer to code section, and invoke system functions such as a system console shell.
  4.	To circumvent other software guarding measures, such as stack canaries, some more sophisticated schemes will carry out indirect pointer attack, by modifying the pointer of a pointer. 

Based on such observation, the DAT strategy is conceived to comprise the following 3 parts:
  * Expanded Memory and Register
  * Block Write Detection
  * Indirect Pointer Detection

####  1. DAT - Expand the memory and register width, add a dirty address bit

For PulseRain Rattlesnake, the memory is made of 4 banks, each bank is expanded from 8 bits to 9 bits, with 1 extra bit to indicate dirty address. The direct address bit is an indication for its content to be suspicious, as its content has been modified through block write. Fortunately, for most mainstream FPGA vendors, port width of 9 is natively supported by their block RAMs.
  
![Dirty Bit in Memory](https://github.com/PulseRain/Rattlesnake/raw/master/docs/dirty_bit_memory.png "Dirty Bit in Memory")

The 32 general purpose registers are also expanded by 1 bit. When data are loaded from memory to registers, the dirty address bit attached to the most significant byte will also be loaded into the highest bit (bit 32) of the expanded register.

![Register Expansion](https://github.com/PulseRain/Rattlesnake/raw/master/docs/register.png "Register Expansion")

####  2. DAT - Block Write Detection

The Block Write Detection will issue a dirty address flag if it seems a batch of consecutive write that are more than 8. Here the threshold 8 is used because according to the RISC-V calling convection, register s0-s7 need to be stored on the stack. A threshold of 8 will avoid the store of s0-s7 being flagged as dirty address. 

The block write detection module will also take interrupt into account. Thus for a buffer-overflow to fly under the radar, its size has to be no more than 8, or it can manage to switch thread context every 8 write operations. For IoT application, this will make the attacker a lot more difficult to escape from the block write detection.

####  3. DAT - Indirect Pointer Detection

However, a more sophisticated attacker will use indirect pointer to circumvent the block write detection. To thwart such attackers, another module called indirect pointer detection is adopted by PulseRain Rattlesnake. The indirect pointer detection module will identify such indirect pointer, and spread the direct address bit to its final target address.

By observing the assembly code produced by the compiler (At this point, the GCC (ver 8.3) from zephyr-sdk 0.10.3 is used.), it can be concluded that the indirect pointer operation is done with the following instruction patterns:

    1 LW   registerA, xxx(s0)
      Load something on the stack frame (s0 is the frame pointer) into registerA. 
      If the pointer is a global variable stored in data section, it may produce a different code pattern.
 
    2. LW   registerB, xxx(registerA)
      indirect pointer(pointer of the pointer)
      
    3. LW registerC, xxx(s0)
      If the pointer is a global variable stored in data section, it may produce a different code pattern.

    4. SW registerC, (registerB)

The indirect pointer detection module will recognize the above pattern. For the last step, if registerC or registerB contains dirty address bit, such dirty address bit will be further spread into the memory word pointed by registerB.

**_For a memory word, merely having its dirty address bit set will not cause any reaction from the processor. However, if later on the processor sees a JAL instruction whose target address is dirty, the processor will throw an illegal instruction exception to prevent the malicious code from being reached._**

####  4. DAT - Side Effect Discussion

Theoretically, the DAT would have some side effect for the software. If the software uses block copy to write a function table that is more than 8 items, the function table might be marked as dirty by DAT. However, practically it is very rare of normal code flow to do something like that, as most function table will be saved as constant, or modified individually instead of a batch fashion.

As a way to test this, the following two zephyr applications (philosopher and synchronization) have been tested along with DAT
bitstream_and_binary\zephyr\philosophers_rv32imc.elf
bitstream_and_binary\zephyr\synchronization_rv32imc.elf
Users can use the following command (assume COM7 is used by the Create Board) to load them

**_python rattlesnake_config.py --port=COM7 --console_enable --reset --run --image=..\bitstream_and_binary\zephyr\philosophers_rv32imc.elf_**

**_python rattlesnake_config.py --port=COM7 --console_enable --reset --run --image=..\bitstream_and_binary\zephyr\synchronization_rv32imc.elf_**


### **_Test with Ripe_**
As mentioned early, for the 5 mock tests from ripe program (![https://github.com/Thales-RISC-V/RISC-V-IoT-Contest](https://github.com/Thales-RISC-V/RISC-V-IoT-Contest)), they can all be stopped by DAT alone, before ERP can catch them. Here is a quick review of those 5 attacks:

####  Attach NR1. -t direct -i shellcode -c funcptrheap -l heap -f memcpy
The list file of this attack program can be found in [here](https://github.com/PulseRain/RISC-V-IoT-Contest/blob/5fd366a0beec4b06054d38bcdca5e6fc5276de96/ATTACK_NR1/build/zephyr/zephyr.lst)

Its output is as following:

    ***** Booting Zephyr OS zephyr-v1.14.1-rc1-2-g936510fd3ed7 *****
    [z_sched_lock]  scheduler locked (0x800471d8:255)
    [k_sched_unlock]  scheduler unlocked (0x800471d8:0)
    RIPE is alive! rattlesnake
    -t direct -i shellcode -c funcptrheap -l heap -f memcpy----------------
    Shellcode instructions:
    lui t1,  0x80042               80042337
    addi t1, t1, 0x2de                 2de30313
    jalr t1000300e7
    ----------------
    target_addr == 0x80049ac0
    buffer == 0x80049790
    payload size == 821
    bytes to pad: 804

    overflow_ptr: 0x80049790
    payload: 7#-

    Executing attack... Exception cause Illegal instruction (2)
    Current thread ID = 0x800471d8
    Faulting instruction address = 0x8004331a
      ra: 0x8004331c  gp: 0xaaaaaaaa  tp: 0xaaaaaaaa  t0: 0x800407d4
      t1: 0xf  t2: 0xfffffff5  t3: 0x0  t4: 0x7fffffff
      t5: 0x19  t6: 0x800464f0  a0: 0x0  a1: 0x0
      a2: 0x80045c48  a3: 0x80047a04  a4: 0x800454a0  a5: 0x80049790
      a6: 0x0  a7: 0x1
    Fatal fault in essential thread! Spinning...

The Faulting instruction address = 0x8004331a in the list file is correspondent to the folllowing instructions:

       ((int (*)(char *, int)) * heap_func_ptr)(NULL, 0);
    80043310:	93442783          	lw	a5,-1740(s0)
    80043314:	439c                	lw	a5,0(a5)
    80043316:	4581                	li	a1,0
    80043318:	4501                	li	a0,0
    8004331a:	9782                	jalr	a5
    8004331c:	b7e9                	j	800432e6 <perform_attack+0xaa0>
    
    

