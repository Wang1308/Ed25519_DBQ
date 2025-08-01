`timescale 1ns / 1ps

module reg_256 #(parameter size = 256)
(
    input clk,
    input Load,
    input [size-1:0] Data,
    output reg [size-1:0] data_Out
);

always @ (posedge clk) begin
    if (Load)
        data_Out <= Data;
end

endmodule
