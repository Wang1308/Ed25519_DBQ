`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2025 01:30:24 PM
// Design Name: 
// Module Name: REG_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module REG_tb();
    parameter WIDTH = 256;
    
    reg clk;
    reg rst;
    reg en;
    reg [WIDTH-1:0] din;
    wire [WIDTH-1:0] dout;

    // Instantiate the REG module
    REG #(WIDTH) uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .din(din),
        .dout(dout)
    );

    // Clock generation: 10ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        rst = 1;
        en = 0;
        din = 0;

        // Wait 20 ns, then release reset
        #20;
        rst = 0;

        // Test vector 1: Write 0xAA...AA with enable=1
        din = {WIDTH{1'b1}}; // all bits = 1 (0xFF...FF)
        en = 1;
        #10; // wait 1 clock cycle

        // Test vector 2: Write 0x55...55 with enable=1
        din = {WIDTH{1'b0}};
        din[0] = 1; din[2] = 1; din[4] = 1; // just some pattern
        // Actually better to write a pattern, for demo just invert bits
        din = ~din;
        #10;

        // Test vector 3: Disable enable, change din, dout should stay the same
        en = 0;
        din = {WIDTH{1'b0}};
        #10;

        // Test vector 4: Enable = 1, write zero
        en = 1;
        din = 0;
        #10;

        // Finish simulation
        $finish;
    end

    // Monitor output
    initial begin
        $monitor("Time=%0t | rst=%b en=%b din=0x%h dout=0x%h", $time, rst, en, din, dout);
    end
endmodule
