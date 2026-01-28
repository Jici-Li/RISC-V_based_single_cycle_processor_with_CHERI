'timescale 1ns/1ps
module ALU(
    input wire[31:0]SrcA,SrcB,
    input wire[3:0]aluControl,
    output reg[31:0]ALUresult,
    output reg Zero
);

// alu_ops.vh
always @(*) begin
 case(aluControl)
  `define ALU_ADD 
  4'b0000 result=SrcA+SrcB;
  `define ALU_SUB 
  4'b0001 result=SrcA-SrcB;
  `define ALU_AND 
  4'b0010 result=SrcA&SrcB;
  `define ALU_OR  
  4'b0011 result=SrcA|SrcB;
  `define ALU_XOR 
  4'b0100 result=SrcA^SrcB;
   default result=32'b0;
endcase
Zero=(result==32'b0);
end
endmodule

