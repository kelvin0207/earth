`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/16 16:04:42
// Design Name: accumulate by temoral
// Module Name: acc_temporal
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


module acc_temporal(
    input   wire            clk,
    input   wire            rst_n,
    // input side
    input   wire            in_valid,
    input   wire [255:0]    in_vector,
    input   wire            in_accum_done,
    // output side
    output  reg             out_valid,
    output  reg  [255:0]    out_vector
    );

    // 拆分结果，分别进行时序累加
	wire [15:0]	in_0;
	wire [15:0]	in_1;
	wire [15:0]	in_2;
	wire [15:0]	in_3;
	wire [15:0]	in_4;
	wire [15:0]	in_5;
	wire [15:0]	in_6;
	wire [15:0]	in_7;
	wire [15:0]	in_8;
	wire [15:0]	in_9;
	wire [15:0]	in_10;
	wire [15:0]	in_11;
	wire [15:0]	in_12;
	wire [15:0]	in_13;
	wire [15:0]	in_14;
	wire [15:0]	in_15;
	
	assign in_0  = in_vector[0 *16 +: 16];
	assign in_1  = in_vector[1 *16 +: 16];
	assign in_2  = in_vector[2 *16 +: 16];
	assign in_3  = in_vector[3 *16 +: 16];
	assign in_4  = in_vector[4 *16 +: 16];
	assign in_5  = in_vector[5 *16 +: 16];
	assign in_6  = in_vector[6 *16 +: 16];
	assign in_7  = in_vector[7 *16 +: 16];
	assign in_8  = in_vector[8 *16 +: 16];
	assign in_9  = in_vector[9 *16 +: 16];
	assign in_10 = in_vector[10*16 +: 16];
	assign in_11 = in_vector[11*16 +: 16];
	assign in_12 = in_vector[12*16 +: 16];
	assign in_13 = in_vector[13*16 +: 16];
	assign in_14 = in_vector[14*16 +: 16];
	assign in_15 = in_vector[15*16 +: 16];

	wire [15:0]	out_0;
	wire [15:0]	out_1;
	wire [15:0]	out_2;
	wire [15:0]	out_3;
	wire [15:0]	out_4;
	wire [15:0]	out_5;
	wire [15:0]	out_6;
	wire [15:0]	out_7;
	wire [15:0]	out_8;
	wire [15:0]	out_9;
	wire [15:0]	out_10;
	wire [15:0]	out_11;
	wire [15:0]	out_12;
	wire [15:0]	out_13;
	wire [15:0]	out_14;
	wire [15:0]	out_15;

    wire [15:0] out_valid_vec;

	// 累加模块实例化
	fp16_acc acc0(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_0),
	    .in_accum_done  (in_accum_done),
        .out_sum        (out_0),
        .out_valid      (out_valid_vec[0])
    );

    fp16_acc acc1(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_1),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_1),
        .out_valid      (out_valid_vec[1])
    );

    fp16_acc acc2(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_2),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_2),
        .out_valid      (out_valid_vec[2])
    );

    fp16_acc acc3(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_3),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_3),
        .out_valid      (out_valid_vec[3])
    );

    fp16_acc acc4(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_4),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_4),
        .out_valid      (out_valid_vec[4])
    );

    fp16_acc acc5(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_5),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_5),
        .out_valid      (out_valid_vec[5])
    );

    fp16_acc acc6(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_6),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_6),
        .out_valid      (out_valid_vec[6])
    );

    fp16_acc acc7(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_7),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_7),
        .out_valid      (out_valid_vec[7])
    );

    fp16_acc acc8(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_8),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_8),
        .out_valid      (out_valid_vec[8])
    );

    fp16_acc acc9(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_9),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_9),
        .out_valid      (out_valid_vec[9])
    );

    fp16_acc acc10(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_10),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_10),
        .out_valid      (out_valid_vec[10])
    );

    fp16_acc acc11(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_11),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_11),
        .out_valid      (out_valid_vec[11])
    );

    fp16_acc acc12(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_12),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_12),
        .out_valid      (out_valid_vec[12])
    );

    fp16_acc acc13(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_13),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_13),
        .out_valid      (out_valid_vec[13])
    );

    fp16_acc acc14(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_14),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_14),
        .out_valid      (out_valid_vec[14])
    );

    fp16_acc acc15(
        .clk            (clk),
        .rst_n          (rst_n),
        .in_a           (in_15),
        .in_accum_done  (in_accum_done),
        .out_sum        (out_15),
        .out_valid      (out_valid_vec[15])
    );

    always@(posedge clk or negedge rst_n) begin
        if (rst_n) begin
            out_valid   <= 0;
            out_vector  <= 0;
        end
        else begin
            out_valid   <= &out_valid_vec;
            out_vector  <= {out_15, out_14, out_15, out_12,
                            out_11, out_10, out_9 , out_8 ,
                            out_7 , out_6 , out_5 , out_4 ,
                            out_3 , out_2 , out_1 , out_0 };
        end
    end
    
endmodule
