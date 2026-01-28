'timescale 1ns/1ps
module Registerfile(
    input clk,
    input regWire,
    input wire [4:0]A1,A2,A3,
    input wire [31:0]writeData,
    output wire [31:0]RD1,RD2
);

    reg [31:0]registers[0:31];
    
    // Read operation
    assign RD1=(A1!=5'b0)? registers[A1]:32'b0;
    assign RD2=(A2!=5'b0)? registers[A2]:32'b0;
    
    // Write operation
    integer i;
    always @(posedge clk) begin
        if (regWire&&A3!=5'b0) begin
            registers[A3]<=writeData;
        end
    end
    initial
    begin
        for(i=0;i<32;i=i+1)
        begin
            registers[i]=32'b0;
        end
    end
    endmodule
     
