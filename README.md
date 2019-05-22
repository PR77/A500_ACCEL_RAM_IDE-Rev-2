# A500_ACCEL_RAM_IDE-Rev-2
Improved design attempt for Amiga 500 in socket 68000 Accelerator, FastRAM and IDE Interface

# Warning
This design has not been compliance tested and will not be. It may cause damage to your A500. I take no responsibility for this. I accept no responsibility for any damage to any equipment that results from the use of this design and its components. IT IS ENTIRELY AT YOUR OWN RISK!

# Overview
The main purpose of this design is to improve on of the Rev 1. As the Rev 1 design was essentially a proof of concept, Rev 2 supports a larger CPLD (95144), SPI Flash, buffered IDE Interface, 2 Spare IO header pins and 2MB SRAM. However, most importantly support for the MC68SEC000 which can be  aggressively clocked.

### Appearance
Nice 3D model:
![3D Model](/Images/A500_ACCEL_RAM_IDE.png)

... and the populated PCB with only 1MB of SRAM (FastRAM) and 128MByte DOM:
![Populated PCB](/Images/HardwareWithIDE.jpg)

My design goals for the Rev 2 design were to:

1. Use a larger CPLD to contain all the logic (and more) from Rev 1.
2. Support up to 40MHz with 0 Waitstates.
3. Support IDE.device (credit to MHeinrichs https://github.com/MHeinrichs) for a simple and quick IDE interface.
4. Have a SPI interface / SPI Flash for available to eventually support Flash based Kickstarts.

Here is the performance overview at 30MHz:
![30 MHz](/Images/PerformanceOverview_30MHz.jpg)

... and at 40MHz:
![40 MHz](/Images/PerformanceOverview_40MHz.jpg)

### BOM
For those wanting to build their own hardware, here is the BOM;

| Reference(s) | Value           | Footprint                                        |
|--------------|-----------------|--------------------------------------------------|
| C101         | 100nF           | Capacitors_SMD:C_0603                            |
| C102         | 100nF           | Capacitors_SMD:C_0603                            |
| C103         | 100nF           | Capacitors_SMD:C_0603                            |
| C104         | 100nF           | Capacitors_SMD:C_0603                            |
| C105         | 100nF           | Capacitors_SMD:C_0603                            |
| C106         | 100nF           | Capacitors_SMD:C_0603                            |
| C107         | 100nF           | Capacitors_SMD:C_0603                            |
| C112         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| C113         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| C114         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              | 
| C201         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| C202         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| C203         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| C204         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| C205         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| C206         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| C207         | 100nF           | Capacitors_SMD:C_0805_HandSoldering              |
| IDE_40       | CONN_02X20      | Pin_Headers:Pin_Header_Straight_2x20_Pitch2.54mm |
| J1           | EXP             | Pin_Headers:Pin_Header_Straight_1x03_Pitch2.54mm |
| JTAG1        | CONN_01X06      | Pin_Headers:Pin_Header_Straight_1x06_Pitch2.54mm |
| LED201       | LED             | LEDs:LED_0805_HandSoldering                      |
| R101         | R10K            | Resistors_SMD:R_0603                             |
| R102         | R10K            | Resistors_SMD:R_0603                             |
| R201         | 680R            | Resistors_SMD:R_0805_HandSoldering               |
| U101         | 68000D          | Pin_Headers:Pin_Header_Straight_2x32_Pitch2.54mm |
| U102         | MC68SEC000FN    | Housings_QFP:LQFP-64_14x14mm_Pitch0.8mm          |
| U103         | XC95144XL-TQ100 | Housings_QFP:TQFP-100_14x14mm_Pitch0.5mm         |
| U104         | AT25_EEPROM     | Housings_SOIC:SOIC-8_3.9x4.9mm_Pitch1.27mm       |
| U105         | LM1117-3.3      | TO_SOT_Packages_SMD:SOT-223                      |
| U201         | SRAM_512Ko      | Housings_DIP:DIP-32_W15.24mm_Socket              |
| U202         | SRAM_512Ko      | Housings_DIP:DIP-32_W15.24mm_Socket              |
| U203         | SRAM_512Ko      | Housings_DIP:DIP-32_W15.24mm_Socket              |
| U204         | SRAM_512Ko      | Housings_DIP:DIP-32_W15.24mm_Socket              |
| U205         | 74HCT245        | Housings_SOIC:SO-20_12.8x7.5mm_Pitch1.27mm       |
| U206         | 74HCT245        | Housings_SOIC:SO-20_12.8x7.5mm_Pitch1.27mm       |
| U207         | 74HCT245        | Housings_SOIC:SO-20_12.8x7.5mm_Pitch1.27mm       |
| X101         | CXO_DIP14       | Oscillators:Oscillator_DIP-14                    |

### Known Issues And Pending Changes
While populated and debugging Rev 2 naturally issues where found and better ideas came to mind. Also contributions from the Amiga community (http://eab.abime.net/showthread.php?t=89165). The following corrections / improvements are pending the next design iteration:

1. Change all SMD capacitors and resistors to 0804 packages with hand-soldering footprints to improve soldering.
2. Correct SPI Flash footprint. Or considering to remove it as I see no immediate benefit.
3. Increase thermal relief around THD and SMD GND connections to improve soldering (as PCB is 4 layers).
4. Add 10uF filtering around the power components (+3.3 volt regulator, CPLD and 68SEC000) and add pull-ups/downs on JTAG.
5. Route PIN 20 of IDE interface to +5V to support DOMs without the need for a power cable.
6. IDE_IRQ to be routed to the CPLD (additional reason why IDE.device was used). Additionally add IDE_WAIT to the CPLD to have the option to support /DTACK Waitstates.
7. Add XTAL Clock buffer.
8. Change RAM Control signals to have /CS tied to GND and connect /OE and /WR to CPLD. RAM access can be faster.
9. Support a cascaded AutoConfig chain (implemented - still to be tested).
