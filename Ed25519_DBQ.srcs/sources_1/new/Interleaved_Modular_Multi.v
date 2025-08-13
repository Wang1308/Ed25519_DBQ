`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Interleaved_Modular_Multi #( parameter WIDTH = 256)(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [WIDTH-1:0] X,
    input wire [WIDTH-1:0] Y,
    output reg [WIDTH-1:0] Z,
    output reg done
);

    localparam P = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED; // 2^255 - 19
    localparam NUM_DIGITS = WIDTH / 3;
    localparam WID = 260;

    reg [7:0] counter;
    reg [2:0] state;

    localparam IDLE      = 3'b000,
               INIT_RAM  = 3'b001,
               PROCESSING= 3'b010,
               FINALIZE  = 3'b011,
               DONE      = 3'b100;

    reg [WID-1:0] C_reg, S_reg;

    wire [WID-1:0] csa1_sum, csa1_carry;
    wire [WID-1:0] csa2_sum, csa2_carry;
    wire [WID-1:0] c_shifted, s_shifted;

    wire clear_regs = (state == FINALIZE);

    wire [WIDTH-1:0] ram_data_out;
    wire  [2:0] ram_addr = ((X >> ((counter-1) * 3)) & 3'b111);

    wire [WIDTH-1:0] rom_data;
    wire  [3:0] sel;

    wire [4:0] high_S = S_reg[WID-1:WIDTH-1];
    wire [4:0] high_C = C_reg[WID-1:WIDTH-1];
    wire [4:0] N_index = (high_S + high_C) & 5'b01111;
    assign sel = N_index[3:0]; 

    wire is_idle_or_init = (state == IDLE) || (state == INIT_RAM);

    wire [WID-1:0] csa1_in1 = is_idle_or_init ? {WID{1'b0}} : c_shifted;
    wire [WID-1:0] csa1_in2 = is_idle_or_init ? {WID{1'b0}} : s_shifted;
    wire [WID-1:0] csa1_in3 = is_idle_or_init ? {WID{1'b0}} : ram_data_out;

    wire [WID-1:0] csa2_in1 = is_idle_or_init ? {WID{1'b0}} : csa1_sum;
    wire [WID-1:0] csa2_in2 = is_idle_or_init ? {WID{1'b0}} : csa1_carry;
    wire [WID-1:0] csa2_in3 = is_idle_or_init ? {WID{1'b0}} : rom_data;

    wire [WID-1:0] Z_tmp = C_reg + S_reg;

    wire [WID-1:0] regC_in = clear_regs ? {WID{1'b0}} : csa2_carry;
    wire [WID-1:0] regS_in = clear_regs ? {WID{1'b0}} : csa2_sum;

    wire [254:0] mod_p_result;
    reg start_mod;
    wire done_mod;

    mod_p_ed25519_seq u_mod_p (
        .clk(clk),
        .rst(reset),
        .start(start_mod),
        .done(done_mod),
        .X({252'b0, Z_tmp}),
        .Z(mod_p_result)
    );

    wire ram_done;

    ramY_2 ramY (
        .clk(clk),
        .rst(reset),
        .Y(Y),
        .init_en(state == IDLE),
        .addr(ram_addr),
        .data_out(ram_data_out),
        .done(ram_done)
    );

    ROM rom2 (
        .sel(sel),
        .data(rom_data)
    );

    Shift_mod #(.N(WID)) u_shift_c (
        .in(C_reg),
        .out(c_shifted)
    );

    Shift_mod #(.N(WID)) u_shift_s (
        .in(S_reg),
        .out(s_shifted)
    );

    CSA #(.WIDTH(WID)) u_csa1 (
        .in1(csa1_in1),
        .in2(csa1_in2),
        .in3(csa1_in3),
        .sum(csa1_sum),
        .carry(csa1_carry)
    );

    CSA #(.WIDTH(WID)) u_csa2 (
        .in1(csa2_in1),
        .in2(csa2_in2),
        .in3(csa2_in3),
        .sum(csa2_sum),
        .carry(csa2_carry)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            counter     <= NUM_DIGITS;
            done        <= 0;
            start_mod   <= 0;
            Z           <= 0;
            C_reg       <= {WID{1'b0}};
            S_reg       <= {WID{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start)
                        state <= INIT_RAM;
                end

                INIT_RAM: begin
                    if (ram_done) begin
                        counter <= NUM_DIGITS;
                        state <= PROCESSING;
                    end
                end

                PROCESSING: begin
                    if (counter > 1)
                        counter <= counter - 1;
                    else begin
                        state <= FINALIZE;
                        start_mod <= 1;
                    end
                    C_reg <= regC_in;
                    S_reg <= regS_in;
                end

                FINALIZE: begin
                    start_mod <= 0;
                    C_reg <= regC_in;
                    S_reg <= regS_in;
                    if (done_mod) begin
                        Z <= {1'b0, mod_p_result};
                        state <= DONE;
                    end
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
