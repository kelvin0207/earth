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
    // input side
    input  wire [15:0] 	in_a,
	input  wire 		in_accum_done,
    // output side
    output wire [15:0] 	out_sum,
    output reg          out_valid
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
			b_sign	<= sign_large_cmp;
			b_exp	<= exp_large;
			b_mant	<= mant_sum_abs;
		end
	end

	wire 		a_sign;
	wire [4:0]	a_exp;
	wire [10:0]	a_mant;

	assign a_sign = in_a[15];
	assign a_exp = in_a[14:10];
	assign a_mant = {1'b1, in_a[9:0]};

    // align exp 
    // 指数对齐（减小指数的尾数右移）
    wire [4:0] exp_diff;
    wire       a_lgt_b; // a>b
    wire       a_lst_b; // a<b
    
    assign a_lgt_b = (a_exp > b_exp);
    assign a_lst_b = (a_exp < b_exp);
    assign exp_diff = a_lgt_b ? (a_exp - b_exp) : (b_exp - a_exp);

    reg  [10:0] a_mant_shifted;
    reg  [10:0] b_mant_shifted;
    reg  [4:0]  exp_large;
    reg         sign_large;

    always @(*) begin
        if (a_lgt_b) begin // a > b
            exp_large       = a_exp;
            sign_large      = a_sign;
            a_mant_shifted  = a_mant;
            b_mant_shifted  = b_mant >> exp_diff;
        end
        else if (a_lst_b) begin // a < b
            exp_large       = a_exp;
            sign_large      = a_sign;
            a_mant_shifted  = a_mant >> exp_diff;
            b_mant_shifted  = b_mant;
        end 
        else begin // a(exp) == b(exp)
            exp_large       = b_exp; // equal exponent
            sign_large      = b_sign; // if equal, prefer b's sign
            a_mant_shifted  = a_mant;
            b_mant_shifted  = b_mant;
        end
    end
    
	// 尾数加减，考虑符号
    reg [12:0]  mant_sum;

    wire        sign_large_cmp;
    wire [12:0] mant_sum_abs;

    always @(*) begin
        if (a_sign ^ b_sign) begin // a b different sign, sub
            mant_sum = {2'b0, a_mant_shifted} - {2'b0, b_mant_shifted};
        end 
        else begin // a b same sign, add
            mant_sum = {2'b0, a_mant_shifted} + {2'b0, b_mant_shifted};
        end
    end

    // 结果符号
    assign sign_large_cmp = mant_sum[12]? ~sign_large : sign_large;
    // 绝对值尾数
    assign mant_sum_abs = mant_sum[12]? (~mant_sum+1) : mant_sum;
    
    // stage 1: norm and output
    reg         out_sign_large;
    reg [5:0]   out_exp_large;
    reg [12:0]  out_mant_sum;
 
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            out_sign_large  <= 0;
            out_exp_large   <= 0;
            out_mant_sum    <= 0;
            out_valid       <= 0;
        end
        else if(in_accum_done) begin
            out_sign_large  <= sign_large_cmp;
            out_exp_large   <= exp_large;
            out_mant_sum    <= mant_sum_abs;
            out_valid       <= 1;
        end
    end

    // 规格化移位 (左移，直到最高位为1)
    reg [4:0]  out_exp_res;
    reg [9:0]  out_frac_res;

    always@(*) begin
        casex(out_mant_sum[11:0])
            12'b1xxx_xxxx_xxxx: begin
                out_exp_res = out_exp_large + 1;
                out_frac_res = out_mant_sum[10:1];
            end
            12'b01xx_xxxx_xxxx: begin
                out_exp_res = out_exp_large;
                out_frac_res = out_mant_sum[9:0];
            end
            12'b001x_xxxx_xxxx:begin
                out_exp_res = out_exp_large - 1;
                out_frac_res = {out_mant_sum[8:0], 1'b0};
            end
            12'b0001_xxxx_xxxx:begin
                out_exp_res = out_exp_large - 2;
                out_frac_res = {out_mant_sum[7:0], 2'b0};
            end
            12'b0000_1xxx_xxxx:begin
                out_exp_res = out_exp_large - 3;
                out_frac_res = {out_mant_sum[6:0], 3'b0};
            end
            12'b0000_01xx_xxxx:begin
                out_exp_res = out_exp_large - 4;
                out_frac_res = {out_mant_sum[5:0], 4'b0};
            end
            12'b0000_001x_xxxx:begin
                out_exp_res = out_exp_large - 5;
                out_frac_res = {out_mant_sum[4:0], 5'b0};
            end
            12'b0000_0001_xxxx:begin
                out_exp_res = out_exp_large - 6;
                out_frac_res = {out_mant_sum[3:0], 6'b0};
            end
            12'b0000_0000_1xxx:begin
                out_exp_res = out_exp_large - 7;
                out_frac_res = {out_mant_sum[2:0], 7'b0};
            end
            12'b0000_0000_01xx:begin
                out_exp_res = out_exp_large - 8;
                out_frac_res = {out_mant_sum[1:0], 8'b0};
            end
            12'b0000_0000_001x:begin
                out_exp_res = out_exp_large - 9;
                out_frac_res = {out_mant_sum[0], 9'b0};
            end
            12'b0000_0000_0001:begin
                out_exp_res = out_exp_large - 10;
                out_frac_res = 10'b0;
            end
            default: begin
                out_exp_res = 0;
                out_frac_res = 0;
            end
        endcase
    end

    assign out_sum = {out_sign_large, out_exp_res, out_frac_res};

endmodule
