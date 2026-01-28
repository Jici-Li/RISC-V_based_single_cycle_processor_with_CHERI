'timescale 1ns/1ps
module 2to1mux(
input [31:0]A,B,
input sel,
output [31:0]out
);
assign out=sel ? A:B;
endmodule
