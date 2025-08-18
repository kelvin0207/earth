`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/18 15:57:51
// Design Name: EARTH top module
// Module Name: TOP
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


module earth_top (
    input  wire         clk,
    input  wire         rst_n,

    // DRAM 交互接口， 单个 HBM2E 堆叠 → ~256 GB/s
	// 高端加速器（4~8 堆叠） → 1 ~ 2 TB/s
	// 数据源自 rambus
	// 我们使用单个 HBM2E, 所以一拍有2kb
    output wire         	dram_rd_en,       // DRAM 读使能
    output wire [31:0]  	dram_rd_addr,     // DRAM 读地址
    input  wire [2047:0] 	dram_rd_data,     // DRAM 读回数据
    input  wire         	dram_rd_valid,    // DRAM 读数据有效

    output wire         	dram_wr_en,       // DRAM 写使能
    output wire [31:0]  	dram_wr_addr,     // DRAM 写地址
    output wire [2047:0] 	dram_wr_data,     // DRAM 写数据
    input  wire         	dram_wr_ready,    // DRAM 写就绪

    // 与外部 Host 配置接口
    input  wire         	cfg_start,        // 启动信号
	input  wire  [7:0]		cfg_status,

    // 状态完成信号
    output wire          	done              // 计算完成
);


    // === 控制信号 ===
    wire [1:0]  cfg_mode;
    wire        cfg_valid;
    wire [2:0]  cfg_k;
    wire        cfg_topk_done;
    wire [7:0]  cfg_base_addr;    // 激活数据起始地址
    wire        cfg_update_LUT;   // 是否加载数据到 LUT
	wire 		cfg_bias_en;

	// === gating <-> buffer ===
	wire 		g2tbuf_wr_en;
	wire [7:0]	g2tbuf_wr_addr;
	wire [63:0]	g2tbuf_wr_data;
	wire		g2tbuf_rd_en;

	wire [1023:0]	tbuf2g_rdata;
	wire 		tbuf2g_rdata_valid;

	wire		cfg_dram2tbuf;
	wire		cfg_dram2wbuf;
	wire		cfg_tbuf2dram;
	wire 		cfg_acc_done;

	// === Gating <-> main ctrl. ===
    wire        g2t_topk_done;
    wire [55:0] g2t_topk_indices;

    // === Dispatcher <-> Buffers ===
    wire        	act_tbuf_rd_en;
    wire [7:0]  	act_tbuf_rd_addr;
    wire [1023:0]	act_tbuf_rd_data;
    wire        	act_tbuf_rd_valid;

    wire        	wgt_wbuf_rd_en;
    wire [7:0]  	wgt_wbuf_rd_addr;
    wire [4095:0] 	wgt_wbuf_rd_data;
    wire        	wgt_wbuf_rd_valid;

    assign wgt_wbuf_rd_valid = dram_rd_valid;
    
    // === Dispatcher -> PE array ===
    wire        	act_out_valid;
	wire			act_out_ready;
    wire [1023:0] 	act_out_acts;

    wire        	wgt_out_valid;
	wire			wgt_out_ready;
    wire [4095:0] 	wgt_out_weights;

    // === PE array -> Collector ===
    wire [15:0]   pe_out_valid_vec;
    wire [4095:0] pe_out_fp16s;

    // === Collector -> Gating ===
    wire          col_out_valid;
    wire [255:0]  col_out_sum;

	// === Main controller (简化为固定配置) ===
    main_controller u_main_controller (
        .clk			(clk), 
		.rst_n			(rst_n),
		// input side 
		.cfg_start		(cfg_start),
		.cfg_status		(cfg_status),
		.topk_done		(g2t_topk_done),
        .topk_indices   (g2t_topk_indices),
		// output side
        .cfg_mode		(cfg_mode),
        .cfg_valid		(cfg_valid),
        .cfg_k			(cfg_k),
        .cfg_topk_done	(cfg_topk_done),
        .cfg_base_addr	(cfg_base_addr),
		.cfg_dram2tbuf	(cfg_dram2tbuf),
		.cfg_dram2wbuf	(cfg_dram2wbuf),
		.cfg_tbuf2dram	(cfg_tbuf2dram),
		.cfg_update_LUT	(cfg_update_LUT),
		.cfg_acc_done	(cfg_acc_done),
		.dfg_bias_en	(cfg_bias_en),
		.dram_rd_en		(dram_rd_en),
		.dram_rd_addr	(dram_rd_addr),
		.dram_wr_addr	(dram_wr_addr),
        .done           (done)
    );

	wire [1023:0] tbuf_out_data;

	assign dram_wr_data = {tbuf_out_data, tbuf_out_data};
	assign dram_wr_en = cfg_tbuf2dram;

	// === Buffers (token / weight) ===
    token_buffer u_token_buffer (
        .clk					(clk), 
		.rst_n					(rst_n),
    	// Source select: 0=DRAM, 1=Dispatcher, 2=Collector, 3=Gating
        .in_src_sel				(cfg_status[1:0]), 
		// DRAM interface
        .in_dram_req			(dram_rd_valid),
		.in_dram_we				(cfg_dram2tbuf),
        .in_dram_addr			(cfg_base_addr), 
		.in_dram_wdata			(dram_rd_data[1023:0]),
        .out_dram_rdata			(tbuf_out_data), 
		.out_dram_rdata_valid	(),
		// act dispatcher interface
        .in_disp_req			(act_tbuf_rd_en),
        .in_disp_addr			(act_tbuf_rd_addr),
        .out_disp_rdata			(act_tbuf_rd_data),
        .out_disp_rdata_valid	(act_tbuf_rd_valid),
		// output collector insterface
        .in_col_req				(col_out_valid), 
		.in_col_addr			(cfg_base_addr), 
		.in_col_wdata			({col_out_sum, col_out_sum, col_out_sum, col_out_sum}),
		// gate module interface
        .in_gate_req			(g2tbuf_wr_en), 
		.in_gate_we				(g2tbuf_wr_en),
        .in_gate_addr			(g2tbuf_wr_addr), 
		.in_gate_wdata			({960'b0, g2tbuf_wr_data}),
        .out_gate_rdata			(tbuf2g_rdata), 
		.out_gate_rdata_valid	(tbuf2g_rdata_valid)
    );

    weight_buffer u_weight_buffer (
        .clk					(clk), 
		.rst_n					(rst_n),
        .in_dram_req			(dram_rd_valid),
		.in_dram_we				(cfg_dram2wbuf),
        .in_dram_addr			(cfg_base_addr), 
		.in_dram_wdata			({dram_rd_data, dram_rd_data}),
        .in_disp_req			(wgt_wbuf_rd_en),
        .in_disp_addr			(wgt_wbuf_rd_addr),
        .out_disp_rdata			(wgt_wbuf_rd_data)
    );

    // === Dispatchers ===
    act_dispatcher u_act_dispatcher (
        .clk				(clk), 
		.rst_n				(rst_n),
        .cfg_start			(cfg_valid),
        .cfg_base_addr		(cfg_base_addr),
        .tbuf_rd_en			(act_tbuf_rd_en),
        .tbuf_rd_addr		(act_tbuf_rd_addr),
        .tbuf_rd_data		(act_tbuf_rd_data),
        .tbuf_rd_valid		(act_tbuf_rd_valid),
        .out_valid			(act_out_valid),
        .out_ready			(act_out_ready),
        .out_acts			(act_out_acts)
    );

    weight_dispatcher u_weight_dispatcher (
        .clk				(clk), 
		.rst_n				(rst_n),
        .cfg_start			(cfg_valid),
        .cfg_base_addr		(cfg_base_addr),
        .cfg_update_LUT		(cfg_update_LUT),
        .wbuf_rd_en			(wgt_wbuf_rd_en),
        .wbuf_rd_addr		(wgt_wbuf_rd_addr),
        .wbuf_rd_data		(wgt_wbuf_rd_data),
        .wbuf_rd_valid		(wgt_wbuf_rd_valid),
        .out_valid			(wgt_out_valid),
        .out_ready			(wgt_out_ready),
        .out_weights		(wgt_out_weights)
    );

    // === PE Array ===
    pe_array u_pe_array (
        .clk				(clk), 
		.rst_n				(rst_n),
        .in_valid			(act_out_valid & wgt_out_valid),
        .in_ready			(act_out_ready),
        .out_ready			(1'b1),
        .in_fp16_acts		(act_out_acts),
        .in_int4s			(wgt_out_weights),
        .out_valid_vec		(pe_out_valid_vec),
        .out_fp16s			(pe_out_fp16s)
    );

    // === Collector ===
    output_collector u_collector (
        .clk				(clk), 
		.rst_n				(rst_n),
        .in_valid			(|pe_out_valid_vec),
        .in_psum			(pe_out_fp16s),
        .in_bias_en			(cfg_bias_en),
        .in_bias_data		(act_out_acts[255:0]),
        .in_accum_done		(cfg_acc_done),
        .out_valid			(col_out_valid),
        .out_sum			(col_out_sum)
    );

    // === Gating ===	
    gating_module u_gating_module (
        .clk				(clk), 
		.rst_n				(rst_n),
        .cfg_mode			(cfg_mode),
        .cfg_valid			(cfg_valid),
        .cfg_k				(cfg_k),
        .cfg_topk_done		(cfg_topk_done),
        .in_valid			(col_out_valid),
        .in_ready			(),
        .in_vec				(col_out_sum),
        .topk_done			(g2t_topk_done),
        .topk_indices		(g2t_topk_indices),
		// tbuf -> gate
        .tbuf_rd_en			(g2tbuf_rd_en), 
		.tbuf_rd_addr		(cfg_base_addr),
        .tbuf_rd_data		(tbuf2g_rdata[63:0]), 
		.tbuf_rd_valid		(tbuf2g_rdata_valid),
		// gate -> tbuf
        .tbuf_wr_en			(g2tbuf_wr_en), 
		.tbuf_wr_addr		(g2tbuf_wr_addr),
        .tbuf_wr_data		(g2tbuf_wr_data)
    );
endmodule