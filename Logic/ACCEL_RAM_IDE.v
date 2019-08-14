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
    input           MB_CLK,
    input           CPU_CLK,

    input           CPU_AS_n,
    output          MB_AS_n,

    input           MB_DTACK_n,
    output          CPU_DTACK_n,

    input           RESET_n,

    output reg      MB_E_CLK,
    input           MB_VPA,
    output          MB_VMA,

    input   [2:0]   CPU_FC,
    output  [2:0]   CPU_IPL,
    input           CPU_BR,
    input           CPU_BG,
    input           MB_BGAK,
    output          BERR,
    output          CPU_AVEC,
    input           RW,
    input           LDS_n,
    input           UDS_n,
    input           HALT_n,

    output          IDE_RW_n,
    output  [1:0]   IDE_CS_n,
    output          IDE_RESET_n,
    output          IDE_READ_n,
    output          IDE_WRITE_n,

    output  [3:0]   RAM_CS_n,

    output          SPI_CS_n,
    output          SPI_MOSI,
    output          SPI_SCK,
    input           SPI_MISO,

    output  [1:0]   IO_PORT,
    input           SPARE_NO_CONNECT,

    input   [23:1]  ADDRESS,
    inout   [15:0]  DATA
    );

assign BERR = 1'bZ;
assign CPU_AVEC = 1'bZ;
assign CPU_IPL = 3'bZZZ;

reg autoConfigDevice = 1'd0;
wire autoConfigAddress = ADDRESS[23:16] == 8'hE8 && autoConfigDevice != 1'd1;

reg [7:0] fastRamBase = 8'h0;
reg fastRamBaseValid = 1'b0;
wire fastRamAddress = ADDRESS[23:20] == fastRamBase[7:4] && fastRamBaseValid;

wire internalAddress = autoConfigAddress || fastRamAddress;

reg [1:0] extraRamCsDrive = 2'b11;

