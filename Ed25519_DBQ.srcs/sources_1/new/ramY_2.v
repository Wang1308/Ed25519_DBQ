module ramY_2 (
    input  wire        clk,
    input  wire        rst,
    input  wire        init_en,
    input  wire [255:0] Y,
    input  wire [2:0]  addr,
    output reg  [255:0] data_out,
    output wire        done      // <--- thêm tín hiệu done
);

    reg [255:0] mem [0:7];      // RAM 8 x 256-bit
    reg [2:0]   i;
    reg         loading;
    reg         stage;         // 0: mult, 1: store result
    reg [511:0] mult_result;

    // Control for modular reduction
    reg         start_mod;
    wire        done_mod;
    wire [254:0] reduced_mod_p;

    // Done signal when loading is finished
    assign done = ~loading;

    mod_p_ed25519_seq mod_p (
        .clk(clk),
        .rst(rst),
        .start(start_mod),
        .X(mult_result),
        .Z(reduced_mod_p),
        .done(done_mod)
    );

    always @(posedge clk) begin
        if (rst) begin
            i           <= 0;
            loading     <= 0;
            stage       <= 0;
            start_mod   <= 0;
            mult_result <= 0;
        end else begin
            if (init_en) begin
                i         <= 0;
                loading   <= 1;
                stage     <= 0;
                start_mod <= 0;
            end else if (loading) begin
                case (stage)
                    0: begin
                        mult_result <= Y * i;
                        start_mod   <= 1;
                        stage       <= 1;
                    end
                    1: begin
                        start_mod <= 0;
                        if (done_mod) begin
                            mem[i] <= {1'b0, reduced_mod_p};
                            if (i == 3'd7)
                                loading <= 0;
                            else
                                i <= i + 1;
                            stage <= 0;
                        end
                    end
                endcase
            end
        end
    end

    // RAM read (pure combinational)
    always @(*) begin
        data_out = mem[addr];
    end

endmodule
