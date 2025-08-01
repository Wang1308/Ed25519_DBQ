`timescale 1ns / 1ps

module tb_mod_p_ed25519_seq;

    logic clk;
    logic rst_n;
    logic start;
    logic [511:0] X;
    logic [254:0] Z;
    logic done;

    // Instantiate DUT
    mod_p_ed25519_seq dut (
        .clk(clk),
        .rst(rst_n),
        .start(start),
        .X(X),
        .Z(Z),
        .done(done)
    );
    localparam [254:0] P = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
    // Clock generator
    always #5 clk = ~clk; // 100MHz

    // Main test process
    initial begin
        $display("===== TEST: mod_p_ed25519_seq =====");
        clk = 0;
        rst_n = 1;
        start = 0;
        X = 0;

        // Reset
        #20;
        rst_n = 0;

        // Test vector: X = 2^510 - 1
        X = (512'd1 << 500) + 123456789;
        start = 1;
        #10;
        start = 0;

        // Wait for result
        wait (done == 1);
        #10;

        $display("Input  X = %h", X);
        $display("Output Z = %h", Z);

        // Optional: check expected result
        // localparam [254:0] p = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
        // Expected result = X mod p

        // End simulation
        $stop;
    end

endmodule
