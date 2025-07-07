`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2025 01:19:48 PM
// Design Name: 
// Module Name: CSA_tb 
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


module CSA_tb();
    parameter WIDTH = 8;
    parameter NUM_VECTORS = 5;

    reg [WIDTH-1:0] in1, in2, in3;
    wire [WIDTH-1:0] sum, carry;

    reg [WIDTH-1:0] tv_in1   [0:NUM_VECTORS-1];
    reg [WIDTH-1:0] tv_in2   [0:NUM_VECTORS-1];
    reg [WIDTH-1:0] tv_in3   [0:NUM_VECTORS-1];
    reg [WIDTH-1:0] tv_sum   [0:NUM_VECTORS-1];
    reg [WIDTH-1:0] tv_carry [0:NUM_VECTORS-1];

    integer i;

    // Instantiate CSA
    CSA #(WIDTH) dut (
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .sum(sum),
        .carry(carry)
    );

    initial begin
        // === Test vectors ===
        tv_in1[0]   = 8'h00; tv_in2[0]   = 8'h00; tv_in3[0]   = 8'h00; // 0 + 0 + 0
        tv_sum[0]   = 8'h00; tv_carry[0] = 8'h00;

        tv_in1[1]   = 8'hFF; tv_in2[1]   = 8'h01; tv_in3[1]   = 8'h01; // FFFF + 1 + 1
        tv_sum[1]   = 8'hFF; tv_carry[1] = 8'h02;

        tv_in1[2]   = 8'hAA; tv_in2[2]   = 8'h55; tv_in3[2]   = 8'hFF;
        tv_sum[2]   = 8'h00; tv_carry[2] = 8'hFE;

        tv_in1[3]   = 8'hF0; tv_in2[3]   = 8'h0F; tv_in3[3]   = 8'hF0;
        tv_sum[3]   = 8'h0F; tv_carry[3] = 8'hE0;

        tv_in1[4]   = 8'h01; tv_in2[4]   = 8'h02; tv_in3[4]   = 8'h04;
        tv_sum[4]   = 8'h07; tv_carry[4] = 8'h00;

        //  Bắt đầu kiểm tra 
        for (i = 0; i < NUM_VECTORS; i = i + 1) begin
            in1 = tv_in1[i];
            in2 = tv_in2[i];
            in3 = tv_in3[i];
            #5;
            if (sum !== tv_sum[i] || carry !== tv_carry[i]) begin
                $display("Test %0d FAILED", i);
                $display("in1 = %h, in2 = %h, in3 = %h", in1, in2, in3);
                $display("Expected sum = %h, carry = %h", tv_sum[i], tv_carry[i]);
                $display("Got      sum = %h, carry = %h\n", sum, carry);
            end else begin
                $display("Test %0d PASSED", i);
            end
        end

        $finish;
    end

endmodule
