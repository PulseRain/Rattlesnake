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
7. [Security Measure Details](#security)


## 1. Overview <a name="overview"></a>
PulseRain Rattlesnake is a RISC-V soft CPU with a Security-Hardened processor core. It supports RV32IMC instruction set, and carries a Von Neumann architecture. 


![Security-Hardened Processor Core](https://github.com/PulseRain/Rattlesnake/raw/master/docs/rattlesnake_core.png "Security-Hardened Processor Core")

As shown above, on top of a regular RV32IMC core (2 x 2 pipeline stage), 3 additional security units are added. They are:

*	DATU (Dirty Address Trace Unit)
*	BRDU (Block Write Detection Unit
*	ERPU (Execution Region Protection Unit)

These security units form two different security strategies: 
*	Execution Region Protection (ERP)
*	Dirty Address Trace (DAT), with extended memory/register width to store dirty address bit.

To verify the effectiveness of the above two strategies, 5 mock tests from ripe program (![https://github.com/Thales-RISC-V/RISC-V-IoT-Contest](https://github.com/Thales-RISC-V/RISC-V-IoT-Contest)) are used as a bench mark. And the results are shown as following:

  
|      | NR1 | NR2 | NR3 | NR4 | NR5 |
| ---- |:---:|:---:|:---:|:---:|:---:|
| **ERP**  |  Pass  |  Pass  |  **_Fail_**  |  **_Fail_**  |  Pass  |
| **DAT**  |  Pass  |  Pass  |  Pass  |  Pass  |  Pass  |

As indicated by the above table, the ERP strategy (which is basically identical to Physical Memory Protection) can only thwart 3 out of the 5 attacks, while the DAT strategy **can thwart all of them**. The details of the DAT strategy will be discussed [at the end of this document](#security).

In addition, the PulseRain Rattlesnake has been successfully ported to [**Future Electronics Creative board (IGLOO2)**](https://www.futureelectronics.com/fr/p/development-tools--development-tool-hardware/futurem2gl-evb-future-electronics-dev-tools-7091559), with a clock rate of **_120MHz_** (for STD speed grade device), and a total power of **_199mW_**.

## 2. Quick Start <a name="quickstart"></a>
* ### Clone the GitHub Repository
* ### Program the Creative Board
* ### Running Software on the soft CPU

## 3. Folder Structure of the Repository <a name="folder"></a>
folder

## 4. Simulation with [Verilator](https://www.veripool.org/wiki/verilator) <a name="sim"></a>
sim

## 5. Regenerate the Bitstream <a name="regen_bitstream"></a>
bistream

## 6. Zephyr <a name="zephyr"></a>
zephyr

## 7. Security Measure Details <a name="security"></a>
security
