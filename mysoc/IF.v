// 这是一个简单的指令获取模块，包含了分支预测和跳转修正功能
module IF(
    input wire clk,
    input wire rst,
    input is_b_jump, // 输入信号，指示是否需要跳转
    input wire [31:0] instruction_in,
    output wire jump_error,
    output wire [31:0] jump_fix_addr, // 输出修正地址
    output wire [31:0] pc_next_out   // 输出下一个 PC 地址
);

wire [31:0] instruction;
assign instruction = instruction_in;
wire [31:0] imm_jal,imm_b;

// 提取 JAL 类指令的立即数
    assign imm_jal = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

// 提取 B 类指令的立即数
    assign imm_b = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

// 定义一个 3 级流水线寄存器，用于存储历史 PC 地址
    reg [31:0] PC_REG[2:0]; // 3 个寄存器组
    reg [31:0] pc_next;     // 下一个 PC 地址

// 输出下一个 PC 地址
    assign pc_next_out = pc_next;

// 判断指令类型
    wire is_jal_type = (instruction[6:0] == 7'b1101111); // JAL 指令 opcode
    wire is_jalr_type = (instruction[6:0] == 7'b1100111); // JALR 指令 opcode
    wire is_b_type = (instruction[6:0] == 7'b1100011); // B 类指令 opcode

// 保存指令类型历史
    reg is_b_type_history[2:0]; 
    reg is_jalr_type_history[2:0]; // 添加JALR历史

// 分支历史记录 (2位饱和计数器)
    reg [1:0] branch_history;
    
// 状态机定义
    reg [1:0] current_state, next_state;
    localparam STATE_JUMP = 2'b00; // 默认跳转状态
    localparam STATE_B = 2'b01;    // 顺序执行状态

// 保存状态机的历史状态（延迟 3 个时钟周期）
    reg [1:0] state_history [2:0];

// 状态机逻辑和指令类型历史更新
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= STATE_JUMP; // 复位时进入默认跳转状态
            state_history[0] <= STATE_JUMP;
            state_history[1] <= STATE_JUMP;
            state_history[2] <= STATE_JUMP;
            is_b_type_history[0] <= 1'b0;
            is_b_type_history[1] <= 1'b0;
            is_b_type_history[2] <= 1'b0;
            is_jalr_type_history[0] <= 1'b0; // 初始化JALR历史
            is_jalr_type_history[1] <= 1'b0;
            is_jalr_type_history[2] <= 1'b0;
            branch_history <= 2'b01; // 初始化为弱预测跳转
        end else begin
            current_state <= next_state;

            // 更新状态历史
            state_history[0] <= current_state;
            state_history[1] <= state_history[0];
            state_history[2] <= state_history[1];
            
            // 更新指令类型历史
            is_b_type_history[0] <= is_b_type;
            is_b_type_history[1] <= is_b_type_history[0];
            is_b_type_history[2] <= is_b_type_history[1];
            
            // 更新JALR指令类型历史
            is_jalr_type_history[0] <= is_jalr_type;
            is_jalr_type_history[1] <= is_jalr_type_history[0];
            is_jalr_type_history[2] <= is_jalr_type_history[1];
            



            // 更新分支历史 (当执行分支指令时) - 修正：使用EX阶段指令类型
            if (is_b_type_history[2]) begin
                if (is_b_jump) begin
                    // 分支执行，增加计数器，最大为11
                    branch_history <= (branch_history == 2'b11) ? 2'b11 : branch_history + 1;
                end else begin
                    // 分支不执行，减少计数器，最小为00
                    branch_history <= (branch_history == 2'b00) ? 2'b00 : branch_history - 1;
                end
            end
        end
    end

// 状态转移逻辑 - 基于分支历史而不是当前是否跳转
    always @(*) begin
        case (current_state)
            STATE_JUMP: begin
                // 在跳转状态时，根据分支历史决定是否切换
                if (branch_history < 2'b10) begin // 如果历史记录偏向不跳转 (00或01)
                    next_state = STATE_B;
                end else begin
                    next_state = STATE_JUMP;
                end
            end
            STATE_B: begin
                // 在顺序执行状态时，根据分支历史决定是否切换
                if (branch_history >= 2'b10) begin // 如果历史记录偏向跳转 (10或11)
                    next_state = STATE_JUMP;
                end else begin
                    next_state = STATE_B;
                end
            end
            default: next_state = STATE_JUMP;
        endcase
    end

// 在时钟上升沿更新流水线寄存器
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // 复位时将所有寄存器清零
            PC_REG[0] <= 32'b0;
            PC_REG[1] <= 32'b0;
            PC_REG[2] <= 32'b0;
            pc_next <= 32'b0;
        end else begin
            // 正常情况下，流水线寄存器向前推进
            PC_REG[0] <= pc_next;
            PC_REG[1] <= PC_REG[0];
            PC_REG[2] <= PC_REG[1];
            // JAL型指令直接执行，不进入预测
            if (is_jal_type) begin
                pc_next <= pc_next + imm_jal; // 直接跳转
            end
            // JALR型指令直接执行，不进入预测
            else if (is_jalr_type) begin
                // JALR指令需要从寄存器+立即数计算，但在这里无法获取寄存器值
                // 暂时按普通指令处理，后续由EX阶段进行正确计算和跳转修正
                pc_next <= pc_next + 4; // 暂时当作顺序执行
            end
            // B型指令根据状态机预测
            else if (is_b_type) begin
                if (current_state == STATE_JUMP) begin
                    pc_next <= pc_next + imm_b; // 预测跳转
                end else begin
                    pc_next <= pc_next + 4; // 预测不跳转
                end
            end
            // 其他指令顺序执行
            else begin
                pc_next <= pc_next + 4;
            end
        end
    end

// 判断跳转预测失败的逻辑 - 使用对应的指令类型历史
    assign jump_error = (is_b_type_history[2] && state_history[2] == STATE_JUMP && !is_b_jump) || 
                        (is_b_type_history[2] && state_history[2] == STATE_B && is_b_jump) ||
                        (is_jalr_type_history[2]); // JALR指令总是需要在EX阶段修正

// 输出修正地址
    assign jump_fix_addr = PC_REG[2] + 4; // 输出 3 个时钟周期前的 PC 地址

endmodule