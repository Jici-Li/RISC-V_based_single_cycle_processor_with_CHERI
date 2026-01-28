'timscale 1ns/1ps
module aluControl(
    input wire[1:0]aluOp,
    input wire[2:0]funct3,
    input wire[6:0]funct7,
    output reg[3:0]ALUControl
);

always @(*) begin
    case(aluOp)
        2'b00:ALUControl=4'b0010; // ADD
        2'b01:ALUControl=4'b0110; // SUB for branch
        2'b10:begin
            case({funct3,funct7})
                3'b000:ALUControl=4'b0000; // ADD
                3'b001:ALUControl=4'b0001; // SUB
                3'b010:ALUControl=4'b0010; // AND
                3'b100:ALUControl=4'b0011; // OR
                3'b110:ALUControl=4'b0100; // XOR
                default:ALUControl=4'b1111; // Invalid operation
            endcase
        end
        default: ALUControl=4'b1111; // Invalid operation
    endcase
end
endmodule
