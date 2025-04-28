

module myCPU(
    input wire clk,
    input wire rst,
    input wire [31:0] instruction_spo, // 指令
    output wire [15:0] if_pc_addr, // PC 地址
    output wire [4:0]rd,
    output wire rd_enable, // 寄存器堆写使能信号
    output wire [31:0] wb_data, // 写回数据
    output wire [15:0] wb_addr, // 写回寄存器地址
    output wire wb_enable, // 写回使能信号
    output wire [31:0] read_data, // 写回值
    output wire [15:0]addr,
    // 外部存储器接口
    output wire [15:0] ext_mem_addr,
    output wire [31:0] ext_mem_wdata,
    output wire ext_mem_write,
    output wire ext_mem_read,
    input wire [31:0] ext_mem_rdata,
    input wire ext_mem_ready
);
reg [42:0]sign_3;
reg [42:0]sign_1;
    assign rd=sign_1[26:22];
    assign rd_enable=sign_3[12];

    // IF 阶段信号
    wire if_jump_error;
    wire [15:0] if_jump_fix_addr;
 /* verilator lint_off UNOPTFLAT */   wire branch_taken;

    // ID 阶段信号

    wire [31:0] id_reg_data1;
    wire [31:0] id_reg_data2;
    wire [31:0] id_imm_data;



    // EX 阶段信号
    wire [31:0] ex_alu_result;
    wire ex_data_conflict;


    // MEM 阶段信号
    wire mem_ready;


    // WB 阶段信号
    wire wb_reg_write_enable;
    wire [31:0] wb_write_data;
    wire [4:0] wb_write_addr;

wire [42:0]sign;
wire [15:0] next_addr;

//  IF if_instance (
//         .clk(clk),
//         .rst(rst),
//         .instruction_spo(instruction_spo),
//         .next_addr(next_addr),
//         .addr(addr)
//     );
    // IF 模块实例化
     IF if_stage(
         .clk(clk),
         .rst(rst),
         .is_b_jump(branch_taken), // 暂时设置为 0，实际需要连接控制信号
         .instruction_in(instruction_spo),
         .jump_error(if_jump_error),//output
         .jump_fix_addr(if_jump_fix_addr),
         .pc_next_out(if_pc_addr)
     );
 assign addr=if_jump_error?if_jump_fix_addr:if_pc_addr;  
     reg  [15:0]IF_jicunqi;
    //第一级流水线
    always @(posedge clk or negedge rst) 
        if(rst)
         IF_jicunqi<=16'b0;
        else if(branch_taken)
         IF_jicunqi<=0;
        else
         IF_jicunqi<=addr;

    // ID 模块实例化
    ID id_stage(
        .clk(clk),
        .rst(rst),
        .instruction(instruction_spo),
        .write_data(wb_write_data),
        .write_addr(wb_write_addr),
        .reg_write_enable(wb_reg_write_enable),
        .reg_data1(id_reg_data1),//output
        .reg_data2(id_reg_data2),
        .imm_data(id_imm_data)
    );
reg [95:0]ID_jicuqi;
//第二级流水线
always@(posedge clk or negedge rst)
    if(rst)
      ID_jicuqi<=96'b0;
    else if(branch_taken)
      ID_jicuqi<=0;
    else 
      ID_jicuqi<={id_reg_data1,id_reg_data2,id_imm_data};
reg [31:0]MEM_jicunqi;
    // EX 模块实例化

    Control control_unit(
        .Instruction(instruction_spo),       // 输入指令
        .sign(sign)           // 输出控制信号
    );
    always @(posedge clk or negedge rst) begin
        if(rst)
            sign_1<=43'b0;
        else
            sign_1<=sign;
    end
