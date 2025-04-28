module Control(
    input [31:0] Instruction,
    output wire [42:0] sign // 扩展输出宽度
);

// 指令类型编码
parameter [3:0] R_TYPE = 4'b0001;
parameter [3:0] I_LOAD = 4'b0010;
parameter [3:0] I_IMM  = 4'b0011;
parameter [3:0] LUI    = 4'b0100;
parameter [3:0] AUIPC  = 4'b0101;
parameter [3:0] JAL    = 4'b0110;
parameter [3:0] JALR   = 4'b0111;
parameter [3:0] BRANCH = 4'b1000;
parameter [3:0] S_TYPE = 4'b1001;


wire [3:0] instruction_type;
wire mem_rd_en;
wire mem_wd_en;
wire register_en;
wire [1:0] res_choose;
wire [1:0] alu_a;
wire [1:0] alu_b;
wire [2:0] ALU_OP;
wire [4:0] read_data1;
wire [4:0] read_data2;
wire [4:0] register_addr;
wire [7:0] mem_addr;
wire [1:0] jump;
// R-type instructions
wire is_r_type;
assign is_r_type = (Instruction[6:0] == 7'b0110011);
wire [2:0] ALU_OP_r;
assign ALU_OP_r = (Instruction[14:12] == 3'b000 && Instruction[31:25] == 7'b0000000) ? 3'b000 : // ADD
                  (Instruction[14:12] == 3'b000 && Instruction[31:25] == 7'b0100000) ? 3'b001 : // SUB
                  (Instruction[14:12] == 3'b001) ? 3'b110 : // SLL
                  (Instruction[14:12] == 3'b100) ? 3'b100 : // 0OR
                  (Instruction[14:12] == 3'b101 && Instruction[31:25] == 7'b0000000) ? 3'b111 : // SRL
                  (Instruction[14:12] == 3'b101 && Instruction[31:25] == 7'b0100000) ? 3'b111 : // SRA
                  (Instruction[14:12] == 3'b110) ? 3'b011 : // OR
                  (Instruction[14:12] == 3'b111) ? 3'b010 : // AND
                  3'b000;

// I-type load instructions
wire is_i_load;
assign is_i_load = (Instruction[6:0] == 7'b0000011);

// I-type immediate instructions
wire is_i_imm;
assign is_i_imm = (Instruction[6:0] == 7'b0010011);
wire [2:0] ALU_OP_i_imm;
assign ALU_OP_i_imm = (Instruction[14:12] == 3'b000) ? 3'b000 : // ADDI
                      (Instruction[14:12] == 3'b001 && Instruction[31:25] == 7'b0000000) ? 3'b110 : // SLLI
                      (Instruction[14:12] == 3'b100) ? 3'b100 : // 0ORI
                      (Instruction[14:12] == 3'b010) ? 3'b001: // SLTI/////////////////////////////
                      (Instruction[14:12] == 3'b011) ? 3'b001 : // SLTIU////////////////////////////
                      (Instruction[14:12] == 3'b100) ? 3'b100 : // XORI////////////////////////////
                      (Instruction[14:12] == 3'b101 && Instruction[31:25] == 7'b0000000) ? 3'b111 : // SRLI
                      (Instruction[14:12] == 3'b101 && Instruction[31:25] == 7'b0100000) ? 3'b111 : // SRAI
                      (Instruction[14:12] == 3'b110) ? 3'b011 : // ORI
                      (Instruction[14:12] == 3'b111) ? 3'b010 : // ANDI
                      3'b000;
wire slti;
assign   slti = (ALU_OP_i_imm==3'b001) ? 1'b1 : 1'b0;


// LUI
wire is_lui;
assign is_lui = (Instruction[6:0] == 7'b0110111);

// AUIPC
wire is_auipc;
assign is_auipc = (Instruction[6:0] == 7'b0010111);

// JAL
wire is_jal;
assign is_jal = (Instruction[6:0] == 7'b1101111);

// JALR
wire is_jalr;
assign is_jalr = (Instruction[6:0] == 7'b1100111);

// Branch instructions
wire is_branch;
assign is_branch = (Instruction[6:0] == 7'b1100011);
wire [2:0] ALU_OP_branch;
wire [1:0]b_type ;
assign ALU_OP_branch = (Instruction[14:12] == 3'b000) ? 3'b001 : // BEQ
                       (Instruction[14:12] == 3'b001) ? 3'b001 : // BNE
                       (Instruction[14:12] == 3'b100) ? 3'b110 : // BLT
                       (Instruction[14:12] == 3'b101) ? 3'b110 : // BGE
                       (Instruction[14:12] == 3'b110) ? 3'b111 : // BLTU
                       (Instruction[14:12] == 3'b111) ? 3'b111 : // BGEU
                       3'b000;
assign b_type        = (Instruction[14:12] == 3'b000) ? 2'b01 : // BEQ
                       (Instruction[14:12] == 3'b001) ? 2'b00 : // BNE
                       (Instruction[14:12] == 3'b100) ? 2'b11 : // BLT
                       (Instruction[14:12] == 3'b101) ? 2'b10 : // BGE
                       (Instruction[14:12] == 3'b110) ? 2'b11 : // BLTU
                       (Instruction[14:12] == 3'b111) ? 2'b10 : // BGEU
                       2'b00;
// S-type store instructions
wire is_s_type;
assign is_s_type = (Instruction[6:0] == 7'b0100011);

// 指令类型标志

assign instruction_type = is_r_type ? R_TYPE :
                          is_i_load ? I_LOAD :
                          is_i_imm ? I_IMM :
                          is_lui ? LUI :
                          is_auipc ? AUIPC :
                          is_jal ? JAL :
                          is_jalr ? JALR :
                          is_branch ? BRANCH :
                          is_s_type ? S_TYPE :
                          4'b0000; // 未知类型

// 最终输出
assign ALU_OP = is_r_type ? ALU_OP_r :
                is_i_imm ? ALU_OP_i_imm :
                is_branch ? ALU_OP_branch :
                is_i_load ?3'b000:
                is_s_type ?3'b000:
                3'b000;

assign register_en = is_r_type || is_i_load || is_i_imm || is_lui || is_auipc || is_jal || is_jalr ;
assign res_choose = (is_i_imm|| is_i_load) ? 2'b01 :
                    is_branch ? 2'b10 :
                    (is_s_type ) ? 2'b11 :
                    2'b00;

assign alu_a = (is_jalr || is_jal|| is_branch) ? 2'b01 : 2'b00;
assign alu_b = (is_i_load  || is_s_type ||  is_lui || is_branch) ? 2'b01 : 2'b00;
assign read_data1 = (is_r_type || is_i_load || is_i_imm || is_branch || is_s_type || is_jalr || is_lui) ? Instruction[19:15] : 5'b0;
assign read_data2 = (is_r_type || is_branch || is_s_type) ? Instruction[24:20] : 5'b0;
assign register_addr = (is_r_type || is_i_load || is_i_imm || is_lui || is_auipc || is_jal || is_jalr) ? Instruction[11:7] : 5'b00000;
assign mem_rd_en = is_i_load;
assign mem_wd_en = is_s_type;
assign jump = (is_jal || is_jalr) ? 2'b01 :
              is_branch ? 2'b10 :
              2'b00;
assign mem_addr = (is_i_load || is_s_type) ? Instruction[24:20] : 5'b00000;
wire [2:0] mem_type;

assign mem_type = (is_i_load || is_s_type)?Instruction[14:12]:3'b0;
wire is_b_type;
assign is_b_type = (is_branch) ? 1'b1 : 1'b0;
assign sign[41:35]= {mem_type,            //41:39
                     b_type,             // 38:37
                     mem_rd_en,        // 36
                     mem_wd_en};       //35
assign sign[34]=is_lui;         // 34



assign sign[33] = slti;          // 33
assign sign[32] = 1'b0;       // 32is_b_type
assign sign[31:0]={   mem_addr,         // 31:27
                      register_addr,    // 26:22
                      res_choose,       // 21:20
                      alu_a,            // 19:18
                      alu_b,            // 17:16
                      ALU_OP,           // 15:13
                      register_en,      // 12
                      read_data2,       // 11:7
                      read_data1,       // 6:2
                      jump};            // 1:0

endmodule