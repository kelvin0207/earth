`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/11 13:11:15
// Design Name: activation data dispatcher
// Module Name: act_dispatcher
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

module act_dispatcher #(
    parameter ADDR_WIDTH = 8,
    parameter ACT_WIDTH  = 1024 // 16组激活总线宽度
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // 与上游 controller 或 DMA 接口
    input  wire                  start,       // 开始调度
    input  wire [ADDR_WIDTH-1:0] base_addr,   // 激活数据起始地址

    // 与片上 buffer 接口
    output reg                   buf_rd_en,
    output reg  [ADDR_WIDTH-1:0] buf_rd_addr,
    input  wire [ACT_WIDTH-1:0]  buf_rd_data,

    // 与 PE array 接口
    output reg                   out_valid,
    input  wire                  out_ready,
    output reg  [ACT_WIDTH-1:0]  out_acts
);

    reg [ADDR_WIDTH-1:0] tile_cnt;
    reg                  busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy        <= 1'b0;
            tile_cnt    <= {ADDR_WIDTH{1'b0}};
            buf_rd_en   <= 1'b0;
            buf_rd_addr <= {ADDR_WIDTH{1'b0}};
            out_valid   <= 1'b0;
            out_acts    <= {ACT_WIDTH{1'b0}};
        end else begin
            if (start && !busy) begin
                busy        <= 1'b1;
                tile_cnt    <= 0;
                buf_rd_en   <= 1'b1;
                buf_rd_addr <= base_addr;
            end else if (busy) begin
                if (buf_rd_en) begin
                    // 下周期可以把数据送到 PE
                    out_acts  <= buf_rd_data;
                    out_valid <= 1'b1;
                    buf_rd_en <= 1'b0; // 停止读，等待 PE array 消费
                end else if (out_valid && out_ready) begin
                    // PE array 接收完成
                    out_valid <= 1'b0;

                    // 如果还有数据，发下一次读
                    if (tile_cnt + 1 < num_tiles) begin
                        tile_cnt    <= tile_cnt + 1;
                        buf_rd_en   <= 1'b1;
                        buf_rd_addr <= base_addr + tile_cnt + 1;
                    end else begin
                        busy <= 1'b0; // 完成所有 tile
                    end
                end
            end
        end
    end

endmodule
