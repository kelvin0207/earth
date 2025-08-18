`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/17 11:00:14
// Design Name: 
// Module Name: topk
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

// support at most 8 experts sort in 128 expert
// thus, idx bitwidth is 7
// once input 16 expert scores

//////////// FUNCTION NOTE /////////////////////
// draft by Jingkui

// 方法：比较 + 最小堆(min-heap)思路
// 用一个大小为 8 的寄存器堆存储当前的 top-8。
// 初始时写入前 8 个 (score, id)。
// 从第 9 个开始，每来一个新的 (score, id)，就比较它和当前 top-8 中的 最小值。
// 如果比最小值大，就替换掉最小值的位置。
// 否则丢弃。
// 最后输出整个寄存器堆（8 个结果，不保证顺序）。

// 硬件实现要点：
// 需要一个 找到最小值的模块（可以用并行比较树，log₂(8) 级延迟，代价小）。
// 每个新元素来时，只需 1 次比较 + 可能 1 次替换。
///////////////////////////////////////

module topk (
    input  wire                     clk,
    input  wire                     rst_n,

    // input stream
    input  wire                     valid_in,
    input  wire [15:0]              score_in,
    input  wire [6:0]               id_in,
    input  wire                     done,       // input finished

    // output
    output reg  [15:0]              topk_score, // 16分八次出来
    output reg  [55:0]              topk_id,    // 7*8 一次全出来给main ctrl
    output reg                      valid_out
);

    // internal storage
    reg [15:0]  buffer_scores [0:7];
    reg [6:0]   buffer_ids    [0:7];

    // cmp tree to find min

    // level 0
    wire [15:0] min_score0_0;
    wire [15:0] min_score0_1;
    wire [15:0] min_score0_2;
    wire [15:0] min_score0_3;

    wire [2 :0] min_index0_0;
    wire [2 :0] min_index0_1;
    wire [2 :0] min_index0_2;
    wire [2 :0] min_index0_3;

    assign min_score0_0 = (buffer_scores[0] < buffer_scores[1]) ? buffer_scores[0] : buffer_scores[1];
    assign min_score0_1 = (buffer_scores[2] < buffer_scores[3]) ? buffer_scores[2] : buffer_scores[3];
    assign min_score0_2 = (buffer_scores[4] < buffer_scores[5]) ? buffer_scores[4] : buffer_scores[5];
    assign min_score0_3 = (buffer_scores[6] < buffer_scores[7]) ? buffer_scores[6] : buffer_scores[7];

    assign min_index0_0 = (buffer_scores[0] < buffer_scores[1]) ? 3'd0 : 3'd1;
    assign min_index0_1 = (buffer_scores[2] < buffer_scores[3]) ? 3'd2 : 3'd3;
    assign min_index0_2 = (buffer_scores[4] < buffer_scores[5]) ? 3'd4 : 3'd5;
    assign min_index0_3 = (buffer_scores[6] < buffer_scores[7]) ? 3'd6 : 3'd7;

    // level 1
    wire [15:0] min_score1_0;
    wire [15:0] min_score1_1;

    wire [2 :0] min_index1_0;
    wire [2 :0] min_index1_1;

    assign min_score1_0 = (min_score0_0 < min_score0_1) ? min_score0_0 : min_score0_1;
    assign min_score1_1 = (min_score0_2 < min_score0_3) ? min_score0_2 : min_score0_3;

    assign min_index1_0 = (min_score0_0 < min_score0_1) ? min_index0_0 : min_index0_1;
    assign min_index1_1 = (min_score0_2 < min_score0_3) ? min_index0_2 : min_index0_3;

    // level 2 - root
    wire [15:0] min_score;
    wire [2:0]  min_index;

    assign min_score = (min_score1_0 < min_score1_1) ? min_score1_0 : min_score1_1;
    assign min_index = (min_score1_0 < min_score1_1) ? min_index1_0 : min_index1_1;

    // main process
    integer i;

    reg [2:0]   out_idx;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid_out   <= 1'b0;
            out_idx     <= 0;
            topk_score  <= 0;
            topk_id     <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                buffer_scores[i] <= 0;
                buffer_ids[i]    <= 0;
            end
        end 
        else if (valid_in && (score_in > min_score)) begin
                buffer_scores[min_index]    <= score_in;
                buffer_ids[min_index]       <= id_in;
        end
        else if (done) begin
            valid_out   <= 1'b1;
            topk_score  <= buffer_scores[out_idx];
            out_idx     <= out_idx + 1;  
            topk_id     <= {buffer_ids[7], buffer_ids[6], buffer_ids[5], buffer_ids[4], 
                            buffer_ids[3], buffer_ids[2], buffer_ids[1], buffer_ids[0]};  
        end
    end

endmodule
