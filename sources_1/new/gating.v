`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/16 16:48:43
// Design Name: Gating module
// Module Name: gating
// Project Name: EARTH
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



/////////////////// FUNCTION NOTE: //////////////////
// drafted by Jingkui

/////// For Router-Linear computation /////////
// 1. Gating module recieves the results from output collector (RL-out)

// 2. on top-k module:
// finish the top-k tell main ctrl. to load the experts

// 3. on Arith. module:
// finish softmax and norm. to get weight, stored in local buffer for later use
// Note: because we first topk than softmax, there is no need for norm.

//////// For Activation Function (GELU as an example) //////
// 1. Gating module recieves the results from output collector (Up-proj out)

// 2. on Arith. module:
// finish non-linear calculaiton (16 results on cycle).

//////// For Aggregation (Final operation) //////
// 1. Gating module recieves the results from output collector (expert-out / Down-proj out)

// 2. on Arth. module:
// load the weights stored in local buffer, and multiply with expert-out 
// (for the second and following expert-out) load previous partial sum from Token buffer 
// (only 16 FP16 results)
// Accumulate with the previous psum (16-ele vector)
// write back to Token buffer

/////////////////// FUNCTION NOTE END //////////////////

// ============================================================================
// Gating Module (MoE Router/Activation/Aggregation)
// - 吞吐：每拍 16 个 FP16（打包 256bit），完全流式 ready/valid
// - 三种工作模式：Router-Linear (TOPK+SOFTMAX)、Activation(GELU)、Aggregation(权重×专家输出 + 累加)
// - 不实现具体数学：softmax/gelu/vec_mul/vec_add/topk 作为外部算子模块被实例化
// - 提供 Local-Weight-Buffer 与 Token-Buffer 的互联接口
// NOTE:
// Gating module 并不需要一次处理16个数，而是将其放在一个FIFO里面，依次处理即可
// 理由如下：
// 我们以 QWen3-30B-A3B 为例，dim=2048，我们的PE array（16个PE）一次处理1*64*16的矩阵乘法
// 所以需要2048/64 = 32拍才能出一次结果，因此我们只需要pipeline起来即可，不需要单独为每个结果准备一套硬件
// ============================================================================

module gating_module (
    input  wire              clk,
    input  wire              rst_n,

    // ===== 模式与控制 =====
    input  wire [1:0]        cfg_mode,    // 0:softmax  1: norm  2: ACT  3: AGG
    input  wire              cfg_valid,   // valid 表示启动处理
    input  wire [2:0]        cfg_k,       // top-k 的 K+1 (<=KMAX) assume KMAX<=8
    input  wire              cfg_topk_done,
	// e.g. cfg_k=0b111 means KMAX=8

    // ===== 输入：来自 Output Collector 的 16×FP16 向量流 =====
    input  wire              in_valid,
    output wire              in_ready,
    input  wire [255:0]      in_vec,

    // ===== Router 结果给主控：TopK 结果 =====
    output reg               topk_done,
    output reg  [23:0]       topk_indices, // 每个 index 4bits 示例；实际按你路由空间位宽改
    // e.g. idx7(3bit), idx6, ..., idx0, 3*8bit=24bit in total

    // ===== 输出：在 ACT 模式或 AGG 最终结果需要向下游吐出时可用 =====
    // ===== Token Buffer（部分和/最终结果）======
    // 读旧 psum / weights
    output reg                   tbuf_rd_en,
    output reg  [7:0]            tbuf_rd_addr,
    input  wire [63:0]           tbuf_rd_data, // 取四次
    input  wire                  tbuf_rd_valid,
    // 写新 psum / weights
    output wire                  tbuf_wr_en, 
    output wire [7:0]            tbuf_wr_addr,
    output wire [63:0]           tbuf_wr_data // 分四次写回
);

    assign in_ready = 1;

    // input FIFO, 类似FIFO，但是实际上就是一个buffer
    // 一次全填满
    reg [16:0] FIFO [0:15];
    reg [3:0]  read_idx; // 读16次
    reg [6:0]  expert_id;

    always@(posedge clk or rst_n) begin
        if(~rst_n) begin
            FIFO    <= 0;
        end
        else if (in_valid) begin
            FIFO[0 ] <= in_vec[(16*0 ) +: 16];
            FIFO[1 ] <= in_vec[(16*1 ) +: 16];
            FIFO[2 ] <= in_vec[(16*2 ) +: 16];
            FIFO[3 ] <= in_vec[(16*3 ) +: 16];
            FIFO[4 ] <= in_vec[(16*4 ) +: 16];
            FIFO[5 ] <= in_vec[(16*5 ) +: 16];
            FIFO[6 ] <= in_vec[(16*6 ) +: 16];
            FIFO[7 ] <= in_vec[(16*7 ) +: 16];
            FIFO[8 ] <= in_vec[(16*8 ) +: 16];
            FIFO[9 ] <= in_vec[(16*9 ) +: 16];
            FIFO[10] <= in_vec[(16*10) +: 16];
            FIFO[11] <= in_vec[(16*11) +: 16];
            FIFO[12] <= in_vec[(16*12) +: 16];
            FIFO[13] <= in_vec[(16*13) +: 16];
            FIFO[14] <= in_vec[(16*14) +: 16];
            FIFO[15] <= in_vec[(16*15) +: 16];
        end
    end

    always@(posedge clk or rst_n) begin
        if (~rst_n) begin
            read_idx    <= 0;
            expert_id   <= 0;
        end
        else if(cfg_valid) begin
            read_idx    <= read_idx + 4'b1;
            expert_id   <= expert_id + 7'b1;
        end
    end

    wire [15:0] topk_out;

    topk topk (
        .clk        (clk),
        .rst_n      (rst_n),
        // input stream
        .valid_in   (cfg_valid && (cfg_mode==2'b00)),
        .score_in   (FIFO[read_idx]),
        .id_in      (expert_id),
        .done       (cfg_topk_done),
        // output
        .topk_score (topk_out),
        .topk_id    (topk_indices),
        .valid_out  (topk_done)
    );

    wire        out_valid;
    wire [15:0] out_data;
    arith_pipeline arith_pipeline(
        .clk        (clk),
        .rst_n      (rst_n),
        // input side
        .in_valid   (cfg_valid),
        .in_data    (topk_done? topk_out:FIFO[read_idx]),
        .in_psum    (tbuf_rd_data[15:0]),
        .in_mode    (cfg_mode),     
        // output side
        .out_valid  (out_valid),
        .out_data   (out_data)
    );

    always@(posedge clk or rst_n) begin
        if (~rst_n) begin
            tbuf_rd_en      <= 0;
            tbuf_rd_addr    <= 0;
        end
        else if(cfg_mode==2'b11) begin
            tbuf_rd_en      <= 1;
            tbuf_rd_addr    <= tbuf_rd_addr + 1l
        end
    end

    output wire                  tbuf_wr_en, 
    output wire [7:0]            tbuf_wr_addr,
    output wire [63:0]           tbuf_wr_data // 分四次写回
    

endmodule
