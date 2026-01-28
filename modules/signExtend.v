'timescale 1ns/1ps
module signExtend(
    input  wire [31:0]instr,
    output reg  [31:0]imm
);
    wire [6:0]opcode=instr[6:0];

    always @(*) begin
        case (opcode)
            7'b0000011,//I-type
            7'b0010011,
            7'b1100111: 
                imm={{20{instr[31]}},instr[31:20]};
            7'b0100011://S-type
                imm={{20{instr[31]}},instr[31:25],instr[11:7]};
            7'b1100011://B-type
                imm={{19{instr[31]}},instr[31],instr[7],instr[30:25], instr[11:8],1'b0};
            7'b0110111,//U-type,lui 
            7'b0010111://U-type
                imm={instr[31:12],12'b0};
            7'b1101111: //J-type
                imm={{11{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
            default:
                imm=32'd0;
        endcase
    end
endmodule

