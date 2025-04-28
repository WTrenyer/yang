module ID(
    input wire clk,
    input wire rst,
    input wire [31:0] instruction, // 输入指令
    input wire [31:0] write_data,  // 写入寄存器的数据
    input wire [4:0] write_addr,   // 写入寄存器的地址
    input wire reg_write_enable,   // 写使能信号
    output wire [31:0] reg_data1,  // 读取的第一个寄存器数据
    output wire [31:0] reg_data2,  // 读取的第二个寄存器数据
    output wire [31:0] imm_data    // 提取的立即数
);
    // 立即数提取模块
    ImmediateExtractor imm_extractor(
        .instruction(instruction),
        .imm_data(imm_data)
    );

    // 寄存器文件模块
    RegisterFile reg_file(
        .clk(clk),
        .rst(rst),
        .read_addr1(instruction[19:15]), // rs1
        .read_addr2(instruction[24:20]), // rs2
        .write_addr(write_addr),
        .write_data(write_data),
        .reg_write_enable(reg_write_enable),
        .read_data1(reg_data2),
        .read_data2(reg_data1)
    );

endmodule

// 立即数提取模块
module ImmediateExtractor(
    input wire [31:0] instruction,
    output reg [31:0] imm_data
);
    always @(*) begin
        case (instruction[6:0])
            7'b0010011, // I 类型指令
            7'b0000011: // Load 指令
                imm_data = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011: // S 类型指令
                imm_data = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b1100011: // B 类型指令
                imm_data = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            7'b1101111: // J 类型指令
                imm_data = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            7'b1100111: // JALR 指令
                imm_data = {{20{instruction[31]}}, instruction[31:20]};
            7'b0110111: // LUI 指令
                imm_data = {instruction[31:12], 12'b0};
            7'b0010111: // AUIPC 指令
                imm_data = {instruction[31:12], 12'b0};
            default: // 默认值
                imm_data = 32'b0;
        endcase
    end
endmodule

// 寄存器文件模块
module RegisterFile(
    input wire clk,
    input wire rst,
    input wire [4:0] read_addr1,  // 第一个读取寄存器地址
    input wire [4:0] read_addr2,  // 第二个读取寄存器地址
    input wire [4:0] write_addr,  // 写入寄存器地址
    input wire [31:0] write_data, // 写入寄存器的数据
    input wire reg_write_enable,  // 写使能信号
    output wire [31:0] read_data1, // 第一个读取寄存器数据
    output wire [31:0] read_data2  // 第二个读取寄存器数据
);
    reg [31:0] registers [0:31]; // 32 个 32 位寄存器

    // 异步读取
    assign read_data1 =  registers[read_addr1] ; // x0 寄存器始终为 0
    assign read_data2 =  registers[read_addr2] ;

    // 同步写入
    integer i;
    always @(posedge clk or negedge rst) begin
        if (rst) begin
            // 复位时清零所有寄存器
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write_enable && write_addr != 0) begin
            // 写入数据到指定寄存器（x0 寄存器始终为 0）
            registers[write_addr] <= write_data;
        end
    end
endmodule