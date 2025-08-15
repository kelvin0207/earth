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

	wire [255:0]	out_vector;
	wire			out_valid;

	acc_array acc_array(
		.clk		(clk),
		.rst_n		(rst_n),
		// 输入：来自 PE array 的部分和
		.in_valid	(in_valid),
		.in_psum	(in_psum),
		// 输出
		.out_valid	(out_valid),
		.out_vector	(out_vector)
	);

	
	// 累加寄存器（保存中间结果，Output-Stationary）
    reg [255:0] 	accum_reg;

	always@(posedge clk or rst_n) begin
		if(~rst_n) begin
			accum_reg <= 0;
		end
		else if (in_bias_en) begin
			accum_reg <= in_bias_data;
		end
		else begin
			accum_reg <= 

endmodule