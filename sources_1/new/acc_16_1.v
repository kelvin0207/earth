`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/15 13:25:44
// Design Name: accumulate 16 psum to 1
// Module Name: acc_16_1
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

// -----------------------------------------------------------------------------
// 16-to-1 FP16 Adder Tree with ready/valid handshake
// - 4 stages: 16->8->4->2->1
// - Each node is an fp16_adder (station-in/out: in_valid/in_ready, out_valid/out_ready)
// - Join logic between stages guarantees that a parent consumes both children
//   outputs in the same cycle when parent is ready.
// -----------------------------------------------------------------------------
module acc_16_1 (
    input  wire         clk,
    input  wire         rst_n,

    // Input vector: 16 FP16 numbers packed as {x15, x14, ..., x0}
    input  wire         in_valid,
    output wire         in_ready,
    input  wire [16*16-1:0] in_vec,

    // Output
    output wire         out_valid,
    input  wire         out_ready,
    output wire [15:0]  out_sum
);
    // -------------------------
    // Stage 0: 16 -> 8 adders
    // -------------------------
    // Operands extraction
	wire [15:0]	s0_op0;
	wire [15:0]	s0_op1;
	wire [15:0]	s0_op2;
	wire [15:0]	s0_op3;
	wire [15:0]	s0_op4;
	wire [15:0]	s0_op5;
	wire [15:0]	s0_op6;
	wire [15:0]	s0_op7;
	wire [15:0]	s0_op8;
	wire [15:0]	s0_op9;
	wire [15:0]	s0_op10;
	wire [15:0]	s0_op11;
	wire [15:0]	s0_op12;
	wire [15:0]	s0_op13;
	wire [15:0]	s0_op14;
	wire [15:0]	s0_op15;

	assign s0_op0 = in_vec[(0*16) +: 16];
	assign s0_op1 = in_vec[(1*16) +: 16];
	assign s0_op2 = in_vec[(2*16) +: 16];
	assign s0_op3 = in_vec[(3*16) +: 16];
	assign s0_op4 = in_vec[(4*16) +: 16];
	assign s0_op5 = in_vec[(5*16) +: 16];
	assign s0_op6 = in_vec[(6*16) +: 16];
	assign s0_op7 = in_vec[(7*16) +: 16];
	assign s0_op8 = in_vec[(8*16) +: 16];
	assign s0_op9 = in_vec[(9*16) +: 16];
	assign s0_op10 = in_vec[(10*16) +: 16];
	assign s0_op11 = in_vec[(11*16) +: 16];
	assign s0_op12 = in_vec[(12*16) +: 16];
	assign s0_op13 = in_vec[(13*16) +: 16];
	assign s0_op14 = in_vec[(14*16) +: 16];
	assign s0_op15 = in_vec[(15*16) +: 16];


    // 8 adders at stage 0
    wire [7:0]  s0_in_ready;
    wire [7:0]  s0_out_valid;

    wire [15:0] s0_out_sum0;
    wire [15:0] s0_out_sum1;
    wire [15:0] s0_out_sum2;
    wire [15:0] s0_out_sum3;
    wire [15:0] s0_out_sum4;
    wire [15:0] s0_out_sum5;
    wire [15:0] s0_out_sum6;
    wire [15:0] s0_out_sum7;

    // out_ready for s0 adders is driven by stage1 join logic (declared later)
    wire [7:0]  s0_out_ready[0:7];

	fp16_adder adder0_0(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (in_valid),
		.in_ready  (s0_in_ready[0]),
		.in_a      (s0_op0),
		.in_b      (s0_op1),
		.out_valid (s0_out_valid[0]),
		.out_ready (s1_in_ready[0]),
		.out_sum   (s0_out_sum0)
	);

	fp16_adder adder0_1(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (in_valid),
		.in_ready  (s0_in_ready[1]),
		.in_a      (s0_op2),
		.in_b      (s0_op3),
		.out_valid (s0_out_valid[1]),
		.out_ready (s1_in_ready[0]),
		.out_sum   (s0_out_sum1)
	);

	fp16_adder adder0_2(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (in_valid),
		.in_ready  (s0_in_ready[2]),
		.in_a      (s0_op4),
		.in_b      (s0_op5),
		.out_valid (s0_out_valid[2]),
		.out_ready (),
		.out_sum   (s0_out_sum2)
	);

	fp16_adder adder0_3(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (in_valid),
		.in_ready  (s0_in_ready[3]),
		.in_a      (s0_op6),
		.in_b      (s0_op7),
		.out_valid (s0_out_valid[3]),
		.out_ready (),
		.out_sum   (s0_out_sum3)
	);
	
  	fp16_adder adder0_4(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (in_valid),
		.in_ready  (s0_in_ready[4]),
		.in_a      (s0_op8),
		.in_b      (s0_op9),
		.out_valid (s0_out_valid[4]),
		.out_ready (),
		.out_sum   (s0_out_sum4)
	);

	fp16_adder adder0_5(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (in_valid),
		.in_ready  (s0_in_ready[5]),
		.in_a      (s0_op10),
		.in_b      (s0_op11),
		.out_valid (s0_out_valid[5]),
		.out_ready (),
		.out_sum   (s0_out_sum5)
	);

	fp16_adder adder0_6(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (in_valid),
		.in_ready  (s0_in_ready[6]),
		.in_a      (s0_op12),
		.in_b      (s0_op13),
		.out_valid (s0_out_valid[6]),
		.out_ready (),
		.out_sum   (s0_out_sum6)
	);

	fp16_adder adder0_7(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (in_valid),
		.in_ready  (s0_in_ready[7]),
		.in_a      (s0_op14),
		.in_b      (s0_op15),
		.out_valid (s0_out_valid[7]),
		.out_ready (),
		.out_sum   (s0_out_sum7)
	);

    // Input ready when ALL stage0 adders are ready (they share the same accept beat)
    assign in_ready = &s0_in_ready;

    // -------------------------
    // Stage 1: 8 -> 4 adders
    // -------------------------
    // Join: pair (0,1)->0 ; (2,3)->1 ; (4,5)->2 ; (6,7)->3
    wire [3:0]  s1_out_valid;
    wire [3:0]  s1_in_ready;

	wire [15:0] s1_out_sum0;
	wire [15:0] s1_out_sum1;
	wire [15:0] s1_out_sum2;
	wire [15:0] s1_out_sum3;

	fp16_adder adder1_0(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (s0_out_valid[0] & s0_out_valid[1]),
		.in_ready  (s1_in_ready[0]),
		.in_a      (s0_out_sum0),
		.in_b      (s0_out_sum1),
		.out_valid (s1_out_valid[0]),
		.out_ready (s2_in_ready[0]),
		.out_sum   (s1_out_sum0)
	);

	fp16_adder adder1_1(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (s0_out_valid[2] & s0_out_valid[3]),
		.in_ready  (s1_in_ready[1]),
		.in_a      (s0_out_sum2),
		.in_b      (s0_out_sum3),
		.out_valid (s1_out_valid[1]),
		.out_ready (s2_in_ready[0]),
		.out_sum   (s1_out_sum1)
	);

	fp16_adder adder1_2(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (s0_out_valid[4] & s0_out_valid[5]),
		.in_ready  (s1_in_ready[2]),
		.in_a      (s0_out_sum4),
		.in_b      (s0_out_sum5),
		.out_valid (s1_out_valid[2]),
		.out_ready (s2_in_ready[1]),
		.out_sum   (s1_out_sum2)
	);

	fp16_adder adder1_3(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (s0_out_valid[6] & s0_out_valid[7]),
		.in_ready  (s1_in_ready[3]),
		.in_a      (s0_out_sum6),
		.in_b      (s0_out_sum7),
		.out_valid (s1_out_valid[3]),
		.out_ready (s2_in_ready[1]),
		.out_sum   (s1_out_sum3)
	);

    // -------------------------
    // Stage 2: 4 -> 2 adders
    // -------------------------
    // Join: pair (0,1)->0 ; (2,3)->1

	wire [1:0]  s2_out_valid;
    wire [1:0]  s2_in_ready;

	wire [15:0] s2_out_sum0;
	wire [15:0] s2_out_sum1;

	fp16_adder adder2_0(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (s1_out_valid[0] & s1_out_valid[1]),
		.in_ready  (s2_in_ready[0]),
		.in_a      (s1_out_sum0),
		.in_b      (s1_out_sum1),
		.out_valid (s2_out_valid[0]),
		.out_ready (s3_in_ready),
		.out_sum   (s2_out_sum0)
	);

	fp16_adder adder2_1(
		.clk       (clk),
		.rst_n     (rst_n),
		// both operands consumed together under in_valid & in_ready
		.in_valid  (s1_out_valid[2] & s1_out_valid[3]),
		.in_ready  (s2_in_ready[1]),
		.in_a      (s1_out_sum2),
		.in_b      (s1_out_sum3),
		.out_valid (s2_out_valid[1]),
		.out_ready (s3_in_ready),
		.out_sum   (s2_out_sum1)
	);

    // -------------------------
    // Stage 3: 2 -> 1 adder (root)
    // -------------------------
    wire        s3_in_valid;
    wire        s3_in_ready;
    wire [15:0] s3_in_a;
    wire [15:0] s3_in_b;

    // Root adder
    fp16_adder add3_root (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (s2_out_valid[0] & s2_out_valid[1]),
        .in_ready  (s3_in_ready),
        .in_a      (s2_out_sum0),
        .in_b      (s2_out_sum1),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .out_sum   (out_sum)
    );

endmodule
