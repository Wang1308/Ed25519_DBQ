`timescale 1ns / 1ps

module RAM_Y_GEN_tb();

    reg clk, rst;
    reg [255:0] Y;
    reg init_en;
    reg [2:0] addr;
    wire [255:0] data_out;

    // Instantiate the module under test
    ramY_2 uut (
        .clk(clk),
        .rst(rst),
        .Y(Y),
        .init_en(init_en),
        .addr(addr),
        .data_out(data_out)
    );

    // Expected output from test vector file
    reg [255:0] expected_mem [0:7];

    integer i, testfile, r;
    reg [1023:0] line;

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        init_en = 0;
        addr = 0;

        // Reset
        #20;
        rst = 0;

        // Open test vector file
        testfile = $fopen("/home/bowang1308/Documents/Ed25519_DBQ/Test vector/test_vectors.txt", "r");
        if (testfile == 0) begin
            $display("ERROR: Cannot open test vector file!");
            $finish;
        end

        // Read Y (line 1)
        r = $fscanf(testfile, "%h\n", Y);
        $display("Y = %h", Y); // Y=p-1 

        // Read 8 expected values
        for (i = 0; i < 8; i = i + 1) begin
            r = $fscanf(testfile, "%h\n", expected_mem[i]);
            $display("Expected mem[%0d] = %h", i, expected_mem[i]);
        end

        // Start RAM loading
        init_en = 1;
        #10;
        init_en = 0;

        // Wait enough cycles for computation (8 cycles + margin)
        #600;

        // Compare results
        for (i = 0; i < 8; i = i + 1) begin
            addr = i;
            #8;
            if (data_out !== expected_mem[i]) begin
                $display("FAIL: mem[%0d] = %h, expected %h", i, data_out, expected_mem[i]);
            end else begin
                $display("PASS: mem[%0d] = %h", i, data_out);
            end
        end

        $fclose(testfile);
        $finish;
    end

endmodule
