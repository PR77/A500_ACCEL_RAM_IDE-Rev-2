`timescale 1ns / 1ps
/*
    This file is part of A500_ACCEL_RAM_IDE originally designed by
    Paul Raspa 2017-2018.

    A500_ACCEL_RAM_IDE is free software: you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    A500_ACCEL_RAM_IDE is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with A500_ACCEL_RAM_IDE. If not, see <http://www.gnu.org/licenses/>.

    Revision 0.0 - 20.02.2018:
    Initial revision of revision 2 design.
    
    Revision 0.1 - 03.07.2018
    Update for revision 3 of design.
*/

 module ACCEL_RAM_IDE(

    input RESET,
    input MB_CLK,
    input CPU_CLK,
    
    input CPU_AS,
    output MB_AS,
       
    input MB_DTACK,
    output CPU_DTACK,
    
    output reg MB_E_CLK,
    input MB_VPA,    
    output MB_VMA,
        
    input [2:0]	CPU_FC,
    output [2:0] CPU_IPL,
    input CPU_BR,
    input CPU_BG,
    input MB_BGAK,
    output BERR,
    output CPU_AVEC,
    input RW,
    input LDS,
    input UDS,
    input HALT,
        
    // IDE
    output IDE_RW,
    output [1:0] IDE_CS,
    output IDE_RESET,
    output IDE_READ,
    output IDE_WRITE,
    
    // RAM
    output [3:0] RAM_CS,
    
    // SPI
    output SPI_CS,
    output SPI_MOSI,
    output SPI_SCK,
    input SPI_MISO,
    
    // IO Port
    output [1:0] IO_PORT,
    
    // SPARE
    input SPARE_NO_CONNECT,
    
    // Address bus
    input [23:1] ADDRESS,
    
    // Data bus
    inout [15:0] DATA

    );
    
assign BERR = 1'bZ;
assign CPU_AVEC = 1'bZ;
assign CPU_IPL = 3'bZZZ;

// --- AUTOCONFIG

reg [2:0] configured = 3'b000;
reg [2:0] shutup = 3'b000;
reg [3:0] autoConfigData = 4'b0000;
reg [7:0] autoConfigBaseFastRam = 8'b00000000;
reg [7:0] autoConfigBaseSPI = 8'b00000000;
reg [7:0] autoConfigBaseIOPort = 8'b00000000;

wire DS = (LDS & UDS);

wire AUTOCONFIG_RANGE = ({ADDRESS[23:16]} == {8'hE8}) && ~CPU_AS && ~DS && ~(&shutup && &configured);
wire AUTOCONFIG_READ = (AUTOCONFIG_RANGE && (RW == 1'b1));
wire AUTOCONFIG_WRITE = (AUTOCONFIG_RANGE && (RW == 1'b0));

wire IDE_RANGE = ({ADDRESS[23:16]} == {8'hEF}) && ~CPU_AS && ~DS;

wire FASTRAM_RANGE = ({ADDRESS[23:20]} == {autoConfigBaseFastRam[7:4]}) && ~CPU_AS && ~DS && configured[0];
wire SPI_RANGE = ({ADDRESS[23:20]} == {autoConfigBaseSPI[7:4]}) && ~CPU_AS && ~DS && configured[1];
wire IOPORT_RANGE = ({ADDRESS[23:16]} == {autoConfigBaseIOPort[7:0]}) && ~CPU_AS && ~DS && configured[2];

// AUTOCONFIG cycle.
always @(negedge DS or negedge RESET) begin

    // Use DS as the entry point to keep this out of a specific clock domain.
    
    if (RESET == 1'b0) begin
        configured[2:0] <= 3'b000; 
        shutup[2:0] <= 3'b000;     
        autoConfigBaseFastRam[7:0] <= 8'h0;
        autoConfigBaseSPI[7:0] <= 8'h0;
        autoConfigBaseIOPort[7:0] <= 8'h0;
    end else begin

       if (AUTOCONFIG_WRITE == 1'b1) begin
            // AutoConfig Write sequence. Here is where we receive from the OS the base address for the RAM.
            case (ADDRESS[7:1])
                8'h24: begin
                // Written second
                    if (configured[2:0] == 3'b000) begin
                        autoConfigBaseFastRam[7:4] <= DATA[15:12];      // FastRAM
                        configured[0] <= 1'b1;
                    end
                    
                    if (configured[2:0] == 3'b001) begin
                        autoConfigBaseSPI[7:4] <= DATA[15:12];          // SPI
                        configured[1] <= 1'b1;
                    end
                    
                    if (configured[2:0] == 3'b011) begin
                        autoConfigBaseIOPort[7:4] <= DATA[15:12];       // IO Port
                        configured[2] <= 1'b1;
                    end
                end

                8'h25: begin
                // Written first
                    if ({configured[2:0] == 3'b000}) autoConfigBaseFastRam[3:0] <= DATA[15:12]; // FastRAM
                    if ({configured[2:0] == 3'b001}) autoConfigBaseSPI[3:0] <= DATA[15:12];     // SPI
                    if ({configured[2:0] == 3'b011}) autoConfigBaseIOPort[3:0] <= DATA[15:12];  // IO Port
                end

                8'h26: begin
                // Written last
                    if ({configured[2:0] == 3'b001}) shutup[0] <= 1'b1;   // FastRAM
                    if ({configured[2:0] == 3'b011}) shutup[1] <= 1'b1;   // IO Port A
                    if ({configured[2:0] == 3'b111}) shutup[2] <= 1'b1;   // IO Port B
                end
                
            endcase
        end

        if (AUTOCONFIG_READ == 1'b1) begin
            // AutoConfig Read sequence. Here is where we publish the RAM and I/O port size and hardware attributes.
           case (ADDRESS[7:1])
                8'h00: begin
                    if ({configured[2:0] == 3'b000}) autoConfigData <= 4'hE;     // (00) FastRAM
                    if ({configured[2:0] == 3'b001}) autoConfigData <= 4'hC;     // (00) SPI
                    if ({configured[2:0] == 3'b011}) autoConfigData <= 4'hC;     // (00) IO Port
                end
                
                8'h01: begin
                    if ({configured[2:0] == 3'b000}) autoConfigData <= 4'h5;     // (02) FastRAM
                    if ({configured[2:0] == 3'b001}) autoConfigData <= 4'h4;     // (02) SPI
                    if ({configured[2:0] == 3'b011}) autoConfigData <= 4'h1;     // (02) IO Port
                end
                
                8'h02: autoConfigData <= 4'h9;     // (04)  
                
                8'h03: begin
                    if ({configured[2:0]} == {3'b000}) autoConfigData <= 4'h8;     // (06) FastRAM
                    if ({configured[2:0]} == {3'b001}) autoConfigData <= 4'h9;     // (06) SPI
                    if ({configured[2:0]} == {3'b011}) autoConfigData <= 4'hA;     // (06) IO Port
                end

                8'h04: autoConfigData <= 4'h7;  // (08/0A)
                8'h05: autoConfigData <= 4'hF;
                
                8'h06: autoConfigData <= 4'hF;  // (0C/0E)
                8'h07: autoConfigData <= 4'hF;
                
                8'h08: autoConfigData <= 4'hF;  // (10/12)
                8'h09: autoConfigData <= 4'h8;
                8'h0A: autoConfigData <= 4'h4;  // (14/16)
                8'h0B: autoConfigData <= 4'h6;                
                
                8'h0C: autoConfigData <= 4'hA;  // (18/1A)
                8'h0D: autoConfigData <= 4'hF;
                8'h0E: autoConfigData <= 4'hB;  // (1C/1E)
                8'h0F: autoConfigData <= 4'hE;
                8'h10: autoConfigData <= 4'hA;  // (20/22)
                8'h11: autoConfigData <= 4'hA;
                8'h12: autoConfigData <= 4'hB;  // (24/26)
                8'h13: autoConfigData <= 4'h3;

                default: 
                    autoConfigData <= 4'hF;

            endcase
        end
     end
end

// Output specific AUTOCONFIG data.
assign DATA[15:12] = (AUTOCONFIG_READ == 1'b1 /*&& ~DS && ~&shutup*/) ? autoConfigData : 4'bZZZZ;

// --- RAM Control

// RAM control arbitration.
assign RAM_CS[3:0] = FASTRAM_RANGE ? {1'b1, 1'b1, UDS, LDS} : {1'b1, 1'b1, 1'b1, 1'b1};

// --- IDE Control

// IDE Port arbitrations.
assign IDE_CS[1:0] = ADDRESS[12] ? {~IDE_RANGE, 1'b1} : {1'b1, ~IDE_RANGE};
assign IDE_RESET = RESET;
assign IDE_READ = ((IDE_RANGE == 1'b1) && (RW == 1'b1)) ? 1'b0 : 1'b1;
assign IDE_WRITE = ((IDE_RANGE == 1'b1) && (RW == 1'b0)) ? 1'b0 : 1'b1;

// 74HCT245 Direction Control. HIGH: A(in) = B(out), LOW: B(in) = A(out).
assign IDE_RW = (IDE_READ == 1'b0) ? 1'b0 : 1'b1;

// --- IO Port Control

reg [1:0] IOPORTData = 2'h0;

// Latch D[15:14] to local IO Port Register during rising edge to S6.
always @(negedge CPU_CLK or negedge RESET) begin

    if (RESET == 1'b0) begin
        IOPORTData[1:0] <= 2'h0;
    end else begin

        if ((IOPORT_RANGE == 1'b1) && (RW == 1'b0))
            IOPORTData[1:0] <= DATA[15:14];
    end
end

// IO Port arbitrations.
assign IO_PORT[1:0] = IOPORTData[1:0];

// --- MC6800 Emulator --- Credit to TerribleFire for all the help with this

reg [3:0] eClockRingCounter = 4'h4;
reg MC6800VMA = 1'b1;
reg MC6800DTACK = 1'b1;

wire CPUSPACE = &CPU_FC;

// Let's get the 709379 Hz E_CLOCK out the way by creating it from the motherboard base 7MHz Clock.
always @(posedge MB_CLK) begin
    
    if (eClockRingCounter == 'd9) begin
        eClockRingCounter <= 'd0;
        
    end else begin
    
        eClockRingCounter <= eClockRingCounter + 'd1;

        if (eClockRingCounter == 'd4) begin
            MB_E_CLK <= 'b1;       
        end

        if (eClockRingCounter == 'd8) begin
            MB_E_CLK <= 'b0;
        end
    end
end

// Determine if current Bus Cycle is a 6800 type where VPA has been asserted.
always @(posedge MB_CLK or posedge MB_VPA) begin

    if (RESET == 1'b0) begin
        MC6800VMA <= 1'b1;
    end

    if (MB_VPA == 1'b1) begin
        MC6800VMA <= 1'b1;
    end else begin

        if (eClockRingCounter == 'd9) begin
            MC6800VMA <= 1'b1;
        end

        if (eClockRingCounter == 'd2) begin
            MC6800VMA <= MB_VPA | CPUSPACE;
        end
    end
end

// Generate /DTACK if 6800 Bus Cycle has been emulated (generatedVMA).
always @(posedge MB_CLK or posedge CPU_AS) begin
    
    if (RESET == 1'b0) begin
        MC6800DTACK <= 1'b1;
    end
    
    if (CPU_AS == 1'b1) begin
        MC6800DTACK <= 1'b1;
    end else begin
               
        if (eClockRingCounter == 'd9) begin
            MC6800DTACK <= 1'b1;
        end

        if (eClockRingCounter == 'd8) begin
            MC6800DTACK <= MC6800VMA;
        end
    end 
end

assign MB_VMA = MC6800VMA;

// --- Accelerator

reg delayedMB_AS = 1'b1;
reg delayedMB_DTACK = 1'b1;
reg fastCPU_DTACK = 1'b1;
reg slowCPU_DTACK = 1'b1;

reg [3:0] SLOW_DTACK_WAITSTATES = 4'b0000;

// Shift /CPU_AS into the 7MHz clock domain gated by FASTRAM_RANGE | AUTOCONFIG_RANGE | IDE_RANGE
// (MB_AS is not asserted during internal cycles). Delay /MB_DTACK by 1 7MHz clock cycle to sync
// up to asynchronous CPU_CLK.
always @(posedge MB_CLK or posedge CPU_AS) begin
    
    if (CPU_AS == 1'b1) begin
        delayedMB_DTACK <= 1'b1;
        delayedMB_AS <= 1'b1;
    end else begin
    
        delayedMB_AS <= CPU_AS | FASTRAM_RANGE | AUTOCONFIG_RANGE | IDE_RANGE;
        delayedMB_DTACK <= MB_DTACK;
    end
end

// Generate a slow DTACK for slow interal space resources.
always @(posedge CPU_CLK or posedge CPU_AS) begin
    
    if (CPU_AS == 1'b1) begin
        SLOW_DTACK_WAITSTATES <= 4'b0000;
        slowCPU_DTACK <= 1'b1;
    end else begin
    
        if (IDE_RANGE == 1'b1 || AUTOCONFIG_RANGE == 1'b1) begin
            SLOW_DTACK_WAITSTATES <= SLOW_DTACK_WAITSTATES + 1;
            
            if (&SLOW_DTACK_WAITSTATES) begin
                slowCPU_DTACK <= 1'b0;
            end
        end
    end
end

// Generate a fast DTACK for fast interal space resources.
always @(posedge CPU_CLK or posedge CPU_AS) begin
    
    if (CPU_AS == 1'b1) begin
        fastCPU_DTACK <= 1'b1;
    end else begin
    
        fastCPU_DTACK <= ~FASTRAM_RANGE;
               
        // SPI_RANGE and IOPORT_RANGE are handled with slow /DTACKS via GARY.
    end
end

assign CPU_DTACK = (delayedMB_DTACK & fastCPU_DTACK & slowCPU_DTACK & MC6800DTACK);
assign MB_AS = (MB_BGAK && HALT) ? delayedMB_AS : 1'bZ;

endmodule
