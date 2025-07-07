`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 10:55:25 PM
// Design Name: 
// Module Name: tb_Interleaved_Modular_
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


module tb_Interleaved_Modular();
    parameter N = 256;

    reg clk = 0;
    reg reset = 0;
    reg start = 0;
    reg [N-1:0] X;
    reg [N-1:0] Y;
    wire [N-1:0] Z;
    wire done;

    // DUT
    Interleaved_Modular_Multi #(N) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .X(X),
        .Y(Y),
        .Z(Z),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // === Vector kiểm thử: bạn có thể đổi để khớp với Python ===
        X = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEC;
        Y = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEB;

        // === Reset ===
        reset = 1; #10;
        reset = 0; #10;

        // === Start ===
        start = 1; #10;
        start = 0;

        // === Đợi DONE và in kết quả ===
        wait (done);
        $display("==== VERILOG RESULT ====");
        $display("X = 0x%h", X);
        $display("Y = 0x%h", Y);
        $display("Z = 0x%h", Z);
        $finish;
    end
endmodule
