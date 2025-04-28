module WB(
    input wire clk,
    input wire rst,
    input wire wb_enable,             // 写回使能信号
    input wire [31:0] wb_data,        // 写回的数据
    input wire [4:0] wb_dest,         // 写回的目标寄存器地址
    input wire is_b_type,           // 是否为分支指令
    output wire reg_write_enable,     // 寄存器写使能信号
    output wire [31:0] write_data,    // 写入寄存器的数据
    output wire [4:0] write_addr      // 写入寄存器的地址
);

    // 写使能信号直接传递
    assign reg_write_enable = wb_enable;
//没有执行S型指令
/////当执行新减法负数默认为0

    // 写入寄存器的数据和地址
    assign write_data = (wb_dest==0)?0: wb_data;
    assign write_addr = wb_dest;

endmodule