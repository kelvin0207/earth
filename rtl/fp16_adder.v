`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/11 13:48:43
// Design Name: 
// Module Name: fp_adder
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
    
    // 尾数加减，考虑符号
    reg [12:0] s0_mant_sum;

    always @(*) begin
        if (s0_sign_a ^ s0_sign_b) begin // a b different sign, sub
            s0_mant_sum = {2'b0, s0_mant_a_shifted} - {2'b0, s0_mant_b_shifted};
        end 
        else begin // a b same sign, add
            s0_mant_sum = {2'b0, s0_mant_a_shifted} + {2'b0, s0_mant_b_shifted};
        end
    end

    // ----------------------------
    // Stage1 registers 
    // ----------------------------
    reg         s1_sign_large;
    reg [4:0]   s1_exp_large;
    reg [12:0]  s1_mant_sum;


    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            s1_valid            <= 0;
            s1_sign_large       <= 0;
            s1_exp_large        <= 0;
            s1_mant_sum         <= 0;
        end
        else if (s0_valid && s1_ready) begin
            s1_valid            <= 1;
            s1_sign_large       <= s0_sign_large;
            s1_exp_large        <= s0_exp_large;
            s1_mant_sum         <= s0_mant_sum;
        end
        else if (out_ready && s1_valid) begin
            s1_valid <= 0; // data moved forward
        end
    end

    wire        s1_sign_res;
    wire [12:0] s1_mant_sum_abs;

    // 结果符号
    assign s1_sign_res = s1_mant_sum[12]? ~s1_sign_large : s1_sign_large;
    // 绝对值尾数
    assign s1_mant_sum_abs = s1_mant_sum[12]? (~s1_mant_sum+1) : s1_mant_sum;


    // 规格化移位 (左移，直到最高位为1)
    reg [4:0]  s1_exp_res;
    reg [9:0]  s1_frac_res;

    always@(*) begin
        casex(s1_mant_sum_abs[11:0])
            12'b1xxx_xxxx_xxxx: begin
                s1_exp_res = s1_exp_large + 1;
                s1_frac_res = s1_mant_sum_abs[10:1];
            end
            12'b01xx_xxxx_xxxx: begin
                s1_exp_res = s1_exp_large;
                s1_frac_res = s1_mant_sum_abs[9:0];
            end
            12'b001x_xxxx_xxxx:begin
                s1_exp_res = s1_exp_large - 1;
                s1_frac_res = {s1_mant_sum_abs[8:0], 1'b0};
            end
            12'b0001_xxxx_xxxx:begin
                s1_exp_res = s1_exp_large - 2;
                s1_frac_res = {s1_mant_sum_abs[7:0], 2'b0};
            end
            12'b0000_1xxx_xxxx:begin
                s1_exp_res = s1_exp_large - 3;
                s1_frac_res = {s1_mant_sum_abs[6:0], 3'b0};
            end
            12'b0000_01xx_xxxx:begin
                s1_exp_res = s1_exp_large - 4;
                s1_frac_res = {s1_mant_sum_abs[5:0], 4'b0};
            end
            12'b0000_001x_xxxx:begin
                s1_exp_res = s1_exp_large - 5;
                s1_frac_res = {s1_mant_sum_abs[4:0], 5'b0};
            end
            12'b0000_0001_xxxx:begin
                s1_exp_res = s1_exp_large - 6;
                s1_frac_res = {s1_mant_sum_abs[3:0], 6'b0};
            end
            12'b0000_0000_1xxx:begin
                s1_exp_res = s1_exp_large - 7;
                s1_frac_res = {s1_mant_sum_abs[2:0], 7'b0};
            end
            12'b0000_0000_01xx:begin
                s1_exp_res = s1_exp_large - 8;
                s1_frac_res = {s1_mant_sum_abs[1:0], 8'b0};
            end
            12'b0000_0000_001x:begin
                s1_exp_res = s1_exp_large - 9;
                s1_frac_res = {s1_mant_sum_abs[0], 9'b0};
            end
            12'b0000_0000_0001:begin
                s1_exp_res = s1_exp_large - 10;
                s1_frac_res = 10'b0;
            end
            default: begin
                s1_exp_res = 0;
                s1_frac_res = 0;
            end
        endcase
    end

    // -------------------------------
    // Stage output 
    // -------------------------------

    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid   <= 0;
            out_sum     <= 0;
        end
        else if(s1_valid & out_ready) begin
            out_valid   <= s1_valid;
            out_sum     <= {s1_sign_res, s1_exp_res, s1_frac_res};
        end
    end

endmodule
