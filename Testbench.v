`timescale 1ns/1ps
module RISC5_tb;
  reg clk;
  reg rst;
  RISC5_top uut (
    .clk(clk),
    .rst(rst)
  );
  always #5 clk = ~clk;
  initial begin
    $dumpfile("output.vcd");
    $dumpvars(0, RISC5_tb);
    clk = 0;
    rst = 1;
    #20;
    rst = 0;
    #5000; 
    $display("\nRegister Values");
    for (integer i = 0; i < 32; i = i + 1) begin
      $display("x%0d  = %0d", i, uut.RF.registers[i]);
    end
    $finish;
  end
endmodule