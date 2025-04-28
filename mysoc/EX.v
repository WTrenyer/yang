module EX(
    input wire clk,
    input wire rst,
    input wire [31:0] operand1,       // 操作数1（寄存器数据）
    input wire [31:0] operand2,       // 操作数2（寄存器数据）
    input wire [31:0] imm_data,       // 立即数
    input wire slti,                 // 是否为 SLTI SLTIU指令
    input wire [15:0] pc_addr,        // 当前 PC 地址
    input wire [2:0] alu_control,     // ALU 控制信号
    input wire use_imm,               // 是否使用立即数作为操作数1
    input wire is_b_type,             // 是否为分支指令
    input wire use_pc,                // 是否使用 PC 地址作为操作数2
    input wire [4:0] ex_dest,         // EX 阶段目标寄存器地址
    input wire [4:0] mem_dest,        // MEM 阶段目标寄存器地址
    input wire [4:0] wb_dest,         // WB 阶段目标寄存器地址
    input wire ex_write_enable,       // EX 阶段写使能信号
    input wire mem_write_enable,      // MEM 阶段写使能信号
    input wire wb_write_enable,       // WB 阶段写使能信号

    
    input wire [31:0] mem_data,       // MEM阶段写入的数据
    input wire [31:0] wb_data,        // WB 阶段写入的数据
    input wire [4:0] id_rs1,          // ID 阶段源寄存器1地址
    input wire [4:0] id_rs2,          // ID 阶段源寄存器2地址
    input wire [1:0] branch_control,  // 分支控制信号
    input wire is_lui,             // 是否为 LUI 指令
    output wire [31:0] alu_result,    // ALU 计算结果
    output wire data_conflict,        // 数据冲突信号
    output wire branch_taken          // 分支是否被执行
);

     wire [31:0] corrected_operand1;
     wire [31:0] corrected_operand2;
    wire Zero;
    wire data_sign;
assign result=(slti==1&&data_sign==0) ? 1:
              (slti==1&&data_sign==1) ? 0:
              (slti==0) ?      alu_result:
              32'b0; // SLTI 指令的结果
    // 数据冲突检测信号
   // 数据冲突检测模块实例化
   DataConflictDetector conflict_detector(
       .id_rs1(id_rs1),
       .id_rs2(id_rs2),
       .ex_dest(ex_dest),
       .mem_dest(mem_dest),
       .wb_dest(wb_dest),
       .ex_write_enable(ex_write_enable),
       .mem_write_enable(mem_write_enable),
       .wb_write_enable(wb_write_enable),
       .conflict(data_conflict)
   );


wire op1_wb_front=(wb_write_enable && id_rs1 == wb_dest) ? 1'b1 : 1'b0;
wire op1_mem_front=(mem_write_enable && id_rs1 == mem_dest) ? 1'b1 : 1'b0;
wire op2_wb_front=(wb_write_enable && id_rs2 == wb_dest) ? 1'b1 : 1'b0;
wire op2_mem_front=(mem_write_enable && id_rs2 == mem_dest) ? 1'b1 : 1'b0;
   // 数据前推逻辑
assign corrected_operand1 =  (mem_write_enable && id_rs2 == mem_dest) ? mem_data :
                             (wb_write_enable && id_rs2 == wb_dest) ?wb_data:
                             operand1 ;

assign corrected_operand2 = (mem_write_enable && id_rs1 == mem_dest) ?mem_data:
                            (wb_write_enable && id_rs1 == wb_dest) ?wb_data:
                            operand2;

   // 根据输入信号选择操作数
    wire [31:0] alu_operand1 ;
    assign alu_operand1 = use_imm ? corrected_operand1:  imm_data; // 操作数1：立即数或寄存器数据

    wire [31:0] alu_operand2 ;
    assign alu_operand2 = is_lui ? 32'b0 : // LUI 指令
                          use_pc ?corrected_operand2  :pc_addr;   // 操作数2：PC 地址或寄存器数据

    // ALU 模块实例化
    ALU alu(
        .operand1(alu_operand1),
        .operand2(alu_operand2),
        .alu_control(alu_control),
        .result(alu_result),
        .Zero(Zero),
        .data_sign(data_sign)
    );
    // 分支判断逻辑
    assign branch_taken =((branch_control == 2'b00 && Zero) ||                  // BEQ: 等于
                         (branch_control == 2'b01 && !Zero) ||                // BNE: 不等于
                         (branch_control == 2'b10 && !data_sign) ||           // BGE: 大于等于（有符号）
                         (branch_control == 2'b11 && data_sign) ||            // BLT: 小于（有符号）
                         (branch_control == 2'b11 && alu_result[31] == 0) ||  // BLTU: 小于（无符号）
                         (branch_control == 2'b10 && alu_result[31] == 1))&&(is_b_type);    // BGEU: 大于等于（无符号）


endmodule
// ALU 模块
module ALU(
    input wire [31:0] operand1,       
    input wire [31:0] operand2,     
    input wire [2:0] alu_control,    // ALU 控制信号
    output wire Zero,                // 零标志
    output wire data_sign,           // 数据符号位
    output reg [31:0] result          // ALU 计算结果
);
    always @(*) begin
        case (alu_control)
            3'b000: result = operand1 + operand2;  // 加法
            3'b001: result = operand1 - operand2;  // 减法
            3'b010: result = operand1 & operand2;  // 按位与
            3'b011: result = operand1 | operand2;  // 按位或
            3'b100: result = operand1 ^ operand2;  // 按位异或
            3'b101: result = operand1 << operand2;        // 左移1位
            3'b110: result = operand1 >> operand2;        // 右移1位
            3'b111: result = (operand1 < operand2) ? 3'b001 : 3'b000; // 比较
            default: result = 32'b0;              // 默认值
        endcase
    end

    // 设置 Zero 标志，如果结果为零
    assign Zero = (result == 32'b0) ? 1'b1 : 1'b0;
    
    // 数据符号位（最高位）
    assign data_sign = result[31];


endmodule

 // 数据冲突检测模块
 module DataConflictDetector(
     input wire [4:0] id_rs1,          // ID 阶段源寄存器1地址
     input wire [4:0] id_rs2,          // ID 阶段源寄存器2地址
     input wire [4:0] ex_dest,         // EX 阶段目标寄存器地址
     input wire [4:0] mem_dest,        // MEM 阶段目标寄存器地址
     input wire [4:0] wb_dest,         // WB 阶段目标寄存器地址
     input wire ex_write_enable,       // EX 阶段写使能信号
     input wire mem_write_enable,      // MEM 阶段写使能信号
     input wire wb_write_enable,       // WB 阶段写使能信号
     output wire conflict              // 数据冲突信号
 );
     assign conflict = 
         (ex_write_enable && (id_rs1 == ex_dest || id_rs2 == ex_dest) && (ex_dest != 5'b0)) ||
         (mem_write_enable && (id_rs1 == mem_dest || id_rs2 == mem_dest) && (mem_dest != 5'b0)) ||
         (wb_write_enable && (id_rs1 == wb_dest || id_rs2 == wb_dest) && (wb_dest != 5'b0));
 endmodule