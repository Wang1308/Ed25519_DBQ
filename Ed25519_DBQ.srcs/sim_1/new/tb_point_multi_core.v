`timescale 1ns / 1ps

module tb_point_multi_core;

    parameter WID = 256;
    parameter NUM_VECTORS = 3;

    reg clk = 0;
    reg rst;
    reg start;
    reg [WID-1:0] k, px, py;
    wire [WID-1:0] qx, qy;
    wire done;

    // Instantiate DUT
    point_multi_core #(WID) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .k(k),
        .px(px),
        .py(py),
        .qx(qx),
        .qy(qy),
        .done(done)
    );

    always #5 clk = ~clk;

    // File handling
    integer fd, status;
    reg [1023:0] line;
    reg [WID-1:0] k_vec [0:NUM_VECTORS-1];
    reg [WID-1:0] px_vec[0:NUM_VECTORS-1];
    reg [WID-1:0] py_vec[0:NUM_VECTORS-1];
    reg [WID-1:0] qx_exp_vec[0:NUM_VECTORS-1];
    reg [WID-1:0] qy_exp_vec[0:NUM_VECTORS-1];
    integer i;

    initial begin
        $display("===== START SIMULATION =====");

        // Reset
        rst = 1;
        start = 0;
        #20;
        rst = 0;

        // Open file
        fd = $fopen("scalar_vector.mem", "r");
        if (fd == 0) begin
            $display("ERROR: Cannot open file scalar_vectors.mem");
            $finish;
        end

       // Read vectors: Each test = 3 lines (k, px, py)
        for (i = 0; i < NUM_VECTORS; i = i + 1) begin
        // Read k
        status = $fgets(line, fd);
        if (status == 0) begin
            $display("ERROR: Unexpected EOF while reading k at test %0d", i);
            $finish;
        end
        $sscanf(line, "%h", k_vec[i]);

        // Read px
        status = $fgets(line, fd);
        if (status == 0) begin
            $display("ERROR: Unexpected EOF while reading px at test %0d", i);
            $finish;
        end
        $sscanf(line, "%h", px_vec[i]);

        // Read py
        status = $fgets(line, fd);
        if (status == 0) begin
            $display("ERROR: Unexpected EOF while reading py at test %0d", i);
            $finish;
        end
        $sscanf(line, "%h", py_vec[i]);
        
        // Read expected qx
            status = $fgets(line, fd);
            if (status == 0) begin
                $display("ERROR: Unexpected EOF while reading qx_expected at test %0d", i);
                $finish;
            end
            $sscanf(line, "%h", qx_exp_vec[i]);

            // Read expected qy
            status = $fgets(line, fd);
            if (status == 0) begin
                $display("ERROR: Unexpected EOF while reading qy_expected at test %0d", i);
                $finish;
            end
            $sscanf(line, "%h", qy_exp_vec[i]);
        end

        $fclose(fd);

        // Run each test
        for (i = 0; i < NUM_VECTORS; i = i + 1) begin
            k  = k_vec[i];
            px = px_vec[i];
            py = py_vec[i];

            $display("TEST %0d:", i);
            $display("  k  = 0x%h", k);
            $display("  px = 0x%h", px);
            $display("  py = 0x%h", py);

            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;

            wait (done == 1);
            @(posedge clk);

            $display("  qx = 0x%h", qx);
            $display("  qy = 0x%h", qy);

            if ((qx === qx_exp_vec[i]) && (qy === qy_exp_vec[i])) begin
                $display("  PASS");
            end else begin
                $display("  FAIL");
                $display("     Expected qx = 0x%h", qx_exp_vec[i]);
                $display("     Expected qy = 0x%h", qy_exp_vec[i]);
            end

            $display("");
            #20;
        end

        $display("===== END SIMULATION =====");
        $stop;
    end
endmodule