`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2025 02:29:13 PM
// Design Name: 
// Module Name: mod_p
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


module mod_p(
    input  wire [511:0] X,            // 512-bit input
    output wire [254:0] result        // 255-bit output result = X mod p
);

    // Constants
    localparam [254:0] P  = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
    localparam [255:0] MU = 256'h8000000000000000000000000000000000000000000000000000000000000013; // floor(2^510 / p)

    // Step 1: q1 = floor(X / 2^(k-1)) = X >> 254
    wire [257:0] q1 = X[511:254]; // 258 bits: from bit 254 to bit 511

    // Step 2: q2 = q1 * μ
    wire [513:0] q2 = q1 * MU; // 258 + 256 = max 514 bits

    // Step 3: q3 = floor(q2 / 2^(k+1)) = q2 >> 256
    wire [257:0] q3 = q2[513:256];

    // Step 4: q3 * p
    wire [512:0] qp = q3 * P;

    // Step 5: r = X - q3*p
    wire [512:0] r_full = {1'b0, X} - qp;

    // Step 6: if r >= p then r = r - p else r
    wire ge_p = (r_full[512:255] > 0) || (r_full[254:0] >= P);
    wire [255:0] r_sub_p = r_full[254:0] - P;
    wire [254:0] r_final = ge_p ? r_sub_p[254:0] : r_full[254:0];

    assign result = r_final;
endmodule
