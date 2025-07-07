`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ompany: Học viện kỹ thuật Mật Mã 
// Engineer: Đỗ Bá Quang
// 
// Create Date: 05/27/2025 01:28:03 PM
// Design Name: Ed25519 
// Module Name: REG
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


module REG #(parameter WIDTH = 256)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    always @(posedge clk or posedge rst) begin
        if (rst) dout <= 0;
        else if (en) dout <= din;
    end
endmodule
