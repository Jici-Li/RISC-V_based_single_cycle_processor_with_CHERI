'timescale 1ns/1ps
module dataMemory(
    input wire clk,
    input wire writeData,
    input wire [31:0]ALUresult,
    output reg [31:0]readData
);
    reg [31:0]memory[0:255];//1KB memory
    always @(posedge clk) begin
        if(writeData)begin
            memory[ALUresult[11:2]]<=readData;// Word-aligned access
        end
    end

    initial begin
        integer i;
        for (i=0;i<256;i=i+1) begin
            memory[i]=32'b0;
        end
    end
    endmodule