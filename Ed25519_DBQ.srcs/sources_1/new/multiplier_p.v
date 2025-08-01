`timescale 1ns / 1ps

module multiplier_p (
    input         clk,
    input         Reset,
    input         start,
    input  [255:0] a,
    input  [255:0] b,
    output reg    Done,
    output reg [255:0] product
);

    // Parameters
    localparam [255:0] P = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;

    // Internal signals
    reg [255:0] a_in;
    wire [255:0] a_out;
    reg [257:0] b_in, c_in;
    wire [257:0] b_out, c_out;
    reg [255:0] count_in;
    wire [255:0] count_out;

    reg a_load, b_load, c_load, count_load;

    // FSM states
    localparam [2:0]
        Init   = 3'd0,
        Start  = 3'd1,
        setB   = 3'd2,
        redB   = 3'd3,
        setC   = 3'd4,
        Finish = 3'd5,
        Done_state= 3'd6;

    reg [2:0] State, Next_State;

    // Registers (dummy modules to be defined separately)
    reg_256        a_reg    (.clk(clk), .Load(a_load), .Data(a_in),    .data_Out(a_out));
    reg_256 #(258) b_reg    (.clk(clk), .Load(b_load), .Data(b_in),    .data_Out(b_out));
    reg_256 #(258) c_reg    (.clk(clk), .Load(c_load), .Data(c_in),    .data_Out(c_out));
    reg_256 #(256) count_reg(.clk(clk), .Load(count_load), .Data(count_in), .data_Out(count_out));

    // FSM: sequential
    always @(posedge clk) begin
        if (Reset)
            State <= Init;
        else
            State <= Next_State;
    end

    // FSM: combinational
    always @(*) begin
        Next_State = State;
        case (State)
            Init:
                if (start) Next_State = Start;
            Start:
                Next_State = setB;
            setB:
                if ((b_out << 1) >= {2'b00, P})
                    Next_State = redB;
                else
                    Next_State = setC;
            redB:
                if (b_out >= {2'b00, P})
                    Next_State = redB;
                else
                    Next_State = setC;
            setC:
                if (count_out == 8'd254)
                    Next_State = Finish;
                else
                    Next_State = setB;
            Finish:
                if (c_out < {2'b00, P}) begin
                Next_State = Done_state;
                end else begin
                Next_State = Finish;
                end
            default: ;
        endcase
    end

    // Combinational logic
    always @(*) begin
        // Defaults
        a_in = a_out;
        b_in = b_out;
        c_in = c_out;
        count_in = count_out;

        a_load = 0;
        b_load = 0;
        c_load = 0;
        count_load = 0;
        Done = 0;
        product = 0;

        case (State)
            Init: begin
                Done = 0;
                a_in = a;
                b_in = {2'b00, b};
                c_in = 258'b0;
                count_in = 0;

                a_load = 1;
                b_load = 1;
                c_load = 1;
                count_load = 1;
            end

            Start: begin
                c_in = (a[0] == 1'b1) ? b_out : 258'b0;
                c_load = 1;
            end

            setB: begin
                a_in = a_out >> 1;
                b_in = b_out << 1;
                a_load = 1;
                b_load = 1;
            end

            redB: begin
                if (b_out >= {2'b00, P})
                    b_in = b_out - {2'b00, P};
                else
                    b_in = b_out;
                b_load = 1;
            end

            setC: begin
                if (a_out[0] == 1'b1) begin
                    if ((c_out + b_out) >= {2'b00, P})
                        c_in = (c_out + b_out) - {2'b00, P};
                    else
                        c_in = c_out + b_out;
                end else begin
                    if (c_out >= {2'b00, P})
                        c_in = c_out - {2'b00, P};
                    else
                        c_in = c_out;
                end

                c_load = 1;
                count_in = count_out + 1;
                count_load = 1;
            end

            Finish: begin
//                if (c_out < {2'b00, P}) begin
//                    Done = 1;
//                    product = c_out[255:0];
//                end else begin
                    c_in = c_out - {2'b00, P};
                    c_load = 1;
                    Done = 0;
//                end
            end
            Done_state: begin
            product = c_out[255:0];
             Done = 1;
            end

            default: ;
        endcase
    end

endmodule
