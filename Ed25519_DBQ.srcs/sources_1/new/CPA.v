`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2025 11:28:18 AM
// Design Name: 
// Module Name: CPA
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


module CPA #(parameter WIDTH = 256)(
    input  wire [WIDTH-1:0] sum_in,
    input  wire [WIDTH-1:0]   carry_in,
    output wire [WIDTH-1:0] result,
    output wire             cout
);
    wire [WIDTH:0] temp_sum;
    assign temp_sum = {1'b0, sum_in} + carry_in;
    assign result   = temp_sum[WIDTH-1:0];
    assign cout     = temp_sum[WIDTH];
endmodule

