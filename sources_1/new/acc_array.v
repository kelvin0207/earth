`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/15 13:11:15
// Design Name: inter-pe accumulation array
// Module Name: acc_array
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

module acc_array(
    input  wire    			clk,
    input  wire      		rst_n,

    // 输入：来自 PE array 的部分和
    input  wire   			in_valid,
    input  wire [4095:0]	in_psum,

    // 输出
    output reg            	out_valid,
    output reg  [255:0]   	out_vector
);

	// split
	wire [255:0]	pe0_psum;
	wire [255:0]	pe1_psum;
	wire [255:0]	pe2_psum;
	wire [255:0]	pe3_psum;
	wire [255:0]	pe4_psum;
	wire [255:0]	pe5_psum;
	wire [255:0]	pe6_psum;
	wire [255:0]	pe7_psum;
	wire [255:0]	pe8_psum;
	wire [255:0]	pe9_psum;
	wire [255:0]	pe10_psum;
	wire [255:0]	pe11_psum;
	wire [255:0]	pe12_psum;
	wire [255:0]	pe13_psum;
	wire [255:0]	pe14_psum;
	wire [255:0]	pe15_psum;

	assign pe0_psum = {	in_psum[(256* 0+16*0) +: 16], in_psum[(256* 1+16*0) +: 16], 
						in_psum[(256* 2+16*0) +: 16], in_psum[(256* 3+16*0) +: 16], 
						in_psum[(256* 4+16*0) +: 16], in_psum[(256* 5+16*0) +: 16], 
						in_psum[(256* 6+16*0) +: 16], in_psum[(256* 7+16*0) +: 16], 
						in_psum[(256* 8+16*0) +: 16], in_psum[(256* 9+16*0) +: 16],
						in_psum[(256*10+16*0) +: 16], in_psum[(256*11+16*0) +: 16], 
						in_psum[(256*12+16*0) +: 16], in_psum[(256*13+16*0) +: 16], 
						in_psum[(256*14+16*0) +: 16], in_psum[(256*15+16*0) +: 16]};
	assign pe1_psum = {	in_psum[(256* 0+16*1) +: 16], in_psum[(256* 1+16*1) +: 16], 
						in_psum[(256* 2+16*1) +: 16], in_psum[(256* 3+16*1) +: 16], 
						in_psum[(256* 4+16*1) +: 16], in_psum[(256* 5+16*1) +: 16], 
						in_psum[(256* 6+16*1) +: 16], in_psum[(256* 7+16*1) +: 16], 
						in_psum[(256* 8+16*1) +: 16], in_psum[(256* 9+16*1) +: 16],
						in_psum[(256*10+16*1) +: 16], in_psum[(256*11+16*1) +: 16], 
						in_psum[(256*12+16*1) +: 16], in_psum[(256*13+16*1) +: 16], 
						in_psum[(256*14+16*1) +: 16], in_psum[(256*15+16*1) +: 16]};
	assign pe2_psum = {	in_psum[(256* 0+16*2) +: 16], in_psum[(256* 1+16*2) +: 16], 
						in_psum[(256* 2+16*2) +: 16], in_psum[(256* 3+16*2) +: 16], 
						in_psum[(256* 4+16*2) +: 16], in_psum[(256* 5+16*2) +: 16], 
						in_psum[(256* 6+16*2) +: 16], in_psum[(256* 7+16*2) +: 16], 
						in_psum[(256* 8+16*2) +: 16], in_psum[(256* 9+16*2) +: 16],
						in_psum[(256*10+16*2) +: 16], in_psum[(256*11+16*2) +: 16], 
						in_psum[(256*12+16*2) +: 16], in_psum[(256*13+16*2) +: 16], 
						in_psum[(256*14+16*2) +: 16], in_psum[(256*15+16*2) +: 16]};
	assign pe3_psum = {	in_psum[(256* 0+16*3) +: 16], in_psum[(256* 1+16*3) +: 16], 
						in_psum[(256* 2+16*3) +: 16], in_psum[(256* 3+16*3) +: 16], 
						in_psum[(256* 4+16*3) +: 16], in_psum[(256* 5+16*3) +: 16], 
						in_psum[(256* 6+16*3) +: 16], in_psum[(256* 7+16*3) +: 16], 
						in_psum[(256* 8+16*3) +: 16], in_psum[(256* 9+16*3) +: 16],
						in_psum[(256*10+16*3) +: 16], in_psum[(256*11+16*3) +: 16], 
						in_psum[(256*12+16*3) +: 16], in_psum[(256*13+16*3) +: 16], 
						in_psum[(256*14+16*3) +: 16], in_psum[(256*15+16*3) +: 16]};
	assign pe4_psum = {	in_psum[(256* 0+16*4) +: 16], in_psum[(256* 1+16*4) +: 16], 
						in_psum[(256* 2+16*4) +: 16], in_psum[(256* 3+16*4) +: 16], 
						in_psum[(256* 4+16*4) +: 16], in_psum[(256* 5+16*4) +: 16], 
						in_psum[(256* 6+16*4) +: 16], in_psum[(256* 7+16*4) +: 16], 
						in_psum[(256* 8+16*4) +: 16], in_psum[(256* 9+16*4) +: 16],
						in_psum[(256*10+16*4) +: 16], in_psum[(256*11+16*4) +: 16], 
						in_psum[(256*12+16*4) +: 16], in_psum[(256*13+16*4) +: 16], 
						in_psum[(256*14+16*4) +: 16], in_psum[(256*15+16*4) +: 16]};
	assign pe5_psum = {	in_psum[(256* 0+16*5) +: 16], in_psum[(256* 1+16*5) +: 16], 
						in_psum[(256* 2+16*5) +: 16], in_psum[(256* 3+16*5) +: 16], 
						in_psum[(256* 4+16*5) +: 16], in_psum[(256* 5+16*5) +: 16], 
						in_psum[(256* 6+16*5) +: 16], in_psum[(256* 7+16*5) +: 16], 
						in_psum[(256* 8+16*5) +: 16], in_psum[(256* 9+16*5) +: 16],
						in_psum[(256*10+16*5) +: 16], in_psum[(256*11+16*5) +: 16], 
						in_psum[(256*12+16*5) +: 16], in_psum[(256*13+16*5) +: 16], 
						in_psum[(256*14+16*5) +: 16], in_psum[(256*15+16*5) +: 16]};
	assign pe6_psum = {	in_psum[(256* 0+16*6) +: 16], in_psum[(256* 1+16*6) +: 16], 
						in_psum[(256* 2+16*6) +: 16], in_psum[(256* 3+16*6) +: 16], 
						in_psum[(256* 4+16*6) +: 16], in_psum[(256* 5+16*6) +: 16], 
						in_psum[(256* 6+16*6) +: 16], in_psum[(256* 7+16*6) +: 16], 
						in_psum[(256* 8+16*6) +: 16], in_psum[(256* 9+16*6) +: 16],
						in_psum[(256*10+16*6) +: 16], in_psum[(256*11+16*6) +: 16], 
						in_psum[(256*12+16*6) +: 16], in_psum[(256*13+16*6) +: 16], 
						in_psum[(256*14+16*6) +: 16], in_psum[(256*15+16*6) +: 16]};
	assign pe7_psum = {	in_psum[(256* 0+16*7) +: 16], in_psum[(256* 1+16*7) +: 16], 
						in_psum[(256* 2+16*7) +: 16], in_psum[(256* 3+16*7) +: 16], 
						in_psum[(256* 4+16*7) +: 16], in_psum[(256* 5+16*7) +: 16], 
						in_psum[(256* 6+16*7) +: 16], in_psum[(256* 7+16*7) +: 16], 
						in_psum[(256* 8+16*7) +: 16], in_psum[(256* 9+16*7) +: 16],
						in_psum[(256*10+16*7) +: 16], in_psum[(256*11+16*7) +: 16], 
						in_psum[(256*12+16*7) +: 16], in_psum[(256*13+16*7) +: 16], 
						in_psum[(256*14+16*7) +: 16], in_psum[(256*15+16*7) +: 16]};
	assign pe8_psum = {	in_psum[(256* 0+16*8) +: 16], in_psum[(256* 1+16*8) +: 16], 
						in_psum[(256* 2+16*8) +: 16], in_psum[(256* 3+16*8) +: 16], 
						in_psum[(256* 4+16*8) +: 16], in_psum[(256* 5+16*8) +: 16], 
						in_psum[(256* 6+16*8) +: 16], in_psum[(256* 7+16*8) +: 16], 
						in_psum[(256* 8+16*8) +: 16], in_psum[(256* 9+16*8) +: 16],
						in_psum[(256*10+16*8) +: 16], in_psum[(256*11+16*8) +: 16], 
						in_psum[(256*12+16*8) +: 16], in_psum[(256*13+16*8) +: 16], 
						in_psum[(256*14+16*8) +: 16], in_psum[(256*15+16*8) +: 16]};
	assign pe9_psum = {	in_psum[(256* 0+16*9) +: 16], in_psum[(256* 1+16*9) +: 16], 
						in_psum[(256* 2+16*9) +: 16], in_psum[(256* 3+16*9) +: 16], 
						in_psum[(256* 4+16*9) +: 16], in_psum[(256* 5+16*9) +: 16], 
						in_psum[(256* 6+16*9) +: 16], in_psum[(256* 7+16*9) +: 16], 
						in_psum[(256* 8+16*9) +: 16], in_psum[(256* 9+16*9) +: 16],
						in_psum[(256*10+16*9) +: 16], in_psum[(256*11+16*9) +: 16], 
						in_psum[(256*12+16*9) +: 16], in_psum[(256*13+16*9) +: 16], 
						in_psum[(256*14+16*9) +: 16], in_psum[(256*15+16*9) +: 16]};
	assign pe10_psum = {in_psum[(256* 0+16*10) +: 16], in_psum[(256* 1+16*10) +: 16], 
						in_psum[(256* 2+16*10) +: 16], in_psum[(256* 3+16*10) +: 16], 
						in_psum[(256* 4+16*10) +: 16], in_psum[(256* 5+16*10) +: 16], 
						in_psum[(256* 6+16*10) +: 16], in_psum[(256* 7+16*10) +: 16], 
						in_psum[(256* 8+16*10) +: 16], in_psum[(256* 9+16*10) +: 16],
						in_psum[(256*10+16*10) +: 16], in_psum[(256*11+16*10) +: 16], 
						in_psum[(256*12+16*10) +: 16], in_psum[(256*13+16*10) +: 16], 
						in_psum[(256*14+16*10) +: 16], in_psum[(256*15+16*10) +: 16]};
	assign pe11_psum = {in_psum[(256* 0+16*11) +: 16], in_psum[(256* 1+16*11) +: 16], 
						in_psum[(256* 2+16*11) +: 16], in_psum[(256* 3+16*11) +: 16], 
						in_psum[(256* 4+16*11) +: 16], in_psum[(256* 5+16*11) +: 16], 
						in_psum[(256* 6+16*11) +: 16], in_psum[(256* 7+16*11) +: 16], 
						in_psum[(256* 8+16*11) +: 16], in_psum[(256* 9+16*11) +: 16],
						in_psum[(256*10+16*11) +: 16], in_psum[(256*11+16*11) +: 16], 
						in_psum[(256*12+16*11) +: 16], in_psum[(256*13+16*11) +: 16], 
						in_psum[(256*14+16*11) +: 16], in_psum[(256*15+16*11) +: 16]};
	assign pe12_psum = {in_psum[(256* 0+16*12) +: 16], in_psum[(256* 1+16*12) +: 16], 
						in_psum[(256* 2+16*12) +: 16], in_psum[(256* 3+16*12) +: 16], 
						in_psum[(256* 4+16*12) +: 16], in_psum[(256* 5+16*12) +: 16], 
						in_psum[(256* 6+16*12) +: 16], in_psum[(256* 7+16*12) +: 16], 
						in_psum[(256* 8+16*12) +: 16], in_psum[(256* 9+16*12) +: 16],
						in_psum[(256*10+16*12) +: 16], in_psum[(256*11+16*12) +: 16], 
						in_psum[(256*12+16*12) +: 16], in_psum[(256*13+16*12) +: 16], 
						in_psum[(256*14+16*12) +: 16], in_psum[(256*15+16*12) +: 16]};
	assign pe13_psum = {in_psum[(256* 0+16*13) +: 16], in_psum[(256* 1+16*13) +: 16], 
						in_psum[(256* 2+16*13) +: 16], in_psum[(256* 3+16*13) +: 16], 
						in_psum[(256* 4+16*13) +: 16], in_psum[(256* 5+16*13) +: 16], 
						in_psum[(256* 6+16*13) +: 16], in_psum[(256* 7+16*13) +: 16], 
						in_psum[(256* 8+16*13) +: 16], in_psum[(256* 9+16*13) +: 16],
						in_psum[(256*10+16*13) +: 16], in_psum[(256*11+16*13) +: 16], 
						in_psum[(256*12+16*13) +: 16], in_psum[(256*13+16*13) +: 16], 
						in_psum[(256*14+16*13) +: 16], in_psum[(256*15+16*13) +: 16]};
	assign pe14_psum = {in_psum[(256* 0+16*14) +: 16], in_psum[(256* 1+16*14) +: 16], 
						in_psum[(256* 2+16*14) +: 16], in_psum[(256* 3+16*14) +: 16], 
						in_psum[(256* 4+16*14) +: 16], in_psum[(256* 5+16*14) +: 16], 
						in_psum[(256* 6+16*14) +: 16], in_psum[(256* 7+16*14) +: 16], 
						in_psum[(256* 8+16*14) +: 16], in_psum[(256* 9+16*14) +: 16],
						in_psum[(256*10+16*14) +: 16], in_psum[(256*11+16*14) +: 16], 
						in_psum[(256*12+16*14) +: 16], in_psum[(256*13+16*14) +: 16], 
						in_psum[(256*14+16*14) +: 16], in_psum[(256*15+16*14) +: 16]};
	assign pe15_psum = {in_psum[(256* 0+16*15) +: 16], in_psum[(256* 1+16*15) +: 16], 
						in_psum[(256* 2+16*15) +: 16], in_psum[(256* 3+16*15) +: 16], 
						in_psum[(256* 4+16*15) +: 16], in_psum[(256* 5+16*15) +: 16], 
						in_psum[(256* 6+16*15) +: 16], in_psum[(256* 7+16*15) +: 16], 
						in_psum[(256* 8+16*15) +: 16], in_psum[(256* 9+16*15) +: 16],
						in_psum[(256*10+16*15) +: 16], in_psum[(256*11+16*15) +: 16], 
						in_psum[(256*12+16*15) +: 16], in_psum[(256*13+16*15) +: 16], 
						in_psum[(256*14+16*15) +: 16], in_psum[(256*15+16*15) +: 16]};

	// stage 0, reg in
	reg 			s0_valid;
	reg [255:0]		s0_pe0_psum;
	reg [255:0]		s0_pe1_psum;
	reg [255:0]		s0_pe2_psum;
	reg [255:0]		s0_pe3_psum;
	reg [255:0]		s0_pe4_psum;
	reg [255:0]		s0_pe5_psum;
	reg [255:0]		s0_pe6_psum;
	reg [255:0]		s0_pe7_psum;
	reg [255:0]		s0_pe8_psum;
	reg [255:0]		s0_pe9_psum;
	reg [255:0]		s0_pe10_psum;
	reg [255:0]		s0_pe11_psum;
	reg [255:0]		s0_pe12_psum;
	reg [255:0]		s0_pe13_psum;
	reg [255:0]		s0_pe14_psum;
	reg [255:0]		s0_pe15_psum;

	always@(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			s0_valid 		<= 0;
			s0_pe0_psum		<= 0;
			s0_pe1_psum		<= 0;
			s0_pe2_psum		<= 0;
			s0_pe3_psum		<= 0;
			s0_pe4_psum		<= 0;
			s0_pe5_psum		<= 0;
			s0_pe6_psum		<= 0;
			s0_pe7_psum		<= 0;
			s0_pe8_psum		<= 0;
			s0_pe9_psum		<= 0;
			s0_pe10_psum	<= 0;
			s0_pe11_psum	<= 0;
			s0_pe12_psum	<= 0;
			s0_pe13_psum	<= 0;
			s0_pe14_psum	<= 0;
			s0_pe15_psum	<= 0;
		end
		else begin
			s0_valid		<= in_valid;
			s0_pe0_psum		<= pe0_psum;
			s0_pe1_psum		<= pe1_psum;
			s0_pe2_psum		<= pe2_psum;
			s0_pe3_psum		<= pe3_psum;
			s0_pe4_psum		<= pe4_psum;
			s0_pe5_psum		<= pe5_psum;
			s0_pe6_psum		<= pe6_psum;
			s0_pe7_psum		<= pe7_psum;
			s0_pe8_psum		<= pe8_psum;
			s0_pe9_psum		<= pe9_psum;
			s0_pe10_psum	<= pe10_psum;
			s0_pe11_psum	<= pe11_psum;
			s0_pe12_psum	<= pe12_psum;
			s0_pe13_psum	<= pe13_psum;
			s0_pe14_psum	<= pe14_psum;
			s0_pe15_psum	<= pe15_psum;
		end
	end

	wire [15:0]	s0_out_valid;
	wire [15:0] s0_out_sum0;
	wire [15:0] s0_out_sum1;
	wire [15:0] s0_out_sum2;
	wire [15:0] s0_out_sum3;
	wire [15:0] s0_out_sum4;
	wire [15:0] s0_out_sum5;
	wire [15:0] s0_out_sum6;
	wire [15:0] s0_out_sum7;
	wire [15:0] s0_out_sum8;
	wire [15:0] s0_out_sum9;
	wire [15:0] s0_out_sum10;
	wire [15:0] s0_out_sum11;
	wire [15:0] s0_out_sum12;
	wire [15:0] s0_out_sum13;
	wire [15:0] s0_out_sum14;
	wire [15:0] s0_out_sum15;



	// inst 16 adder tree
	acc_16_1 acc0(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe0_psum),
		// Output
		.out_valid	(s0_out_valid[0]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum0)
	);

	acc_16_1 acc1(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe1_psum),
		// Output
		.out_valid	(s0_out_valid[1]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum1)
	);

	acc_16_1 acc2(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe2_psum),
		// Output
		.out_valid	(s0_out_valid[2]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum2)
	);

	acc_16_1 acc3(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe3_psum),
		// Output
		.out_valid	(s0_out_valid[3]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum3)
	);

	acc_16_1 acc4(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe4_psum),
		// Output
		.out_valid	(s0_out_valid[4]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum4)
	);

	acc_16_1 acc5(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe5_psum),
		// Output
		.out_valid	(s0_out_valid[5]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum5)
	);

	acc_16_1 acc6(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe6_psum),
		// Output
		.out_valid	(s0_out_valid[6]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum6)
	);

	acc_16_1 acc7(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe7_psum),
		// Output
		.out_valid	(s0_out_valid[7]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum7)
	);

	acc_16_1 acc8(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe8_psum),
		// Output
		.out_valid	(s0_out_valid[8]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum8)
	);

	acc_16_1 acc9(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe9_psum),
		// Output
		.out_valid	(s0_out_valid[9]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum9)
	);

	acc_16_1 acc10(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe10_psum),
		// Output
		.out_valid	(s0_out_valid[10]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum10)
	);

	acc_16_1 acc11(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe11_psum),
		// Output
		.out_valid	(s0_out_valid[11]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum11)
	);

	acc_16_1 acc12(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe12_psum),
		// Output
		.out_valid	(s0_out_valid[12]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum12)
	);

	acc_16_1 acc13(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe13_psum),
		// Output
		.out_valid	(s0_out_valid[13]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum13)
	);

	acc_16_1 acc14(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe14_psum),
		// Output
		.out_valid	(s0_out_valid[14]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum14)
	);

	acc_16_1 acc15(
    	.clk		(clk),
    	.rst_n		(rst_n),
    	// Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    	.in_valid	(s0_valid),
    	.in_ready	(),
    	.in_vec		(s0_pe15_psum),
		// Output
		.out_valid	(s0_out_valid[15]),
		.out_ready	(1'b1),
		.out_sum	(s0_out_sum15)
	);

	always@(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			out_valid	<= 0;
			out_vector	<= 0;
		end
		else begin
			out_valid	<= &s0_out_valid;
			out_vector	<= {s0_out_sum15, s0_out_sum14, s0_out_sum13, s0_out_sum12,
							s0_out_sum11, s0_out_sum10, s0_out_sum9 , s0_out_sum8 ,
							s0_out_sum7 , s0_out_sum6 , s0_out_sum5 , s0_out_sum4 ,
							s0_out_sum3 , s0_out_sum2 , s0_out_sum1 , s0_out_sum0 };
		end
	end

endmodule
