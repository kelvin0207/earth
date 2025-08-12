`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/12 11:24:15
// Design Name: processing element
// Module Name: pe
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

// -----------------------------------------------------------------------------
// pe16.v
// Processing Element with 16 DPUs (dot-product units).
// - Each DPU takes 4 FP16 activations (shared across DPUs) and 4 INT4 weights.
// - Inputs:
//     in_fp16_0..3         : 4 shared FP16 activations
//     in_int4s [255:0]     : 16*4 INT4s concatenated as
//                            { dpu15.w3,dpu15.w2,dpu15.w1,dpu15.w0, ..., dpu0.w0 }
//     in_valid              : global input valid
// - Outputs:
//     in_ready              : 1 if *all* DPUs are ready to accept input
//     out_valid_vec [15:0]  : per-DPU out_valid
//     out_fp16s [255:0]     : per-DPU FP16 outputs concatenated as
//                            { dpu15.out, dpu14.out, ..., dpu0.out }
// - Also takes per-DPU out_ready vector for backpressure.
//
// Note: This file assumes a module named `dpu` (as you provided) is available.
// -----------------------------------------------------------------------------


module pe(
    input  wire         clk,
    input  wire         rst_n,

    // shared activations (4 FP16)
    input  wire [15:0]  in_fp16_0,
    input  wire [15:0]  in_fp16_1,
    input  wire [15:0]  in_fp16_2,
    input  wire [15:0]  in_fp16_3,

    // weights: 16 DPUs * 4 weights * 4 bits = 256 bits
    // layout: { dpu15.w3, dpu15.w2, dpu15.w1, dpu15.w0,
    //           dpu14.w3, ..., dpu0.w0 }
    input  wire [255:0] in_int4s,

    // global input handshake
    input  wire         in_valid,
    output wire         in_ready,

    // per-DPU output handshake and results
    output wire [15:0]  out_valid_vec,
    input  wire [15:0]  out_ready_vec,
    output wire [255:0] out_fp16s   // { dpu15.out(15:0), ..., dpu0.out(15:0) }
);

    // internal wires for each dpu
    wire [15:0] dpu_out_fp16  [0:15];
    wire        dpu_out_valid  [0:15];
    wire        dpu_in_ready   [0:15];

    // flatten mapping helpers (we will assemble out_fp16s and out_valid_vec later)
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_DPUS
            // extract the 4 weights for DPU i from in_int4s
            // index base: each DPU has 4 weights, each 4 bits.
            // DPU0 occupies bits [ (0*4+4)*4 -1 : 0 ] ? to keep mapping simple,
            // we defined layout as {dpu15.w3 ... dpu0.w0} (big-endian). So compute base accordingly.
            localparam integer dpui = i;
            // compute start bit for dpu i (w0 LSB of its block)
            // block_idx = (15 - i)  (because high bits are dpu15)
            localparam integer block_idx = 15 - dpui;
            // each block is 16 bits (4 weights * 4 bits)
            localparam integer block_start = block_idx * 16;

            wire [3:0] w0 = in_int4s[ block_start +  3 -: 4 ]; // w0 at lowest bits of block
            wire [3:0] w1 = in_int4s[ block_start +  7 -: 4 ];
            wire [3:0] w2 = in_int4s[ block_start + 11 -: 4 ];
            wire [3:0] w3 = in_int4s[ block_start + 15 -: 4 ];

            // instantiate dpu i
            dpu dpu_inst (
                .clk         (clk),
                .rst_n       (rst_n),
                .in_valid    (in_valid),
                .in_ready    (dpu_in_ready[i]),
                .in_fp16_0   (in_fp16_0),
                .in_fp16_1   (in_fp16_1),
                .in_fp16_2   (in_fp16_2),
                .in_fp16_3   (in_fp16_3),
                .in_int4_0   (w0),
                .in_int4_1   (w1),
                .in_int4_2   (w2),
                .in_int4_3   (w3),
                .out_valid   (dpu_out_valid[i]),
                .out_ready   (out_ready_vec[i]),
                .out_fp16    (dpu_out_fp16[i])
            );
        end
    endgenerate

    // in_ready is true only when all DPUs are ready (they share the same input data)
    wire all_ready;
    assign all_ready = &dpu_in_ready; // bitwise AND across 16 wires
    assign in_ready = all_ready;

    // Collect outputs into vectors / flat bus
    // out_valid_vec: simple mapping
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : GEN_OUTS
            assign out_valid_vec[k] = dpu_out_valid[k];
            // place each dpu's 16-bit out in the large flat vector
            // out_fp16s layout: { dpu15_out, dpu14_out, ..., dpu0_out }
            localparam integer out_block_idx = 15 - k;
            localparam integer out_start = out_block_idx * 16;
            assign out_fp16s[out_start +: 16] = dpu_out_fp16[k];
        end
    endgenerate

endmodule

/*
module pe16 (
    input  wire         clk,
    input  wire         rst_n,

    // shared activations (4 FP16)
    input  wire [15:0]  in_fp16_0,
    input  wire [15:0]  in_fp16_1,
    input  wire [15:0]  in_fp16_2,
    input  wire [15:0]  in_fp16_3,

    // weights: 16 DPUs * 4 weights * 4 bits = 256 bits
    // layout: { dpu15.w3, dpu15.w2, dpu15.w1, dpu15.w0,
    //           dpu14.w3, ..., dpu0.w0 }
    input  wire [255:0] in_int4s,

    // global input handshake
    input  wire         in_valid,
    output wire         in_ready,

    // per-DPU output handshake and results
    output wire [15:0]  out_valid_vec,
    input  wire         out_ready,
    output wire [255:0] out_fp16s   // { dpu15.out(15:0), ..., dpu0.out(15:0) }
);

    // internal wires for each dpu
	wire 		dpu0_in_ready;
	wire 		dpu1_in_ready;
	wire 		dpu2_in_ready;
	wire 		dpu3_in_ready;
	wire 		dpu4_in_ready;
	wire 		dpu5_in_ready;
	wire 		dpu6_in_ready;
	wire 		dpu7_in_ready;
	wire 		dpu8_in_ready;
	wire 		dpu9_in_ready;
	wire 		dpu10_in_ready;
	wire 		dpu11_in_ready;
	wire 		dpu12_in_ready;
	wire 		dpu13_in_ready;
	wire 		dpu14_in_ready;
	wire 		dpu15_in_ready;

	wire [15:0] in_ready_vec;

	assign in_ready_vec = {dpu15_in_ready, dpu14_in_ready, dpu13_in_ready, dpu12_in_ready,
							dpu11_in_ready, dpu10_in_ready, dpu9_in_ready, dpu8_in_ready,
							dpu7_in_ready, dpu6_in_ready, dpu5_in_ready, dpu4_in_ready,
							dpu3_in_ready, dpu2_in_ready, dpu1_in_ready, dpu0_in_ready};

	assign in_ready = &in_ready_vec;

    wire [15:0] dpu0_out_fp16;
    wire        dpu0_out_valid;

	wire [15:0] dpu1_out_fp16;
    wire        dpu1_out_valid;

	wire [15:0] dpu2_out_fp16;
    wire        dpu2_out_valid;

	wire [15:0] dpu3_out_fp16;
    wire        dpu3_out_valid;

	wire [15:0] dpu4_out_fp16;
    wire        dpu4_out_valid;

	wire [15:0] dpu5_out_fp16;
    wire        dpu5_out_valid;

	wire [15:0] dpu6_out_fp16;
    wire        dpu6_out_valid;

	wire [15:0] dpu7_out_fp16;
    wire        dpu7_out_valid;

	wire [15:0] dpu8_out_fp16;
    wire        dpu8_out_valid;

	wire [15:0] dpu9_out_fp16;
    wire        dpu9_out_valid;

	wire [15:0] dpu10_out_fp16;
    wire        dpu10_out_valid;

	wire [15:0] dpu11_out_fp16;
    wire        dpu11_out_valid;

	wire [15:0] dpu12_out_fp16;
    wire        dpu12_out_valid;

	wire [15:0] dpu13_out_fp16;
    wire        dpu13_out_valid;

	wire [15:0] dpu14_out_fp16;
    wire        dpu14_out_valid;

	wire [15:0] dpu15_out_fp16;
    wire        dpu15_out_valid;

	// 声明16个16位的wire
	wire [15:0] in_int4_dpu0;
	wire [15:0] in_int4_dpu1;
	wire [15:0] in_int4_dpu2;
	wire [15:0] in_int4_dpu3;
	wire [15:0] in_int4_dpu4;
	wire [15:0] in_int4_dpu5;
	wire [15:0] in_int4_dpu6;
	wire [15:0] in_int4_dpu7;
	wire [15:0] in_int4_dpu8;
	wire [15:0] in_int4_dpu9;
	wire [15:0] in_int4_dpu10;
	wire [15:0] in_int4_dpu11;
	wire [15:0] in_int4_dpu12;
	wire [15:0] in_int4_dpu13;
	wire [15:0] in_int4_dpu14;
	wire [15:0] in_int4_dpu15;

	// 分配256位输入信号的相应位段到各个16位信号
	assign in_int4_dpu0  = in_int4s[15:0];
	assign in_int4_dpu1  = in_int4s[31:16];
	assign in_int4_dpu2  = in_int4s[47:32];
	assign in_int4_dpu3  = in_int4s[63:48];
	assign in_int4_dpu4  = in_int4s[79:64];
	assign in_int4_dpu5  = in_int4s[95:80];
	assign in_int4_dpu6  = in_int4s[111:96];
	assign in_int4_dpu7  = in_int4s[127:112];
	assign in_int4_dpu8  = in_int4s[143:128];
	assign in_int4_dpu9  = in_int4s[159:144];
	assign in_int4_dpu10 = in_int4s[175:160];
	assign in_int4_dpu11 = in_int4s[191:176];
	assign in_int4_dpu12 = in_int4s[207:192];
	assign in_int4_dpu13 = in_int4s[223:208];
	assign in_int4_dpu14 = in_int4s[239:224];
	assign in_int4_dpu15 = in_int4s[255:240];


	dpu dpu0 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu0_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu0[3:0]),
		.in_int4_1   (in_int4_dpu0[7:4]),
		.in_int4_2   (in_int4_dpu0[11:8]),
		.in_int4_3   (in_int4_dpu0[15:12]),
		.out_valid   (dpu0_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu0_out_fp16)
	);

   // 实例化dpu1
	dpu dpu1 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu1_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu1[3:0]),
		.in_int4_1   (in_int4_dpu1[7:4]),
		.in_int4_2   (in_int4_dpu1[11:8]),
		.in_int4_3   (in_int4_dpu1[15:12]),
		.out_valid   (dpu1_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu1_out_fp16)
	);

	// 实例化dpu2
	dpu dpu2 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu2_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu2[3:0]),
		.in_int4_1   (in_int4_dpu2[7:4]),
		.in_int4_2   (in_int4_dpu2[11:8]),
		.in_int4_3   (in_int4_dpu2[15:12]),
		.out_valid   (dpu2_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu2_out_fp16)
	);

	// 实例化dpu3
	dpu dpu3 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu3_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu3[3:0]),
		.in_int4_1   (in_int4_dpu3[7:4]),
		.in_int4_2   (in_int4_dpu3[11:8]),
		.in_int4_3   (in_int4_dpu3[15:12]),
		.out_valid   (dpu3_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu3_out_fp16)
	);

	// 实例化dpu4
	dpu dpu4 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu4_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu4[3:0]),
		.in_int4_1   (in_int4_dpu4[7:4]),
		.in_int4_2   (in_int4_dpu4[11:8]),
		.in_int4_3   (in_int4_dpu4[15:12]),
		.out_valid   (dpu4_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu4_out_fp16)
	);

	// 实例化dpu5
	dpu dpu5 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu5_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu5[3:0]),
		.in_int4_1   (in_int4_dpu5[7:4]),
		.in_int4_2   (in_int4_dpu5[11:8]),
		.in_int4_3   (in_int4_dpu5[15:12]),
		.out_valid   (dpu5_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu5_out_fp16)
	);

	// 实例化dpu6
	dpu dpu6 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu6_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu6[3:0]),
		.in_int4_1   (in_int4_dpu6[7:4]),
		.in_int4_2   (in_int4_dpu6[11:8]),
		.in_int4_3   (in_int4_dpu6[15:12]),
		.out_valid   (dpu6_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu6_out_fp16)
	);

	// 实例化dpu7
	dpu dpu7 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu7_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu7[3:0]),
		.in_int4_1   (in_int4_dpu7[7:4]),
		.in_int4_2   (in_int4_dpu7[11:8]),
		.in_int4_3   (in_int4_dpu7[15:12]),
		.out_valid   (dpu7_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu7_out_fp16)
	);

	// 实例化dpu8
	dpu dpu8 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu8_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu8[3:0]),
		.in_int4_1   (in_int4_dpu8[7:4]),
		.in_int4_2   (in_int4_dpu8[11:8]),
		.in_int4_3   (in_int4_dpu8[15:12]),
		.out_valid   (dpu8_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu8_out_fp16)
	);

	// 实例化dpu9
	dpu dpu9 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu9_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu9[3:0]),
		.in_int4_1   (in_int4_dpu9[7:4]),
		.in_int4_2   (in_int4_dpu9[11:8]),
		.in_int4_3   (in_int4_dpu9[15:12]),
		.out_valid   (dpu9_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu9_out_fp16)
	);

	// 实例化dpu10
	dpu dpu10 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu10_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu10[3:0]),
		.in_int4_1   (in_int4_dpu10[7:4]),
		.in_int4_2   (in_int4_dpu10[11:8]),
		.in_int4_3   (in_int4_dpu10[15:12]),
		.out_valid   (dpu10_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu10_out_fp16)
	);

	// 实例化dpu11
	dpu dpu11 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu11_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu11[3:0]),
		.in_int4_1   (in_int4_dpu11[7:4]),
		.in_int4_2   (in_int4_dpu11[11:8]),
		.in_int4_3   (in_int4_dpu11[15:12]),
		.out_valid   (dpu11_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu11_out_fp16)
	);

	// 实例化dpu12
	dpu dpu12 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu12_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu12[3:0]),
		.in_int4_1   (in_int4_dpu12[7:4]),
		.in_int4_2   (in_int4_dpu12[11:8]),
		.in_int4_3   (in_int4_dpu12[15:12]),
		.out_valid   (dpu12_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu12_out_fp16)
	);

	// 实例化dpu13
	dpu dpu13 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu13_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu13[3:0]),
		.in_int4_1   (in_int4_dpu13[7:4]),
		.in_int4_2   (in_int4_dpu13[11:8]),
		.in_int4_3   (in_int4_dpu13[15:12]),
		.out_valid   (dpu13_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu13_out_fp16)
	);

	// 实例化dpu14
	dpu dpu14 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu14_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu14[3:0]),
		.in_int4_1   (in_int4_dpu14[7:4]),
		.in_int4_2   (in_int4_dpu14[11:8]),
		.in_int4_3   (in_int4_dpu14[15:12]),
		.out_valid   (dpu14_out_valid),
		.out_			ready   (out_ready),
		.out_fp16    (dpu14_out_fp16)
	);

	// 实例化dpu15
	dpu dpu15 (
		.clk         (clk),
		.rst_n       (rst_n),
		.in_valid    (in_valid),
		.in_ready    (dpu15_in_ready),
		.in_fp16_0   (in_fp16_0),
		.in_fp16_1   (in_fp16_1),
		.in_fp16_2   (in_fp16_2),
		.in_fp16_3   (in_fp16_3),
		.in_int4_0   (in_int4_dpu15[3:0]),
		.in_int4_1   (in_int4_dpu15[7:4]),
		.in_int4_2   (in_int4_dpu15[11:8]),
		.in_int4_3   (in_int4_dpu15[15:12]),
		.out_valid   (dpu15_out_valid),
		.out_ready   (out_ready),
		.out_fp16    (dpu15_out_fp16)
	);

	assign out_valid_vec = {dpu15_out_valid, dpu14_out_valid, dpu13_out_valid, dpu12_out_valid,
							dpu11_out_valid, dpu10_out_valid, dpu9_out_valid, dpu8_out_valid,
							dpu7_out_valid, dpu6_out_valid, dpu5_out_valid, dpu4_out_valid,
							dpu3_out_valid, dpu2_out_valid, dpu1_out_valid, dpu0_out_valid};
	
	assign out_fp16s = {dpu15_out_fp16, dpu14_out_fp16, dpu13_out_fp16, dpu12_out_fp16,
							dpu11_out_fp16, dpu10_out_fp16, dpu9_out_fp16, dpu8_out_fp16,
							dpu7_out_fp16, dpu6_out_fp16, dpu5_out_fp16, dpu4_out_fp16,
							dpu3_out_fp16, dpu2_out_fp16, dpu1_out_fp16, dpu0_out_fp16};

endmodule
*/
