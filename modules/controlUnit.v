'timescale 1ns/1ps

module controUnit(
    input wire [6:0]op,
    output reg Branch,MemRead,MemtoReg,
    output reg MemWrite,ALUSrc,RegWrite,
    output reg Jal,Jalr,
    output reg Lui,Auipc
);
    always @(*) begin
        // Default values
        Branch=0;MemRead=0;MemtoReg=0;
        MemWrite=0;ALUSrc=0;RegWrite=0;
        Jal=0;Jalr=0;
        Lui=0;Auipc=0;
        case (op)
            7'b0110011:begin //R-type
                RegWrite=1;
            end
            7'b0000011:begin //Load
                MemRead=1;
                MemtoReg=1;
                ALUSrc=1;
                RegWrite=1;
            end
            7'b0100011:begin //Store
                MemWrite=1;
                ALUSrc=1;
            end
            7'b1100011:begin //Branch
                Branch=1;
            end
            7'b0010011:begin //I-type
                ALUSrc=1;
                RegWrite=1;
            end
            7'b1101111:begin //JAL
                Jal=1;
                RegWrite=1;
            end
            7'b1100111:begin //JALR
                Jalr=1;
                ALUSrc=1;
                RegWrite=1;
            end
            7'b0110111:begin //LUI
                Lui=1;
                RegWrite=1;
            end
            7'b0010111:begin //AUIPC
                Auipc=1;
                RegWrite=1;
            end
        endcase
    end
    endmodule