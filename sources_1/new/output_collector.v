`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/15 15:11:15
// Design Name: output collector
// Module Name: output_collector
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

module output_collector(
	input  wire      		clk,
    input  wire      		rst_n,

    // 输入：来自 PE array 的部分和
    input  wire   			in_valid,
    input  wire [4095:0]	in_psum,

    // Bias 输入
    input  wire   			in_bias_en,  // 是否累加 bias
    input  wire [255:0]		in_bias_data,

    // 控制：是否结束本轮累加
    input  wire   			in_accum_done,

    // 输出
	// Gating module side
	output reg 				out_valid,
	output reg	[255:0] 	out_sum
);

	// spatial acc
	wire 			sp_acc_out_valid;
	wire [255:0] 	sp_acc_out_vector;
	acc_array acc_array(
		.clk		(clk),
		.rst_n		(rst_n),
		// 输入：来自 PE array 的部分和
		.in_valid	(in_valid),
		.in_psum	(in_psum),
		// 输出
		.out_valid	(sp_acc_out_valid),
		.out_vector	(sp_acc_out_vector)
	);

	// temporal acc
	wire			tp_acc_in_valid;
	wire [255:0]	tp_acc_in_vector;
	
	assign tp_acc_in_valid = in_bias_en? 1 : sp_acc_out_valid;
	assign tp_acc_in_vector = in_bias_en? in_bias_data : sp_acc_out_vector;

	acc_temporal acc_temporal(
    	.clk			(clk),
    	.rst_n			(rst_n),
		// input side
		.in_valid		(tp_acc_in_valid),
		.in_vector		(tp_acc_in_vector),
		.in_accum_done	(in_accum_done),
		// output side
		.out_valid		(out_valid),
		.out_vector		(out_sum)
    );

endmodule