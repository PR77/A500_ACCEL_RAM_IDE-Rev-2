`timescale 1ns / 1ps

module MC6800_EMULATION(

    input RESET,
    input MB_CLK,
    input CPU_CLK,
    
    input CPU_AS,
       
    output MC6800_DTACK,
    
    output reg MB_E_CLK,
    input MB_VPA,    
    output MB_VMA,
        
    input [2:0]	CPU_FC

    );
    
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
        MC6800_DTACK <= 1'b1;
    end
    
    if (CPU_AS == 1'b1) begin
        MC6800_DTACK <= 1'b1;
    end else begin
               
        if (eClockRingCounter == 'd9) begin
            MC6800_DTACK <= 1'b1;
        end

        if (eClockRingCounter == 'd8) begin
            MC6800_DTACK <= MC6800VMA;
        end
    end 
end

assign MB_VMA = MC6800VMA;

endmodule