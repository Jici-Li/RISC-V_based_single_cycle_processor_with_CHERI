`timescale 1ns/1ps

module design(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] instr,       
    output wire [31:0] pc_out,
    output wire        trap,
    output wire [2:0]  trap_cause
);
    // =====================
    // PC
    // =====================
    reg [31:0] pc;
    assign pc_out = pc;

    wire [31:0] pc_plus4 = pc + 32'd4;

    // =====================
    // Decode fields
    // =====================
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    // =====================
    // Control
    // =====================
    wire Branch, MemRead_raw, MemtoReg, MemWrite_raw, ALUSrc, RegWrite_raw;
    wire Jal, Jalr, Lui, Auipc;
    wire [1:0] ALUOp;

    controlUnit CU(
        .opcode(opcode),
        .Branch(Branch),
        .MemRead(MemRead_raw),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite_raw),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite_raw),
        .Jal(Jal),
        .Jalr(Jalr),
        .Lui(Lui),
        .Auipc(Auipc),
        .ALUOp(ALUOp)
    );

    // =====================
    // Immediate
    // =====================
    wire [31:0] imm;
    immGen IG(.instr(instr), .imm(imm));

    // =====================
    // Register file
    // =====================
    wire [31:0] rd1, rd2;
    wire [31:0] writeBackData;

    Registerfile RF(
        .clk(clk),
        .RegWrite(RegWrite),
        .A1(rs1),
        .A2(rs2),
        .A3(rd),
        .writeData(writeBackData),
        .RD1(rd1),
        .RD2(rd2)
    );

    // =====================
    // ALU Control
    // =====================
    wire [3:0] ALUCtl;
    aluControl ALC(
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ALUCtl(ALUCtl)
    );

    // =====================
    // ALU inputs
    // =====================
    wire [31:0] srcB = ALUSrc ? imm : rd2;

    // AUIPC uses pc + imm (U-type)
    // Easiest: treat it as ALU op ADD with SrcA = pc
    wire [31:0] srcA = Auipc ? pc : rd1;

    wire [31:0] aluResult;
    wire zero;

    ALU alu(
        .SrcA(srcA),
        .SrcB(srcB),
        .ALUCtl(ALUCtl),
        .ALUResult(aluResult),
        .Zero(zero)
    );

    // =====================
    // Branch / Jump target
    // =====================
    wire takeBranch = Branch & zero; // 只支持 BEQ 的话这样写；BNE 你要用 funct3 分开
    wire [31:0] pc_branch = pc + imm;
    wire [31:0] pc_jal    = pc + imm;
    wire [31:0] pc_jalr   = (aluResult & 32'hFFFF_FFFE); // rs1+imm & ~1 （aluResult 在 jalr 下就是 rs1+imm）

    // =====================
    // Data memory
    // =====================
    wire [31:0] memRData;

    DataMemory DM(
        .clk(clk),
        .we(MemWrite),
        .re(MemRead),
        .addr(aluResult),
        .wdata(rd2),
        .rdata(memRData)
    );

    // =====================
    // CHERI minimal integration
    // =====================
    // 先给你一个“最小可跑”的 cap metadata：默认全部允许
    // 你以后把它换成真正的 cap regfile / metadata table
    wire cap_tag   = 1'b1;
    wire [31:0] cap_base   = 32'd0;
    wire [31:0] cap_length = 32'hFFFF_FFFF;
    wire cap_perm_load  = 1'b1;
    wire cap_perm_store = 1'b1;
    wire cap_perm_exec  = 1'b1;

    wire need_load  = MemRead_raw;
    wire need_store = MemWrite_raw;
    wire need_exec  = Jalr;

    wire cap_ok;
    wire [2:0] cap_cause;

    cheri_check CK(
        .tag(cap_tag),
        .base(cap_base),
        .length(cap_length),
        .addr(Jalr ? pc_jalr : aluResult), // exec-check看jalr目标；mem-check看aluResult
        .need_load(need_load),
        .need_store(need_store),
        .need_exec(need_exec),
        .perm_load(cap_perm_load),
        .perm_store(cap_perm_store),
        .perm_exec(cap_perm_exec),
        .ok(cap_ok),
        .cause(cap_cause)
    );

    assign trap = (need_load | need_store | need_exec) & ~cap_ok;
    assign trap_cause = cap_cause;

    // gate side effects
    wire MemRead  = MemRead_raw  & cap_ok;
    wire MemWrite = MemWrite_raw & cap_ok;
    wire RegWrite = RegWrite_raw & (~MemRead_raw | cap_ok); // load fault 不写回

    // =====================
    // Writeback
    // =====================
    wire [31:0] aluOrMem = MemtoReg ? memRData : aluResult;
    wire [31:0] rd_from_jal = pc_plus4;

    // LUI: write imm (U-type already shifted)
    wire [31:0] rd_lui = imm;

    assign writeBackData =
        Jal | Jalr ? rd_from_jal :
        Lui        ? rd_lui :
        aluOrMem;

    // =====================
    // PC next selection (priority)
    // trap > jalr > jal > branch > pc+4
    // =====================
    reg [31:0] pc_next;
    localparam [31:0] TRAP_VECTOR = 32'h0000_0100;

    always @(*) begin
        pc_next = pc_plus4;

        if (takeBranch) pc_next = pc_branch;
        if (Jal)        pc_next = pc_jal;
        if (Jalr & cap_ok) pc_next = pc_jalr;   // 非法 jalr 不跳
        if (trap)       pc_next = TRAP_VECTOR;
    end

    // =====================
    // PC register
    // =====================
    always @(posedge clk) begin
        if (rst) pc <= 32'd0;
        else     pc <= pc_next;
    end
endmodule
