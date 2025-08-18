`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/18 16:02:39
// Design Name: 
// Module Name: main_controller
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


// 控制器简单版
module main_controller (
    input  wire         clk,
    input  wire         rst_n,

    // input side
    input  wire         cfg_start,
    input  wire [7:0]   cfg_status,
    input  wire         topk_done,
    input  wire [55:0]  topk_indices,
    // output side
    output reg  [1:0]   cfg_mode,
    output reg          cfg_valid,
    output reg  [2:0]   cfg_k,
    output reg          cfg_topk_done,
    output reg  [7:0]   cfg_base_addr,
    output reg          cfg_dram2tbuf,
    output reg          cfg_dram2wbuf,
    output reg          cfg_tbuf2dram,
    output reg          cfg_update_LUT,
    output reg          cfg_acc_done,
    output reg          dfg_bias_en,
    output reg          dram_rd_en,
    output reg  [31:0]  dram_rd_addr,
    output reg  [31:0]  dram_wr_addr,
    output reg          done
);

    // FSM 状态定义
    localparam  S_IDLE      = 3'd0;
    localparam  S_CONFIG    = 3'd1;
    localparam  S_RUN_LOAD  = 3'd2;   // 从 DRAM 加载
    localparam  S_RUN_COMP  = 3'd3;   // 片上计算
    localparam  S_DONE      = 3'd4;

    reg [2:0] state, next_state;

    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // 状态转移逻辑
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (cfg_start)
                    next_state = S_CONFIG;
            end
            S_CONFIG: begin
                next_state = S_RUN_LOAD;
            end
            S_RUN_LOAD: begin
                // 这里简单条件控制，避免被优化掉
                if (cfg_status[0])
                    next_state = S_RUN_COMP;
            end
            S_RUN_COMP: begin
                if (topk_done)
                    next_state = S_DONE;
            end
            S_DONE: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // 输出逻辑（防优化）
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cfg_mode       <= 4'd0;
            cfg_valid      <= 1'b0;
            cfg_k          <= 3'd0;
            cfg_topk_done  <= 1'b0;
            cfg_base_addr  <= 8'd0;
            cfg_dram2tbuf  <= 1'b0;
            cfg_dram2wbuf  <= 1'b0;
            cfg_tbuf2dram  <= 1'b0;
            cfg_update_LUT <= 1'b0;
            cfg_acc_done   <= 1'b0;
            dfg_bias_en    <= 1'b0;
            dram_rd_en     <= 1'b0;
            dram_rd_addr   <= 32'd0;
            dram_wr_addr   <= 32'd0;
            done           <= 0;
        end 
        else begin
            case (state)
                S_IDLE: begin
                    cfg_valid <= 1'b0;
                end
                S_CONFIG: begin
                    cfg_mode        <= 2'b10;  // 随便赋一个值，避免被优化掉
                    cfg_tbuf2dram   <= 1'b1;
                    cfg_valid       <= 1'b1;
                    cfg_k           <= cfg_k + 1;  // 循环自增
                    cfg_base_addr   <= topk_indices[7:0];
                end
                S_RUN_LOAD: begin
                    cfg_dram2tbuf <= 1'b1;
                    cfg_dram2wbuf <= ~cfg_dram2wbuf; // 每拍翻转，防优化
                    dram_rd_en    <= 1'b1;
                    dram_rd_addr  <= dram_rd_addr + 32'd64;
                    cfg_base_addr   <= topk_indices[15:8];
                end
                S_RUN_COMP: begin
                    dfg_bias_en    <= 1'b1;
                    cfg_update_LUT <= ~cfg_update_LUT; // 保持翻转
                end
                S_DONE: begin
                    cfg_acc_done   <= 1'b1;
                    cfg_tbuf2dram  <= 1'b1;
                    dram_wr_addr   <= dram_wr_addr + 32'd128;
                    cfg_topk_done  <= 1'b1;
                    done           <= 1;
                end
            endcase
        end
    end

endmodule
