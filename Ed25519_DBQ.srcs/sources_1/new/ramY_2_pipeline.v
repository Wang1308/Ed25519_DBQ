module ramY_2_pipeline (
    input  wire        clk,
    input  wire        rst,
    input  wire        init_en,
    input  wire [255:0] Y,
    input  wire [2:0]  addr,
    output reg  [255:0] data_out
);

    parameter LATENCY = 4;

    reg [255:0] mem [0:7];
    reg [2:0] wr_addr;
    reg       loading;

    // Pipeline FIFO (shift register)
    reg [2:0]  addr_pipe [0:LATENCY-1];
    reg        valid_pipe [0:LATENCY-1];

    wire [511:0] mult_result;
    wire [254:0] reduced_mod_p;

    // Register Y * i
    reg [255:0] Y_reg;
    reg [2:0]   i;

    // Internal reset signal for mod_p
    reg mod_p_rst;

    // Multiply and feed to pipeline
    assign mult_result = Y_reg * i;

    // Pipelined Barrett Reduction with internal reset
    mod_p_ed25519_pipe mod_p(
        .clk(clk),
        .rst(mod_p_rst),
        .X(mult_result),
        .Z(reduced_mod_p)
    );

    integer k;
    always @(posedge clk) begin
        if (rst) begin
            i        <= 0;
            wr_addr  <= 0;
            loading  <= 0;
            Y_reg    <= 0;
            mod_p_rst <= 0;

            for (k = 0; k < LATENCY; k = k + 1) begin
                valid_pipe[k] <= 0;
                addr_pipe[k]  <= 0;
            end
        end
        else begin
            // Default: mod_p_rst deassert
            mod_p_rst <= 0;

            if (init_en) begin
                i        <= 0;
                Y_reg    <= Y;
                wr_addr  <= 0;
                loading  <= 1;
            end
            else if (loading) begin
                // Shift pipeline
                for (k = LATENCY-1; k > 0; k = k - 1) begin
                    valid_pipe[k] <= valid_pipe[k-1];
                    addr_pipe[k]  <= addr_pipe[k-1];
                end
                valid_pipe[0] <= 1;
                addr_pipe[0]  <= i;

                // Write result to RAM
                if (valid_pipe[LATENCY-1]) begin
                    mem[addr_pipe[LATENCY-1]] <= {1'b0, reduced_mod_p};
                end

                // Increase i
                if (i < 7) begin
                    i <= i + 1;
                end

                // Track writes
                wr_addr <= wr_addr + 1;

                // Finish loading and issue reset to mod_p
                if (wr_addr == 7 + LATENCY - 1) begin
                    loading <= 0;
                    mod_p_rst <= 1;  // Reset mod_p in the next clock
                end
            end
        end
    end

    // Combinational read
    always @(*) begin
        data_out = mem[addr];
    end

endmodule
