`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/11 13:48:43
// Design Name: 
// Module Name: fp_add
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

module fp16_adder (
    input   wire        clk,
    input   wire        rst_n,

    // Input side
    input   wire        in_valid,
    output  wire        in_ready,
    input   wire [15:0] in_a,
    input   wire [15:0] in_b,

    // Output side
    output reg          out_valid,
    input  wire         out_ready,
    output reg   [15:0] out_sum
);

    // ----------------------------
    // Stage valid/ready signals
    // ----------------------------
    reg s0_valid;
    reg s1_valid;

    wire s0_ready;
    wire s1_ready;

    // ready propagation (typical pipeline backpressure)
    // ready backpropagation, valid forward propagation
    assign s1_ready = !s1_valid || (out_ready && out_valid);
    assign s0_ready = !s0_valid || s1_ready;
    assign in_ready = s0_ready;
    // if S1 has no new data (!s1_valid), s1 is ready for new data
    // if S1 has new data and the next stage is ready for new data
    //    s1 is ready for new data

    // ----------------------------
    // Stage0 registers (unpack)
    // ----------------------------
    // unpacked fields for stage0 -> stage1
    reg        s0_sign_a;
    reg [4:0]  s0_exp_a;
    reg [9:0]  s0_frac_a;

    reg        s0_sign_b;
    reg [4:0]  s0_exp_b;
    reg [9:0]  s0_frac_b;

    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            s0_valid        <= 0;

            s0_sign_a       <= 0;
            s0_exp_a        <= 0;
            s0_frac_a       <= 0;

            s0_sign_b       <= 0;
            s0_exp_b        <= 0;
            s0_frac_b       <= 0;
        end

        else if(in_valid & s0_ready) begin
            s0_valid        <= 1;

            s0_sign_a       <= in_a[15];
            s0_exp_a        <= in_a[14:10];
            s0_frac_a       <= in_a[9:0];

            s0_sign_b       <= in_b[15];
            s0_exp_b        <= in_b[14:10];
            s0_frac_b       <= in_b[9:0];
        end

        else if (s1_ready & s0_valid) begin
            s0_valid        <= 0; 
        end
    end

    // normalize mant. 
    // 归一化尾数，隐藏位1（除非指数全0表示非规格化数）
    wire [10:0] s0_mant_a;
    wire [10:0] s0_mant_b;

    assign s0_mant_a = {1'b1, s0_frac_a};
    assign s0_mant_b = {1'b1, s0_frac_b};

    // align exp 
    // 指数对齐（减小指数的尾数右移）
    wire [4:0] s0_exp_diff;
    wire       s0_a_lgt_b; // a>b
    wire       s0_a_lst_b; // a<b
    
    assign s0_a_lgt_b = (s0_exp_a > s0_exp_b)
    assign s0_a_lst_b = (s0_exp_a < s0_exp_b)
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
    
    // ----------------------------
    // Stage1 registers 
    // ----------------------------
    reg         s1_valid;
    reg         s1_sign_a;
    reg         s1_sign_b;
    reg  [10:0] s1_mant_a_shifted;
    reg  [10:0] s1_mant_b_shifted;
    reg  [4:0]  s1_exp_large;

    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            // here
            
    // 尾数加减，考虑符号
    reg [11:0] s0_man_sum;

    always @(*) begin
        if (s0_sign_a ^ s0_sign_b) begin
            s0_mant_sum = {1'b0, s0_mant_a_shifted} - {1'b0, s0_mant_b_shifted};
        end 
        else begin
            s0_mant_sum = {1'b0, s0_mant_a_shifted} + {1'b0, s0_mant_b_shifted};
        end
    end

    // 结果符号
    wire sign_res = (man_sum_signed < 0) ? ~sign_large : sign_large;

    // 绝对值尾数和归一化
    wire [11:0] man_sum_abs = (man_sum_signed < 0) ? -man_sum_signed : man_sum_signed;

    // 规格化移位 (左移，直到最高位为1)
    reg [4:0] exp_res;
    reg [10:0] frac_res;
    integer shift_count;

    always @(*) begin
        if (man_sum_abs == 0) begin
            // 结果为零
            exp_res  = 0;
            frac_res = 0;
        end else begin
            // 先假设最高位在 bit 11（12位宽）
            shift_count = 0;
            // 左移直到第11位为1（最高有效位）
            while (man_sum_abs[11] == 0 && shift_count < 12) begin
                man_sum_abs = man_sum_abs << 1;
                shift_count = shift_count + 1;
            end
            exp_res  = exp_large - shift_count;
            frac_res = man_sum_abs[10:0] >> 1; // 最高位是隐藏位，不存储，截取后面10位尾数
        end
    end

    // 组装输出
    always @(*) begin
        if (man_sum_abs == 0) begin
            sum = 16'b0; // +0
        end else begin
            sum = {sign_res, exp_res, frac_res[9:0]};
        end
    end

endmodule
