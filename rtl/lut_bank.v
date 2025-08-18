`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/18 15:42:41
// Design Name: 
// Module Name: lut_bank
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


module lut_bank #(
    parameter NUM_LUTS   = 16,   // LUT 数量
    parameter LUT_DEPTH  = 16,   // 每个 LUT 项数
    parameter LUT_WIDTH  = 4     // 每项位宽
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // LUT 更新接口
    input  wire                  cfg_update,   // 更新使能
    input  wire                  lut_wr_valid,

    // 查表接口
    input  wire [4095:0]         in_weights,   // 输入4-bit index * 1024
    output reg  [4095:0]         out_weights   // 输出映射结果
);

    reg [LUT_WIDTH-1:0] lut_mem [0:NUM_LUTS-1][0:LUT_DEPTH-1];

    integer i, j, lut_id; 

    // 更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i=0; i<NUM_LUTS; i=i+1)
                for (j=0; j<LUT_DEPTH; j=j+1)
                    lut_mem[i][j] <= 0;
        end 
        else if (cfg_update && lut_wr_valid) begin
            for (i=0; i<NUM_LUTS; i=i+1)
                for (j=0; j<LUT_DEPTH; j=j+1)
                    lut_mem[i][j] <= in_weights[i*LUT_DEPTH*LUT_WIDTH + j*LUT_WIDTH +: LUT_WIDTH];
        end
    end

    // 查表逻辑
    always @(*) begin
        for (i=0; i<1024; i=i+1) begin
            lut_id = i >> 6;
            out_weights[i*LUT_WIDTH +: LUT_WIDTH] = 
                lut_mem[lut_id][in_weights[i*4 +: 4]];
        end
    end

endmodule