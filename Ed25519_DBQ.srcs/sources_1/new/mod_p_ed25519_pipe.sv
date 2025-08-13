module mod_p_ed25519_pipe (
    input  logic         clk,
    input  logic         rst,
    input  logic [511:0] X,
    output logic [254:0] Z
);
    localparam [254:0] P = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

    // Stage 1: Tách X thành X_low và X_high, pre-reduce nếu >= P
    logic [254:0] X_low_s1;
    logic [256:0] X_high_s1;

    // Stage 2: Tính temp_sum = X_low + X_high * 19
    logic [260:0] temp_sum_s2;

    // Stage 3: Giảm mod P
    logic [260:0] temp_sum_s3;

    // ============================
    // Stage 1
    // ============================
    always_ff @(posedge clk) begin
        if (rst) begin
            X_low_s1  <= 0;
            X_high_s1 <= 0;
        end else begin
            X_low_s1  <= (X[254:0] >= P) ? X[254:0] - P : X[254:0];
            X_high_s1 <= (X[511:255] >= P) ? X[511:255] - P : X[511:255];
        end
    end

    // ============================
    // Stage 2
    // ============================
    always_ff @(posedge clk) begin
        if (rst)
            temp_sum_s2 <= 0;
        else
            temp_sum_s2 <= X_low_s1 + (X_high_s1 << 4) + (X_high_s1 << 1) + X_high_s1; // x19
    end

    // ============================
    // Stage 3
    // ============================
    always_ff @(posedge clk) begin
        if (rst)
            temp_sum_s3 <= 0;
        else
            temp_sum_s3 <= temp_sum_s2;
    end

    // Output (sau stage 3)
    always_ff @(posedge clk) begin
        if (rst)
            Z <= 0;
        else
            Z <= (temp_sum_s3 >= P) ? temp_sum_s3 - P : temp_sum_s3[254:0];
    end

endmodule
