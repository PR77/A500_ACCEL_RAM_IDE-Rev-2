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