assign RAM_CS_n[3:2] = 2'b11;
assign RAM_CS_n[1:0] = extraRamCsDrive & (!CPU_AS_n && fastRamAddress ? {UDS_n, LDS_n} : 2'b11);

reg mbAsReq = 1'b0;
reg mbAsAck = 1'b0;
assign MB_AS_n = !(mbAsReq != mbAsAck);

// Acknowledge an internal (FastRAM, AutoConfig) data transfer.
reg internalDtackReq = 1'b0;
reg internalDtackAck = 1'b0;
wire internalDtack = internalDtackReq != internalDtackAck;

// Acknowledge an external data transfer.
reg externalDtackReq = 1'b0;
reg externalDtackAck = 1'b0;
wire externalDtack = externalDtackReq != externalDtackAck;

// Acknowledge a MC6800 emulation transfer.
reg mc6800DtackReq = 1'b0;
reg mc6800DtackAck = 1'b0;
wire mc6800Dtack = mc6800DtackReq != mc6800DtackAck;

assign CPU_DTACK_n = !(internalDtack || externalDtack || mc6800Dtack);

reg [1:0] internalCycleCounter = 2'd0;
reg [1:0] externalCycleCounter = 2'd0;

reg externalAccessReq = 1'b0;
reg externalAccessAck = 1'b0;

reg driveAutoConfigData = 1'b0;
reg [3:0] autoConfigData = 4'd0;
assign DATA[15:12] = driveAutoConfigData && !CPU_AS_n ? autoConfigData : 4'bZZZZ;

MC6800_EMULATION MC6800(

    .RESET          (RESET),
    .MB_CLK         (MB_CLK),
    .CPU_CLK        (CPU_CLK),
    
    .CPU_AS         (CPU_AS),
       
    .MC6800_DTACK   (mc6800DtackReq),
    
    .MB_E_CLK       (MB_E_CLK),
    .MB_VPA         (MB_VPA),    
    .MB_VMA         (MB_VMA),
        
    .CPU_FC         (CPU_FC)
);

always @(negedge CPU_AS_n)
begin
    if (!internalAddress)
        externalAccessReq <= !externalAccessAck;
end

always @(posedge CPU_AS_n)
begin
    mbAsAck <= mbAsReq;
    internalDtackAck <= internalDtackReq;
    externalDtackAck <= externalDtackReq;
    mc6800DtackAck <= mc6800DtackReq;
end

always @(negedge CPU_CLK)
begin
    if (internalCycleCounter == 2'd0)
    begin
        if (!CPU_AS_n && internalAddress)
            internalCycleCounter <= 2'd1;
    end
    else
        internalCycleCounter <= internalCycleCounter + 2'd1;
end

always @(posedge CPU_CLK)
begin
    if (internalCycleCounter == 2'd1)
    begin
        internalDtackReq <= (!internalDtackAck);
    end
    else if (internalCycleCounter == 2'd2)
    begin
        if (fastRamAddress && !RW)
            extraRamCsDrive <= {UDS_n, LDS_n};
    end
    else if (internalCycleCounter == 2'd3)
    begin
        extraRamCsDrive <= 2'b11;
    end
end

always @(posedge MB_CLK)
begin
    if (externalCycleCounter == 2'd0 && externalAccessReq != externalAccessAck)
    begin
        mbAsReq <= !mbAsAck;
        externalAccessAck <= externalAccessReq;
    end
end

always @(negedge MB_CLK)
begin
    case (externalCycleCounter)
    2'd0:
        if (!MB_AS_n)
            externalCycleCounter <= 2'd1;
    2'd1:
        if (!MB_DTACK_n)
            externalCycleCounter <= 2'd2;
    2'd2:
    begin
        externalDtackReq <= !externalDtackAck;
        externalCycleCounter <= 2'd3;
    end
    2'd3:
        externalCycleCounter <= 2'd0;
    endcase
end

// Handle auto config access.
always @(negedge CPU_CLK)
begin
    if (internalCycleCounter == 2'd1)
    begin
        if (autoConfigAddress)
            if (RW) // Read
            begin
                driveAutoConfigData <= 1'b1;
                if (ADDRESS[7:6] == 2'd0)
                    case (ADDRESS[5:1])
                        5'h00: autoConfigData <= 4'hE;  // (00) FastRAM
                        5'h01: autoConfigData <= 4'h5;  // (02) FastRAM

                        5'h02: autoConfigData <= 4'h9;  // (04)  
                        5'h03: autoConfigData <= 4'h8;  // (06) FastRAM

                        5'h04: autoConfigData <= 4'h7;  // (08/0A)
                        5'h05: autoConfigData <= 4'hF;
                        
                        5'h06: autoConfigData <= 4'hF;  // (0C/0E)
                        5'h07: autoConfigData <= 4'hF;
                        
                        5'h08: autoConfigData <= 4'hF;  // (10/12)
                        5'h09: autoConfigData <= 4'h8;
                        5'h0A: autoConfigData <= 4'h4;  // (14/16)
                        5'h0B: autoConfigData <= 4'h6;                
                        
                        5'h0C: autoConfigData <= 4'hA;  // (18/1A)
                        5'h0D: autoConfigData <= 4'hF;
                        5'h0E: autoConfigData <= 4'hB;  // (1C/1E)
                        5'h0F: autoConfigData <= 4'hE;
                        5'h10: autoConfigData <= 4'hA;  // (20/22)
                        5'h11: autoConfigData <= 4'hA;
                        5'h12: autoConfigData <= 4'hB;  // (24/26)
                        5'h13: autoConfigData <= 4'h3;

                        default: autoConfigData <= 4'hF;
                    endcase
                else
                    autoConfigData <= 4'hF;
            end
            else    // Write
            begin
                if (ADDRESS[7:1] == 7'h24) // Written second
                begin
                    fastRamBase[7:4] <= DATA[15:12];
                    fastRamBaseValid <= 1'b1;
                    autoConfigDevice <= autoConfigDevice + 1'd1;
                end
                else if (ADDRESS[7:1] == 7'h25) // Written first
                begin
                    fastRamBase[3:0] <= DATA[15:12];
                end
                else if (ADDRESS[7:1] == 7'h26)
                    autoConfigDevice <= autoConfigDevice + 1'd1;
            end
    end
    
    else if (internalCycleCounter == 2'd3)
        driveAutoConfigData <= 1'b0;
end

endmodule