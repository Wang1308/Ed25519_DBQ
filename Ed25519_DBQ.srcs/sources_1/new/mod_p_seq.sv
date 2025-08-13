module mod_p_ed25519_seq (
    input  logic         clk,
    input  logic         rst,
    input  logic         start,
    input  logic [511:0] X,
    output logic [254:0] Z,     // Kết quả modulo p = 2^255 - 19
    output logic         done
);

    // Trạng thái FSM
    typedef enum logic [1:0] {
        IDLE, CALC, REDUCE
    } state_t;

    state_t state, next_state;

    localparam [254:0] P = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

    logic [254:0] X_low;
    logic [256:0] X_high;       // Không cần pad 6 bit
    logic [260:0] temp_sum;

    // FSM điều khiển
    always_comb begin
        case (state)
            IDLE:    next_state = start ? CALC : IDLE;
            CALC:    next_state = REDUCE;
            REDUCE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Cập nhật trạng thái
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Luồng xử lý chính
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            done      <= 0;
            Z         <= 0;
            temp_sum  <= 0;
            X_low     <= 0;
            X_high    <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done   <= 0;
                    if (X[254:0] >= P)
                        X_low  <= X[254:0] - P;
                    else
                        X_low  <= X[254:0];
                    
                    if (X[511:255] >= P)
                        X_high  <= X[511:255] - P;
                    else
                        X_high  <= X[511:255];
//                    X_low  <= (X[254:0] >= P) ? X[254:0] - P : X[254:0];
//                    X_high <= (X[511:255] >= P) ? X[511:255] - P : X[511:255];
                end

                CALC: begin
                    // Thay thế X_high * 19 bằng: (X_high << 4) + (X_high << 1) + X_high
                    temp_sum <= X_low + (X_high << 4) + (X_high << 1) + X_high;
                end

                REDUCE: begin
                    done <= 1;
                    if (temp_sum >= P)
                        Z  <= temp_sum - P;
                    else
                        Z  <= temp_sum[254:0];
//                    Z    <= (temp_sum >= P) ? temp_sum - P : temp_sum[254:0];
                end
            endcase
        end
    end

endmodule
