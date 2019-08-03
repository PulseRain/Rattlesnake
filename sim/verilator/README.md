 * # Simulation with [Verilator](https://www.veripool.org/wiki/verilator)

The PulseRain Reindeer can be simulated with [Verialtor](https://www.veripool.org/wiki/verilator). To prepare the simulation, the following steps (tested on Ubuntu and Debian hosts) can be followed: 
  
  1. Install Verilator from https://www.veripool.org/wiki/verilator
  
  2. Install zephyr-SDK, (details can be found in https://docs.zephyrproject.org/latest/getting_started/installation_linux.html)
     
  3. Make sure **riscv32-zephyr-elf-**  tool chain is in $PATH and is accessible everywhere
    
     If default installation path is used for Zephyr SDK, the following can be appended to the .profile or .bash_profile
     
         export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
         
         export ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
         
         export PATH="/opt/zephyr-sdk/sysroots/x86_64-pokysdk-linux/usr/bin/riscv32-zephyr-elf":$PATH
         
  4. **git clone https://github.com/PulseRain/Reindeer.git**
  
  5. **cd Reindeer/sim/verilator**
  
  6. Build the verilog code and C++ test bench: **make**
  
  7. Run the simulation for compliance test: **make test_all**

If everything goes smooth, the output may look like the following:
  
<a href="https://youtu.be/bs-CplrT9Mo" target="_blank"><img src="https://github.com/PulseRain/Reindeer/raw/master/docs/verilator.GIF" alt="Verilator" width="1008" height="756" border="10" /></a>

As mentioned early, the Reindeer soft CPU uses an OCD to load code/data. And for the [verilator]( https://www.veripool.org/wiki/verilator) simulation, a C++ testbench will replace the OCD. The testbench will invoke the toolchain (riscv32-zephyr-elf-) to extract code/data from sections of the .elf file. The testbench will mimic the OCD bus to load the code/data into CPU's memory.  Afterwards, the start-address of the .elf file ("_start" or "__start" symbol) will be passed onto the CPU, and turn the CPU into active state.

To form a foundation for verification, it is mandatory to pass [55 test cases]( https://github.com/riscv/riscv-compliance/tree/master/riscv-test-suite/rv32i) for RV32I instruction set. For compliance test, the test bench will automatically extract the address for begin_signature and end_signature symbol.
The compliance test will utilize the hold-and-load feature of the PulseRain Reindeer soft CPU, and do the following:
  1. Reset the CPU, put it into hold state
  2. Call upon toolchain to extract code/data from the .elf file for the test case
  3. Start the CPU, run for 2000 clock cycles
  4. Reset the CPU, put it into hold state for the second time
  5. Read the data out of the memory, and compare them against the reference signature

And the diagram below also illustrates the same idea:

  
![Verilator Simulation](https://github.com/PulseRain/Reindeer/raw/master/docs/sim_verilator.png "Verilator Simulation")
  
And for the sake of completeness, the [Makefile for Verilator](https://github.com/PulseRain/Reindeer/blob/master/sim/verilator/Makefile) supports the following targets:
  * **make build** : the default target to build the verilog uut and C++ testbench for Verilator
  * **make test_all** : run compliance test for all 55 cases
  * **make test compliance_case_name** : run compliance test for individual case. For example: make test I-ADD-01
  * **make run elf_file** : run sim on an .elf file for 2000 cycles. For example: make run ../../bitstream_and_binary/zephyr/hello_world.elf
