`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/11 13:11:15
// Design Name: dot-product unit
// Module Name: dpu
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

module dpu (
    input  wire         clk,
    input  wire         rst_n,

    // Input side
    input  wire         in_valid,
    output wire         in_ready,
    input  wire [15:0]  in_fp16_0,
    input  wire [15:0]  in_fp16_1,
    input  wire [15:0]  in_fp16_2,
    input  wire [15:0]  in_fp16_3,
    input  wire [3:0]   in_int4_0,
    input  wire [3:0]   in_int4_1,
    input  wire [3:0]   in_int4_2,
    input  wire [3:0]   in_int4_3,

    // Output side
    output wire         out_valid,
    input  wire         out_ready,
    output wire [15:0]  out_fp16
);

    // ------------------------------
    // Stage 0: Four multipliers in parallel
    // ------------------------------
    wire m0_in_ready;
	wire m1_in_ready;
	wire m2_in_ready;
	wire m3_in_ready;

    wire m0_out_valid;
	wire m1_out_valid;
	wire m2_out_valid;
	wire m3_out_valid;

    wire [15:0] m0_out_fp16;
	wire [15:0] m1_out_fp16;
	wire [15:0] m2_out_fp16;
	wire [15:0] m3_out_fp16;

    assign in_ready = m0_in_ready & m1_in_ready & m2_in_ready & m3_in_ready;

	wire adder0_in_ready; // for mul 0 & 1
	wire adder1_in_ready; // for mul 2 & 3
	wire adder2_in_ready; // for adder 0 & 1

    fp16_int4_mul mul0 (
        .clk(clk), 
		.rst_n(rst_n),
        .in_valid(in_valid), 
		.in_ready(m0_in_ready),
        .in_fp16(in_fp16_0), 
		.in_int4(in_int4_0),
        .out_valid(m0_out_valid), 
		.out_ready(adder0_in_ready),
        .out_fp16(m0_out_fp16)
    );

    fp16_int4_mul mul1 (
        .clk(clk), 
		.rst_n(rst_n),
        .in_valid(in_valid), 
		.in_ready(m1_in_ready),
        .in_fp16(in_fp16_1), 
		.in_int4(in_int4_1),
        .out_valid(m1_out_valid), 
		.out_ready(adder0_in_ready),
        .out_fp16(m1_out_fp16)
    );

    fp16_int4_mul mul2 (
        .clk(clk), 
		.rst_n(rst_n),
        .in_valid(in_valid), 
		.in_ready(m2_in_ready),
        .in_fp16(in_fp16_2), 
		.in_int4(in_int4_2),
        .out_valid(m2_out_valid), 
		.out_ready(adder1_in_ready),
        .out_fp16(m2_out_fp16)
    );

    fp16_int4_mul mul3 (
        .clk(clk), 
		.rst_n(rst_n),
        .in_valid(in_valid), 
		.in_ready(m3_in_ready),
        .in_fp16(in_fp16_3), 
		.in_int4(in_int4_3),
        .out_valid(m3_out_valid), 
		.out_ready(adder1_in_ready),
        .out_fp16(m3_out_fp16)
    );

    // ------------------------------
    // Stage 1: First level adders
    // ------------------------------
    wire adder0_out_valid;
	wire adder1_out_valid;
	wire adder2_out_valid;
	wire adder3_out_valid;

    wire [15:0] s0_sum, s1_sum;

    fp16_adder add0 (
        .clk(clk), 
		.rst_n(rst_n),
        .in_valid(m0_out_valid & m1_out_valid),
        .in_ready(adder0_in_ready),
        .in_a(m0_out_fp16),
        .in_b(m1_out_fp16),
        .out_valid(adder0_out_valid),
        .out_ready(adder2_in_ready),
        .out_sum(s0_sum)
    );

    fp16_adder add1 (
        .clk(clk), 
		.rst_n(rst_n),
        .in_valid(m2_out_valid & m3_out_valid),
        .in_ready(adder1_in_ready),
        .in_a(m2_out_fp16),
        .in_b(m3_out_fp16),
        .out_valid(adder1_out_valid),
        .out_ready(adder2_in_ready),
        .out_sum(s1_sum)
    );

    // ------------------------------
    // Stage 2: Final adder
    // ------------------------------
    fp16_adder add_2 (
        .clk(clk), 
		.rst_n(rst_n),
        .in_valid(adder0_out_valid & adder1_out_valid),
        .in_ready(adder2_in_ready), // 不直接反馈到输入
        .in_a(s0_sum),
        .in_b(s1_sum),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_sum(out_fp16)
    );

endmodule
