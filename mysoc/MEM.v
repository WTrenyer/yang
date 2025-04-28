module MEM(
    input wire clk,
    input wire rst,
    input wire mem_read,              // 读存储器信号
    input wire mem_write,             // 写存储器信号
    input wire [15:0] mem_addr,       // 存储器地址
    input wire [31:0] write_data,     // 写入存储器的数据
  
    output wire mem_ready,            // 存储器操作完成信号
    output wire [31:0] read_data,     // 从存储器读取的数据
    // 与外部存储器交互的接口
    output wire [15:0] ext_mem_addr,  // 外部存储器地址
    output wire [31:0] ext_mem_wdata, // 外部存储器写入数据
    output wire ext_mem_write,        // 外部存储器写使能
    output wire ext_mem_read,         // 外部存储器读使能
    input wire [31:0] ext_mem_rdata,  // 外部存储器读取数据
    input wire ext_mem_ready          // 外部存储器操作完成信号
);

    // 将输入信号直接传递给外部存储器
    assign ext_mem_addr = mem_addr;
    assign ext_mem_wdata = write_data;
    assign ext_mem_write = mem_write;
    assign ext_mem_read = mem_read;

    // 从外部存储器读取数据
  //////S
    assign read_data = write_data;

    // 操作完成信号
    assign mem_ready = ext_mem_ready;

endmodule