reg [42:0]sign_4;
    EX ex_stage(
        .clk(clk),
        .rst(rst),
        .operand1(ID_jicuqi[95:64]),                                   
        .operand2(ID_jicuqi[63:32]),  
        .imm_data(ID_jicuqi[31:0]),
        .pc_addr(addr),
//.pc_addr(IF_jicunqi),  // 当前 PC 地址
        .alu_control(sign_1[15:13]),
        .slti(sign_4[33]),
        .use_imm(sign_1[18]),
        .use_pc(sign_1[16]),
        .ex_dest(sign_1[26:22]),
        .mem_dest(sign_2[26:22]), 
        .wb_dest(sign_3[26:22]), 
        .is_b_type(sign_1[32]),
        .ex_write_enable(sign_1[12]), // EX 阶段写使能信号
        .mem_write_enable(sign_2[12]), // MEM 阶段写使能信号
        .wb_write_enable(sign_3[12]),// WB 阶段写使能信号
        .mem_data(EX_jicunqi[47:16]), // MEM 阶段写入的数据
        .wb_data(wb_write_data),
        .id_rs1(sign_1[6:2]),
        .id_rs2(sign_1[11:7]),
        .branch_control(sign_1[38:37]), // 控制信号
        .is_lui(sign_1[34]), // 是否为 LUI 指令
        .alu_result(ex_alu_result),//output
        .branch_taken(branch_taken),
        .data_conflict(ex_data_conflict)
    );
reg [42:0]sign_2;
    always @(posedge clk or negedge rst) begin
        if(rst)
            sign_2<=43'b0;
        else
            sign_2<=sign_1;
    end

reg [47:0] EX_jicunqi;
always @(posedge clk or negedge rst) begin
    if(rst)
      EX_jicunqi<=64'b0;
    else if(branch_taken)
      EX_jicunqi<=0;
    else begin
        EX_jicunqi[15:0]<=IF_jicunqi;
        EX_jicunqi[47:16]<=ex_alu_result;
    end
      
    
end

    // MEM 模块实例化
    MEM mem_stage(
        .clk(clk),
        .rst(rst),
        .mem_read(sign_2[36]),
        .mem_write(sign_2[35]),
        .mem_addr(EX_jicunqi[15:0]),
        .write_data(EX_jicunqi[47:16]),
        .read_data(read_data),//output  // 从存储器读取的数据
        .mem_ready(mem_ready),
        .ext_mem_addr(ext_mem_addr),
        .ext_mem_wdata(ext_mem_wdata),
        .ext_mem_write(ext_mem_write),
        .ext_mem_read(ext_mem_read),
        .ext_mem_rdata(ext_mem_rdata),
        .ext_mem_ready(ext_mem_ready)
    );

    always @(posedge clk or negedge rst) begin
        if(rst)
            sign_3<=43'b0;
        else
            sign_3<=sign_2;
    end
        always @(posedge clk or negedge rst) begin
        if(rst)
            sign_4<=43'b0;
        else
            sign_4<=sign_3;
    end
    
//第四级流水线
always @(posedge clk or negedge rst) begin
    if(rst)
     MEM_jicunqi<=32'b0;
    else if(branch_taken)
     MEM_jicunqi<=0;
    else 
     MEM_jicunqi<=read_data;
end
    // WB 模块实例化
    WB wb_stage(
        .clk(clk),
        .rst(rst),
        .wb_enable(sign_3[12]),
        .wb_data(MEM_jicunqi),
        .wb_dest(sign_3[26:22]), 
        .is_b_type(sign_3[32]),
        .reg_write_enable(wb_reg_write_enable),//output
        .write_data(wb_write_data),
        .write_addr(wb_write_addr)
    );

assign wb_data=wb_write_data;
assign wb_enable=sign_3[12];

endmodule



    // 数据存储器模块
    module MEMModule(
        input wire clk,
        input wire rst,
        input wire mem_read,
        input wire mem_write,
        input wire [15:0] addr,
        input wire [31:0] write_data,
        output wire [31:0] read_data,
        output wire ready
    );
        reg [31:0] memory [0:255]; // 256 x 32 位存储器
        reg mem_ready;

        assign read_data = memory[addr[7:0]];
        assign ready = mem_ready;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                mem_ready <= 1'b0;
            end else begin
                if (mem_write) begin
                    memory[addr[7:0]] <= write_data; // 写操作
                    mem_ready <= 1'b1;
                end else if (mem_read) begin
                    mem_ready <= 1'b1; // 读操作完成
                end else begin
                    mem_ready <= 1'b0;
                end
            end
        end
    endmodule
