`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/18 17:56:19
// Design Name: 
// Module Name: tb_earth_top
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

module tb_earth_top;

    reg clk;
    reg rst_n;
    reg cfg_start;
    reg [7:0] cfg_status;

    wire dram_rd_en;
    wire [31:0] dram_rd_addr;
    reg [2047:0] dram_rd_data;
    reg dram_rd_valid;

    wire dram_wr_en;
    wire [31:0] dram_wr_addr;
    wire [2047:0] dram_wr_data;
    reg dram_wr_ready;

    wire done;

    // ------------------------
    // DUT 实例化
    // ------------------------
    earth_top dut (
        .clk(clk),
        .rst_n(rst_n),

        .dram_rd_en(dram_rd_en),
        .dram_rd_addr(dram_rd_addr),
        .dram_rd_data(dram_rd_data),
        .dram_rd_valid(dram_rd_valid),

        .dram_wr_en(dram_wr_en),
        .dram_wr_addr(dram_wr_addr),
        .dram_wr_data(dram_wr_data),
        .dram_wr_ready(dram_wr_ready),

        .cfg_start(cfg_start),
        .cfg_status(cfg_status),

        .done(done)
    );

    // ------------------------
    // Clock & Reset
    // ------------------------
    initial begin
        clk = 0;
        forever #1 clk = ~clk; // 2ns 时钟周期
    end

    initial begin
        rst_n = 0;
        cfg_start = 0;
        cfg_status = 8'd0;
        dram_rd_data = 0;
        dram_rd_valid = 0;
        dram_wr_ready = 1;

        #10 rst_n = 1; // 释放复位
        #5  cfg_start = 1; // 发起启动
        cfg_status = 8'd1;
    end

    // ------------------------
    // 简易 DRAM 模型
    // ------------------------
    reg [2047:0] dram_mem [0:255];
    integer i;

    initial begin
        // 初始化 dram_mem
        for (i = 0; i < 256; i = i + 1) begin
            dram_mem[i] = {2048{1'b0}};
        end
        dram_mem[0] = {2048{1'b1}}; // 给个非零数据测试
    end

    // 读响应逻辑
    always @(posedge clk) begin
        if (dram_rd_en) begin
            dram_rd_data <= dram_mem[dram_rd_addr];
            dram_rd_valid <= 1'b1;
        end else begin
            dram_rd_valid <= 1'b0;
        end
    end

    // 写逻辑
    always @(posedge clk) begin
        if (dram_wr_en && dram_wr_ready) begin
            dram_mem[dram_wr_addr] <= dram_wr_data;
            $display("[%0t] DRAM WRITE: addr=%0d data[63:0]=%h", $time, dram_wr_addr, dram_wr_data[63:0]);
        end
    end

    // ------------------------
    // 仿真结束条件
    // ------------------------
    initial begin
        #10000;
        if (done) begin
            $display("[%0t] DUT DONE!", $time);
        end else begin
            $display("[%0t] TIMEOUT! DUT not finished.", $time);
        end
        $finish;
    end

endmodule
