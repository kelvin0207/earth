// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/11 13:11:15
// Design Name: weight data dispatcher
// Module Name: weight_dispatcher
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

// Fetch from weight buffer
// dispatch to pe array

module weight_dispatcher(
    input  wire             clk,
    input  wire             rst_n,

    // 控制接口
    input  wire             cfg_start,
    input  wire [7:0]       cfg_base_addr,
    input  wire             cfg_update_LUT,

    // buffer 接口
    output reg              wbuf_rd_en,
    output reg  [7:0]       wbuf_rd_addr,
    input  wire [4095:0]    wbuf_rd_data,
    input  wire             wbuf_rd_valid,

    // PE array 接口
    output reg              out_valid,
    input  wire             out_ready,
    output reg  [4095:0]    out_weights
);

    // FSM 与 act_dispatcher 一样
    localparam S_IDLE  = 2'd0;
    localparam S_FETCH = 2'd1;
    localparam S_DISP  = 2'd2;

    reg [1:0] state, next_state;
    reg [7:0] rd_addr_reg;

    // LUT 子模块
    wire [4095:0] lut_out;

    lut_bank u_lut_bank (
        .clk			(clk),
        .rst_n			(rst_n),
        .cfg_update		(cfg_update_LUT),
        .lut_wr_valid	(wbuf_rd_valid),
        .in_weights		(wbuf_rd_data),   // 原始权重作为查表索引
        .out_weights	(lut_out)
    );

    // FSM
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) 
			state <= S_IDLE;
        else        
			state <= next_state;
    end
	
    always @(*) begin
        case (state)
            S_IDLE:  next_state = cfg_start ? S_FETCH : S_IDLE;
            S_FETCH: next_state = wbuf_rd_valid ? S_DISP : S_FETCH;
            S_DISP:  next_state = (out_valid && out_ready) ? S_FETCH : S_DISP;
            default: next_state = S_IDLE;
        endcase
    end

    // 地址
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            rd_addr_reg <= 8'd0;
        else if (state == S_IDLE && cfg_start)
            rd_addr_reg <= cfg_base_addr;
        else if (state == S_DISP && out_valid && out_ready)
            rd_addr_reg <= rd_addr_reg + 1'b1;
    end

    // buffer 控制
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wbuf_rd_en   <= 1'b0;
            wbuf_rd_addr <= 8'd0;
        end else if (state == S_FETCH) begin
            wbuf_rd_en   <= 1'b1;
            wbuf_rd_addr <= rd_addr_reg;
        end else begin
            wbuf_rd_en   <= 1'b0;
        end
    end

    // 输出
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid   <= 1'b0;
            out_weights <= 0;
        end else begin
            case (state)
                S_FETCH: begin
                    if (wbuf_rd_valid) begin
                        // mux: LUT更新时，直接传原始数据，不走查表
                        out_weights <= cfg_update_LUT ? wbuf_rd_data : lut_out;
                        out_valid   <= 1'b1;
                    end
                end
                S_DISP: if (out_valid && out_ready) out_valid <= 1'b0;
                default: out_valid <= 1'b0;
            endcase
        end
    end

endmodule
