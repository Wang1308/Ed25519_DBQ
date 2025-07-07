`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 09:58:55 PM
// Design Name: 
// Module Name: Interleaved_Modular_Multi
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
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
   localparam [WID-1:0] MASK = { {WID-256{1'b0}}, {256{1'b1}} };  // 260-bit, chỉ 256-bit thấp là 1
   
   // ==== FSM ====
    reg [7:0] counter;
    reg [7:0] counter_ram;

//    wire [2:0] x_group;
    
    // FSM States
    localparam IDLE      = 3'b000,
           INIT_RAM  = 3'b001,
           PROCESSING= 3'b010,
           FINALIZE  = 3'b011,
           DONE      = 3'b100;

    reg [2:0] state;
    
    

    // ==== REG Signals ====
    wire [WID-1:0] C_reg_out, S_reg_out;
    wire [WID-1:0] csa1_sum, csa1_carry;
    wire [WID-1:0] csa2_sum, csa2_carry;
    wire [WID-1:0] c_shifted, s_shifted;
    wire enable_reg;
    
    
    // ==== RAM_Y_GEN ====
    wire [WIDTH-1:0] ram_data_out;
    wire  [2:0] ram_addr;
    
//    reg [N-1:0] X_tmp;
//    wire [8:0] shift_amt;
//    wire [N-1:0] mask;
//    assign shift_amt = (counter - 1) * 3;
//    assign ram_addr = (X_tmp >> shift_amt) & 3'b111;
//    assign mask = (shift_amt >= N) ? {N{1'b0}} : ((1 << shift_amt) - 1);
    
    // ==== ROM ====
    wire [WIDTH-1:0] rom_data;
    wire  [3:0] sel;
//    wire  [4:0] sel_sum;
//    wire C_msb = C_reg_out[N-1];  // bit thứ 255
//    wire S_msb = S_reg_out[N-1];  // bit thứ 255
    
//    assign sel_sum = {3'b000, C_msb} + {3'b000, S_msb};  // giá trị trong khoảng 0..2

    wire clear_regs = (state == FINALIZE);   
    assign enable_reg = (state == PROCESSING) || clear_regs;
    // ==== Trích 3 bit nhóm từ X ====
    assign ram_addr = ((X >> ((counter-1) * 3)) & 3'b111);
    wire [4:0] high_S = S_reg_out[WID-1:WIDTH-1];
    wire [4:0] high_C = C_reg_out[WID-1:WIDTH-1];
    wire [4:0] N_index = (high_S + high_C) & 5'b01111;
    
    assign sel = N_index[3:0]; 
    
    wire is_idle_or_init = (state == IDLE) || (state == INIT_RAM);
    
    wire [WID-1:0] csa1_in1, csa1_in2, csa1_in3;
    wire [WID-1:0] csa2_in1, csa2_in2, csa2_in3;
    
    assign csa1_in1 = is_idle_or_init ? {WID{1'b0}} : c_shifted;
    assign csa1_in2 = is_idle_or_init ? {WID{1'b0}} : s_shifted;
    assign csa1_in3 = is_idle_or_init ? {WID{1'b0}} : ram_data_out;  // zero extend ram_data_out lên WID bit
    
    assign csa2_in1 = is_idle_or_init ? {WID{1'b0}} : csa1_sum;
    assign csa2_in2 = is_idle_or_init ? {WID{1'b0}} : csa1_carry;
    assign csa2_in3 = is_idle_or_init ? {WID{1'b0}} : rom_data;  // zero extend rom_data lên WID bit
    
    wire [WID-1:0] Z_tmp = C_reg_out + S_reg_out;
    wire [WID-1:0] regC_in = clear_regs ? {WID{1'b0}} : csa2_carry;
    wire [WID-1:0] regS_in = clear_regs ? {WID{1'b0}} : csa2_sum;

    wire [254:0] mod_p_result;
    
    mod_p u_mod_p (
    .X({252'b0, Z_tmp}),      // Zero-extend Z_tmp to 512 bits (260 -> 512)
    .result(mod_p_result)
    );

    
    RAM_Y_GEN ramY (
        .clk(clk),
        .rst(reset),
        .Y(Y),
        .init_en(state == IDLE),
        .addr(ram_addr),
        .data_out(ram_data_out)
    );
    
    // ==== ROM ====
    ROM rom2 (
        .sel(sel),
        .data(rom_data)
    );
    
    // ==== Shift_mod ====
    Shift_mod #(.N(WID)) u_shift_c (
        .in(C_reg_out),
        .out(c_shifted)
    );

    Shift_mod #(.N(WID)) u_shift_s (
        .in(S_reg_out),
        .out(s_shifted)
    );
    
    // ==== CSA ====
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
    
    
    // ==== REG ====
    REG #(.WIDTH(WID)) regC (
    .clk(clk),
    .rst(reset),
    .en(enable_reg),
    .din(regC_in),
    .dout(C_reg_out)
    );

    REG #(.WIDTH(WID)) regS (
    .clk(clk),
    .rst(reset),
    .en(enable_reg),
    .din(regS_in),
    .dout(S_reg_out)
    );

    

    // FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            counter  <= NUM_DIGITS;
            counter_ram <= 0;
            done     <= 0;
            Z        <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
//                    X_tmp <= X;
                    if (start) begin
                        state <= INIT_RAM;
//                        sel      <= 0;
                        counter_ram <= 0;
                    end
                end
                INIT_RAM: begin
                    counter_ram <= counter_ram +1;
                    counter <= NUM_DIGITS;
                    if (counter_ram > 14) begin 
                    state <= PROCESSING;
                    end
                end
                PROCESSING: begin
                if (counter > 1) begin
                    counter <= counter - 1;
                end else begin
                    state <= FINALIZE;
                end
            end

            FINALIZE: begin
                Z <= {1'b0, mod_p_result};
                state <= DONE;
            end

            DONE: begin
                done  <= 1;
                state <= IDLE;
            end
        endcase
        end
    end
    
endmodule
