`timescale 1ns / 1ps

module invert #(parameter WID = 256) (
    input  wire             clk,
    input  wire             rst,
    input  wire             start,
    input  wire [WID-1:0]   a,
    output wire [WID-1:0]   result,
    output reg              done
);

    // FSM states
    localparam
        IDLE          = 5'd0,
        CALC_A2       = 5'd1, 
        CALC_A4       = 5'd2, 
        CALC_A8       = 5'd3, 
        CALC_A9       = 5'd4,
        CALC_A11      = 5'd5,
        CALC_A22      = 5'd6,  
        CALC_2_5_1    = 5'd7,
        CALC_2_10_1   = 5'd8,
        CALC_2_20_1   = 5'd9,
        CALC_2_40_1   = 5'd10,
        CALC_2_50_1   = 5'd11,
        CALC_2_100_1  = 5'd12,
        CALC_2_200_1  = 5'd13,
        CALC_2_250_1  = 5'd14,
        INV_A         = 5'd15,
        DONE          = 5'd16;

    reg [4:0] state, next_state;

    // Multiplier interface
    reg [WID-1:0] op_a, op_b;
    reg           mul_start;
    wire [WID-1:0] mul_result;
    wire          mul_done;

    Interleaved_Modular_Multi multiplier (
        .clk(clk),
        .reset(rst),
        .start(mul_start),
        .X(op_a),
        .Y(op_b),
        .Z(mul_result),
        .done(mul_done)
    );

    // Temporary registers for intermediate results
    reg [WID-1:0] r_a2, r_a4, r_a8, r_a9, r_a11, r_a22, r_a2_5_1, r_a2_10_1, r_a2_20_1, r_a2_50_1, r_a2_100_1, r_a2_250_1, r_a2_11;
    reg [WID-1:0] r_t;

    // Control
    reg [6:0] counter;
    reg [WID-1:0] result_reg;
    assign result = result_reg;

    // FSM
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always @(posedge clk) begin
        if (rst) begin
        next_state <= IDLE;
        mul_start <= 0;
        done <= 0;
        end else begin
        case (state)
            IDLE: begin
                if (start) next_state <= CALC_A2;
            end

            CALC_A2: begin
                mul_start <= 1;
                op_a <= a;
                op_b <= a;
                if (mul_done) begin
                 next_state <= CALC_A4;
                 mul_start <= 0;
             end
            end
            
            CALC_A4: begin
                mul_start <= 1;
                op_a <= r_a2;
                op_b <= r_a2;
                if (mul_done) begin
                 next_state <= CALC_A8;
                 mul_start <= 0;
             end
            end

            CALC_A8: begin
                mul_start <= 1;
                op_a <= r_a4;
                op_b <= r_a4;
                if (mul_done) begin
                next_state <= CALC_A9;
                mul_start <= 0;
                end
            end

            CALC_A9: begin
                mul_start <= 1;
                op_a <= r_a8;
                op_b <= a;
                if (mul_done) begin
                next_state <= CALC_A11;
                mul_start <= 0;
                end
            end

            CALC_A11: begin
                mul_start <= 1;
                op_a <= r_a9;
                op_b <= r_a2;
                if (mul_done) begin
                 next_state <= CALC_A22;
                 mul_start <= 0;
                 end
            end
            
            CALC_A22: begin
                mul_start <= 1;
                op_a <= r_a11;
                op_b <= r_a11;
                if (mul_done) begin
                 next_state <= CALC_2_5_1;
                 mul_start <= 0;
                 end
            end
            
            CALC_2_5_1: begin
                mul_start <= 1;
                op_a <= r_a22;
                op_b <= r_a9;
                if (mul_done) begin
                 next_state <= CALC_2_10_1;
                 mul_start <= 0;
                 end
            end

            CALC_2_10_1: begin
                // Perform 5 squarings and one multiply with a11
                if (counter < 5) begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_t;
                end else begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_a2_5_1;
                end
                if (mul_done) begin
                    mul_start <= 0;
                    if (counter < 5) counter <= counter + 1;
                    else begin
                    next_state <= CALC_2_20_1;
                    counter <= 0;
                    end
                end
            end

            CALC_2_20_1: begin
                // 10 squarings and one multiply with result from CALC_2_10_1
                if (counter < 10) begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_t;
                end else begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_a2_10_1; // could use r_a2_10_1
                end
                if (mul_done) begin
                    mul_start <= 0;
                    if (counter < 10) counter <= counter + 1;
                    else begin
                    next_state <= CALC_2_40_1;
                    counter <= 0;
                    end
                end
            end

            CALC_2_40_1: begin
                // 20 squarings and one multiply with result from CALC_2_20_1
                if (counter < 20) begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_t;
                end else begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_a2_20_1; // could use r_a2_20_1
                end
                if (mul_done) begin
                    mul_start <= 0;
                    if (counter < 20) counter <= counter + 1;
                    else begin
                    next_state <= CALC_2_50_1;
                    counter <= 0;
                    end
                end
            end
            
            CALC_2_50_1: begin
                // 10 squarings and one multiply with result from CALC_2_10_1
                if (counter < 10) begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_t;
                end else begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_a2_10_1; // could use r_a2_10_1
                end
                if (mul_done) begin
                    mul_start <= 0;
                    if (counter < 10) counter <= counter + 1;
                    else begin
                    next_state <= CALC_2_100_1;
                    counter <= 0;
                    end
                end
            end
            
            CALC_2_100_1: begin
                // 50 squarings and one multiply with result from CALC_2_50_1
                if (counter < 50) begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_t;
                end else begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_a2_50_1; // could use r_a2_50_1
                end
                if (mul_done) begin
                    mul_start <= 0;
                    if (counter < 50) counter <= counter + 1;
                    else begin
                    next_state <= CALC_2_200_1;
                    counter <= 0;
                    end
                end
            end
            
            CALC_2_200_1: begin
                // 100 squarings and one multiply with result from CALC_2_100_1
                if (counter < 100) begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_t;
                end else begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_a2_100_1; // could use r_a2_100_1
                end
                if (mul_done) begin
                    mul_start <= 0;
                    if (counter < 100) counter <= counter + 1;
                    else begin
                    next_state <= CALC_2_250_1;
                    counter <= 0;
                    end
                end
            end
            
            CALC_2_250_1: begin
                // 50 squarings and one multiply with result from CALC_2_50_1
                if (counter < 50) begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_t;
                end else begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_a2_50_1; // could use r_a2_50_1
                end
                if (mul_done) begin
                    mul_start <= 0;
                    if (counter < 50) begin
                    counter <= counter + 1;
                    end
                    else begin
                    next_state <= INV_A;
                    counter <= 0;
                    end
                end
            end
            
            
            INV_A: begin
                // 5 squarings and one multiply with result from CALC_2_11
                if (counter < 5) begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_t;
                end else begin
                    mul_start <= 1;
                    op_a <= r_t;
                    op_b <= r_a11; // could use r_a11
                end
                if (mul_done) begin
                    mul_start <= 0;
                    if (counter < 5) counter <= counter + 1;
                    else begin
                    next_state <= DONE;
                    result_reg <= mul_result;
                    end
                end
            end

            DONE: begin
                done <= 1;
                next_state <= IDLE;
            end
        endcase
      end
    end

    // Output result capture and register updates
    always @(posedge clk) begin
        if (rst) begin
            r_a2 <= 0; r_a4 <= 0; r_a8 <= 0; r_a9 <= 0; r_a11 <= 0; r_t <= 0;
            counter <= 0; result_reg <= 0;
        end else if (mul_done) begin
            case (state)
                CALC_A2:  r_a2  <= mul_result;
                CALC_A4:  r_a4  <= mul_result;
                CALC_A8:  r_a8  <= mul_result;
                CALC_A9:  r_a9  <= mul_result;
                CALC_A11: r_a11 <= mul_result;
                CALC_A22: r_a22 <= mul_result;
                CALC_2_5_1: begin r_t <= mul_result; r_a2_5_1 <= mul_result; end
                CALC_2_10_1: begin r_t <= mul_result; r_a2_10_1 <= mul_result; end
                CALC_2_20_1: begin r_t <= mul_result; r_a2_20_1 <= mul_result; end
                CALC_2_40_1: r_t <= mul_result;
                CALC_2_50_1: begin r_t <= mul_result; r_a2_50_1 <= mul_result; end
                CALC_2_100_1: begin r_t <= mul_result; r_a2_100_1 <= mul_result; end
                CALC_2_200_1: r_t <= mul_result;
                CALC_2_250_1: begin r_a2_250_1 <= mul_result; r_t <= mul_result;end
                INV_A       : r_t <= mul_result;
            endcase
        end
    end

endmodule
