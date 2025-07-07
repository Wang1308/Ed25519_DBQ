module RAM_Y_GEN (
    input  wire        clk,
    input  wire        rst,
    input  wire [255:0] Y,
    input  wire        init_en,
    input  wire [2:0]  addr,
    output reg  [255:0] data_out
);
    reg [255:0] mem [0:7];
    reg [2:0] i;
    reg       loading;
    reg       stage; // 0: chuẩn bị mult, 1: lưu kết quả

    reg [255:0] i_val;
    reg [511:0] mult_result;

    wire [254:0] reduced_mod_p;

    // MODULE Barrett Reduction
    mod_p barrett_inst (
        .X(mult_result),
        .result(reduced_mod_p)
    );

    always @(posedge clk) begin
        if (rst) begin
            i <= 0;
            loading <= 0;
            stage <= 0;
        end
        else if (init_en) begin
            i <= 0;
            loading <= 1;
            stage <= 0;
        end
        else if (loading) begin
            if (stage == 0) begin
                // Giai đoạn 1: chuẩn bị nhân
                i_val <= i;
                mult_result <= {253'b0, i} * Y;
                stage <= 1;
            end
            else begin
                // Giai đoạn 2: nhận kết quả mod_p và lưu
                mem[i] <= {1'b0, reduced_mod_p};
                if (i_val == 3'd7)
                    loading <= 0;
                else
                    i <= i + 1;
                stage <= 0;
            end
        end
    end

    // Đọc RAM
    always @(*) begin
        data_out = mem[addr];
    end
endmodule
