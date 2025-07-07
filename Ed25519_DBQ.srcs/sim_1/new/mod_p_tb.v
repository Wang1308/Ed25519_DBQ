`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2025 02:32:09 PM
// Design Name: 
// Module Name: mod_p_tb
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


module mod_p_tb();

    reg  [511:0] X;
    wire [254:0] result;

    // Instantiate the Unit Under Test (UUT)
    mod_p uut (
        .X(X),
        .result(result)
    );

    // Constant p = 2^255 - 19
    localparam [254:0] P = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

    initial begin
        $display("===== Test Barrett Reduction =====");

        // Test 1: X < p
        X = 512'd123456789;
        #10;
        $display("Test 1: X =%d", X);
        $display("Result =%d", result);
        $display("Expected =%d\n", X % P);

        // Test 2: X = p
        X = {257'd0, P}; // Zero-extend P to 512 bits
        #10;
        $display("Test 2: X = P =%d", X);
        $display("Result =%d", result);
        $display("Expected =%d\n", 0);

        // Test 3: X = p + 1
        X = {257'd0, P} + 1;
        #10;
        $display("Test 3: X = p + 1 =%d", X);
        $display("Result =%d", result);
        $display("Expected =%d\n", 1);

        // Test 4: X = 2*p
        X = {257'd0, P} << 1;
        #10;
        $display("Test 4: X = 2*p =%d", X);
        $display("Result =%d", result);
        $display("Expected =%d\n", 0);

        // Test 5: X = 2^500 + 123456789
        X = (512'd1 << 500) + 123456789;
        #10;
        $display("Test 5: X = 2^500 + 123456789");
        $display("Result =%d", result);
        $display("Expected = 1074243015385257672386644880451694457623110209300376326537936570386036280597\n");

        // Test 6: Maximum 512-bit value
        X = 512'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #10;
        $display("Test 6: X = 512'hFFFFFFFF...FFFF");
        $display("Result =%d", result);
        $display("Expected = 1443\n");

        $finish;
    end
endmodule
