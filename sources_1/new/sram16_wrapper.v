`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 10:19:46
// Design Name: 
// Module Name: sram16_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// NOTE:
// buffer depth (ADDR_WIDTH):
// simple estimation for synthesis, 256b is enough (addr_width=8)

// interface bandwidth (DATA_WIDTH):
// for act.: 1*4*16b = 64b
// for weight: 4*16*4b = 256b

module sram16_wrapper #(
    parameter ADDR_WIDTH = 8,     // 每个 bank 的地址宽度
    parameter DATA_WIDTH = 64     // 每个 bank 宽度（例如4×FP16=64bit）
)(
    input  wire                    clk,

    // === Load interface ===
    input  wire                    load_en,
    input  wire [ADDR_WIDTH-1:0]   load_addr,
    input  wire [DATA_WIDTH*16-1:0] load_data, // 按bank顺序打包的宽数据
    // 每个 bank 写入对应的 slice
    // load_addr 通常是 tile index 或 SRAM 行号

    // === Fetch interface ===
    input  wire                    fetch_en,
    input  wire [ADDR_WIDTH-1:0]   fetch_addr,
    output wire [DATA_WIDTH*16-1:0] fetch_data // 拼接 16 bank 的数据
);
    
    // 读数据的中间信号
    wire [DATA_WIDTH-1:0] fetch_data_bank [0:15];

    // 实例化 16 个 buffer
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : bank_gen
            buffer #(
                .ADDR_WIDTH (ADDR_WIDTH),
                .DATA_WIDTH (DATA_WIDTH)
            ) bank_inst (
                .clk     (clk),
                // 写口
                .wr_en   (load_en),
                .wr_addr (load_addr),
                .wr_data (load_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]),
                // 读口
                .rd_en   (fetch_en),
                .rd_addr (fetch_addr),
                .rd_data (fetch_data_bank[i])
            );
        end
    endgenerate

    // 拼接成总线输出
    assign fetch_data = { fetch_data_bank[15], fetch_data_bank[14],
                          fetch_data_bank[13], fetch_data_bank[12],
                          fetch_data_bank[11], fetch_data_bank[10],
                          fetch_data_bank[ 9], fetch_data_bank[ 8],
                          fetch_data_bank[ 7], fetch_data_bank[ 6],
                          fetch_data_bank[ 5], fetch_data_bank[ 4],
                          fetch_data_bank[ 3], fetch_data_bank[ 2],
                          fetch_data_bank[ 1], fetch_data_bank[ 0] };

endmodule