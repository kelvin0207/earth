`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 16:57:51
// Design Name: 
// Module Name: fp16_acc
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


module fp16_acc(
    input  wire      	clk,
    input  wire      	rst_n,
    input  wire [15:0] 	in_a,
	input  wire 		in_accum_done,
    output reg  [15:0] 	out_sum
);

	// local buffer for psum (没有规格化)
    reg			b_sign;
	reg	[4:0]	b_exp;
	reg [12:0]	b_mant;

	// input reg
	always@(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			b_sign	<= 0;
			b_exp	<= 0;
			b_mant	<= 0;
		end
		// 计算完毕之后local buffer数据清零
		else if (in_accum_done) begin
			b_sign	<= 0;
			b_exp	<= 0;
			b_mant	<= 0;
		end
		else begin
			b_sign	<= ;
			b_exp	<= ;
			b_mant	<= ;
		end
	end

	wire 		in_sign;
	wire [4:0]	in_exp;
	wire [10:0]	in_mant;

	assign a_sign = in_a[15];
	assign a_exp = in_a[14:10];
	assign a_mant = {1'b1, in_a[9:0]};

    // align exp 
    // 指数对齐（减小指数的尾数右移）
    wire [4:0] s0_exp_diff;
    wire       s0_a_lgt_b; // a>b
    wire       s0_a_lst_b; // a<b
    
    assign s0_a_lgt_b = (s0_exp_a > s0_exp_b);
    assign s0_a_lst_b = (s0_exp_a < s0_exp_b);
    assign s0_exp_diff = s0_a_lgt_b ? (s0_exp_a - s0_exp_b) : (s0_exp_b - s0_exp_a);

    reg  [10:0] s0_mant_a_shifted;
    reg  [10:0] s0_mant_b_shifted;
    reg  [4:0]  s0_exp_large;
    reg         s0_sign_large;

    always @(*) begin
        if (s0_a_lgt_b) begin // a > b
            s0_exp_large       = s0_exp_a;
            s0_sign_large      = s0_sign_a;
            s0_mant_a_shifted  = s0_mant_a;
            s0_mant_b_shifted  = s0_mant_b >> s0_exp_diff;
        end
        else if (s0_a_lst_b) begin // a < b
            s0_exp_large       = s0_exp_b;
            s0_sign_large      = s0_sign_b;
            s0_mant_a_shifted  = s0_mant_a >> s0_exp_diff;
            s0_mant_b_shifted  = s0_mant_b;
        end 
        else begin // a(exp) == b(exp)
            s0_exp_large       = s0_exp_a;  // equal exponent
            s0_sign_large      = s0_sign_a; // if equal, prefer a's sign
            s0_mant_a_shifted  = s0_mant_a;
            s0_mant_b_shifted  = s0_mant_b;
        end
    end
    
	



endmodule
