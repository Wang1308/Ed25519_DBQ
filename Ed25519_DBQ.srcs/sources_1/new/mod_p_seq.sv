module mod_p_ed25519_seq (
    input logic clk,
    input logic rst,
    input logic start,
    input logic [511:0] X,
    output logic [254:0] Z,     // Kết quả modulo p = 2^255 - 19
    output logic done
);

    // Trạng thái FSM
    typedef enum logic [1:0] {
        IDLE, LOAD, MUL_ACC, REDUCE
    } state_t;

    state_t state, next_state;

    localparam [254:0] P = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

    logic [254:0] X_low;
    logic [261:0] X_high;
    logic [261:0] temp_sum;

    // FSM chuyển trạng thái
    always_comb begin
        case (state)
            IDLE:    next_state = start ? LOAD : IDLE;
            LOAD:    next_state = (X_low >= P || X_high >= P) ? LOAD : MUL_ACC;
            MUL_ACC: next_state = REDUCE;
            REDUCE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Đăng ký lưu trạng thái
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Xử lý chính
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 0;
            Z <= 0;
            temp_sum <= 0;
            X_low <= 0;
            X_high <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    X_low <= X[254:0];
                    X_high <= {6'b000000, X[511:255]};  // Pad để đủ 262-bit
                end

                LOAD: begin
                    if (X_low >= P)
                        X_low <= X_low - P;

                    if (X_high >= P)
                        X_high <= X_high - P;
                end

                MUL_ACC: begin
                    temp_sum <= X_low + X_high * 19;
                end

                REDUCE: begin
                    if (temp_sum >= P)
                        Z <= temp_sum - P;
                    else
                        Z <= temp_sum[254:0];
                    done <= 1;
                end
            endcase
        end
    end

endmodule
