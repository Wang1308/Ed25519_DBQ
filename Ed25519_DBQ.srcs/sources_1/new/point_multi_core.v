`timescale 1ns / 1ps

module point_multi_core #(
    parameter WID = 256
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [WID-1:0] k,
    input wire [WID-1:0] px, py,   // P(X, Y, Z,T)
    output reg [WID-1:0] qx, qy,
    output reg done
    );
    
    localparam 
        IDLE       = 3'd0,
        CALC_P     = 3'd1,
        CALC_Q     = 3'd2,
        INV_Z      = 3'd3,
        CALC_Qx    = 3'd4,
        CALC_Qy    = 3'd5,
        DONE       = 3'd6;
    reg [2:0] state;
    
    reg [WID-1:0] Z_qx, Z_qy;
    
    reg rst_SMSM;
    reg start_SMSM;
    reg [WID-1:0] pt;

    // Outputs from FSM
    wire SMSM_done;
    wire [WID-1:0] result_x, result_y, result_z, result_t;

    // ALU interface wires
    wire rst_alu;
    wire start_alu;
    wire alu_done;
    wire op_alu;
    wire [WID-1:0] qx_alu, qy_alu, qz_alu, qt_alu;
    wire [WID-1:0] px_alu, py_alu, pz_alu, pt_alu;
    
    // Mul 
    reg rst_mul;
    reg [WID-1:0] X,Y;
    wire[WID-1:0] Z;
    wire mul_done;
    reg start_mul;
    
    // Inv
    reg rst_inv;
    reg [WID-1:0] a;
    wire [WID-1:0] a_inv;
    reg start_inv;
    wire inv_done;
    
    Scalar_multi_SM SMSM (
        .clk(clk),
        .rst(rst_SMSM),
        .start(start_SMSM),
        .k(k),
        .px(px),
        .py(py),
        .pz(256'h1),
        .pt(pt),
        .done(SMSM_done),
        .rst_alu(rst_alu),
        .start_alu(start_alu),
        .alu_done(alu_done),
        .op_alu(op_alu),
        .qx_alu(qx_alu),
        .qy_alu(qy_alu),
        .qz_alu(qz_alu),
        .qt_alu(qt_alu),
        .px_alu(px_alu),
        .py_alu(py_alu),
        .pz_alu(pz_alu),
        .pt_alu(pt_alu),
        .result_x(result_x),
        .result_y(result_y),
        .result_z(result_z),
        .result_t(result_t)
    );

    // Instantiate Real ALU Unit
    ALU_UNIT #(
        .WID(WID),
        .DEPTH(32),
        .REG_BANK(5)
    ) alu_unit (
        .clk(clk),
        .rst(rst_alu),
        .start(start_alu),
        .op(op_alu),
        .px(px_alu),
        .py(py_alu),
        .pz(pz_alu),
        .pt(pt_alu),
        .qx(qx_alu),
        .qy(qy_alu),
        .qz(qz_alu),
        .qt(qt_alu),
        .done(alu_done)
    );
    
    Interleaved_Modular_Multi multi_unit (
        .clk(clk),
        .reset(rst_mul),
        .start(start_mul),
        .X(X),
        .Y(Y),
        .Z(Z),
        .done(mul_done)
    );
    
    invert #(.WID(WID)) inv_unit (
        .clk(clk),
        .rst(rst_inv),
        .start(start_inv),
        .a(a),
        .done(inv_done),
        .result(a_inv)
    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    if (start) state <= CALC_P;
                
                CALC_P: begin
                    if (mul_done) begin
                    state <= CALC_Q;
                    pt <= Z;
                    end
                 end  
                 
                CALC_Q: begin
                    if (SMSM_done) state <= INV_Z;
                end
                
                INV_Z: begin
                    if (inv_done) state <= CALC_Qx;
                end
                
                CALC_Qx: begin
                    if (mul_done) begin
                         state <= CALC_Qy;
                         Z_qx <= Z;
                    end 
                end
                
                CALC_Qy: begin
                    if (mul_done) begin
                         state <= DONE;
                         Z_qy <= Z;
                    end 
                end
                
                DONE:
                    state <= IDLE;

                default:
                    state <= IDLE;
             endcase
        end
    end
    
        always @(posedge clk or posedge rst) begin
        if (rst) begin
            rst_SMSM <= 1;
            rst_mul <= 1;
            rst_inv <= 1;
            start_mul <= 0;
            X <= 0;
            Y <= 0;
            start_SMSM <= 0;
            pt <= 0;
            start_inv <= 0;
            a <= 0;
            done <= 0;
            qx <= 0;
            qy <= 0;
        end else begin
            start_mul <= 0;
            start_SMSM <= 0;
            start_inv <= 0;
            rst_SMSM <= 0;
            rst_mul <= 0;
            rst_inv <= 0;
            case (state)
                IDLE: begin
                    rst_SMSM <= 1;
                    rst_mul <= 1;
                    rst_inv <= 1;
                    done <= 0;
                end
                CALC_P: begin
                    start_mul <= 1;
                    X <= px;
                    Y <= py;
                end
                CALC_Q: begin
                    start_SMSM <= 1;
//                    pt <= Z;
                end
                INV_Z: begin
                    start_inv <= 1;
                    a <= result_z;
                end
                CALC_Qx: begin
                    start_mul <= 1;
                    X <= result_x;
                    Y <= a_inv;
                end
                CALC_Qy: begin
                    start_mul <= 1;
                    X <= result_y;
                    Y <= a_inv;
                end
                DONE: begin
                    done <= 1;
                    qx <= Z_qx;
                    qy <= Z_qy;
                end
            endcase
        end
    end
endmodule
