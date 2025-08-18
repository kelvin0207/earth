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

// Fetch from token buffer
// dispatch to pe array
module act_dispatcher(
    input  wire             clk,
    input  wire             rst_n,

    // 上游控制接口
    input  wire             cfg_start,       // 开始调度
    input  wire [7:0]       cfg_base_addr,   // 激活数据起始地址

    // 与片上 token buffer 接口
    output reg              tbuf_rd_en,
    output reg  [7:0]       tbuf_rd_addr,
    input  wire [1023:0]    tbuf_rd_data,
    input  wire             tbuf_rd_valid,

    // 与 PE array 接口
    output reg              out_valid,
    input  wire             out_ready,
    output reg  [1023:0]    out_acts
);

    // FSM 状态编码
    localparam S_IDLE  = 2'd0;
    localparam S_FETCH = 2'd1;
    localparam S_DISP  = 2'd2;

    reg [1:0] state, next_state;
    reg [7:0] rd_addr_reg;   // 当前读地址寄存

    // FSM: 状态转移
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // FSM: 下一个状态逻辑
    always @(*) begin
        case (state)
            S_IDLE: begin
                if (cfg_start)
                    next_state = S_FETCH;
                else
                    next_state = S_IDLE;
            end

            S_FETCH: begin
                if (tbuf_rd_valid)   // token buffer 返回有效数据
                    next_state = S_DISP;
                else
                    next_state = S_FETCH;
            end

            S_DISP: begin
                if (out_valid && out_ready)  // PE array 接收完成
                    next_state = S_FETCH;
                else
                    next_state = S_DISP;
            end

            default: next_state = S_IDLE;
        endcase
    end

    // 读地址管理
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_addr_reg <= 8'd0;
        end 
        else if (state == S_IDLE && cfg_start) begin
            rd_addr_reg <= cfg_base_addr;   // 初始化
        end 
        else if (state == S_DISP && out_valid && out_ready) begin
            rd_addr_reg <= rd_addr_reg + 1'b1; // 下一次地址
        end
    end

    // token buffer 控制
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            tbuf_rd_en   <= 1'b0;
            tbuf_rd_addr <= 8'd0;
        end else begin
            case (state)
                S_FETCH: begin
                    tbuf_rd_en   <= 1'b1;
                    tbuf_rd_addr <= rd_addr_reg;
                end
                default: begin
                    tbuf_rd_en   <= 1'b0;
                end
            endcase
        end
    end

    // 输出控制
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid <= 1'b0;
            out_acts  <= 1024'd0;
        end 
        else begin
            case (state)
                S_FETCH: begin
                    if (tbuf_rd_valid) begin
                        out_acts  <= tbuf_rd_data;
                        out_valid <= 1'b1;
                    end
                end

                S_DISP: begin
                    if (out_valid && out_ready) begin
                        out_valid <= 1'b0; // 发送完成
                    end
                end

                default: begin
                    out_valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
