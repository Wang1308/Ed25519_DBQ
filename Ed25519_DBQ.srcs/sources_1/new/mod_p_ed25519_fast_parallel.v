module mod_p_ed25519_fast_parallel (
    input  wire [511:0] A,      // 512-bit input
    output wire [254:0] Q       // Output: A mod p, where p = 2^255 - 19
);

    // Prime p = 2^255 - 19
    localparam [254:0] P = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

    // (1) T = A[127:0]
    wire [127:0] T_raw = A[127:0];
    wire [260:0] T = {134'd0, T_raw};  // Extend to 261 bits

    // Extract A128–A255 for use in multiple terms
    wire [127:0] A128_255 = A[255:128];

    // (2) S1 = A128_255 << 5
    wire [260:0] S1 = {133'd0, A128_255} << 5;

    // (3) S2 = A128_255 << 3
    wire [260:0] S2 = {133'd0, A128_255} << 3;

    // (4) S3 = (A[254:247] << 4)
    wire [7:0] A254_247 = A[254:247];
    wire [260:0] S3 = {253'd0, A254_247, 4'd0};

    // (5) S4 = (A[253:249] << 2)
    wire [5:0] A253_249 = A[253:249];
    wire [260:0] S4 = {255'd0, A253_249, 2'd0};

    // (6) S5 = (A[254:249] << 4)
    wire [6:0] A254_249 = A[254:248];
    wire [260:0] S5 = {253'd0, A254_249, 4'd0};

    // (7) D1 = A128_255 << 1
    wire [260:0] D1 = {133'd0, A128_255} << 1;

    // (8) D2 = A[254] ? (1 << 253) : 0
    wire [260:0] D2 = A[254] ? (261'd1 << 253) : 261'd0;

    // (9) D3 = A[253] ? (1 << 253) : 0
    wire [260:0] D3 = A[253] ? (261'd1 << 253) : 261'd0;

    // (10) Final Q = (T + S1 + S2 + S3 + S4 + S5 - D1 - D2 - D3) mod p
    wire [260:0] Q_temp = T + S1 + S2 + S3 + S4 + S5 - D1 - D2 - D3;

    // Reduce mod p = 2^255 - 19
    assign Q = (Q_temp[260:255] != 0 || Q_temp[254:0] >= P) ?
               Q_temp[254:0] - P :
               Q_temp[254:0];

endmodule
