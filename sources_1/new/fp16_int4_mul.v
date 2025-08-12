`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/11 13:48:43
// Design Name: FP16 * INT 4 multiplier
// Module Name: fp_mul
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

module fp16_int4_mul (
    input   wire        clk,
    input   wire        rst_n,

    // Input side
    input  wire         in_valid,
    output wire         in_ready,
    input  wire [15:0]  in_fp16,
    input  wire [3:0]   in_int4,

    // Output side
    output reg          out_valid,
    input  wire         out_ready,
    output reg  [15:0]  out_fp16
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
    reg        s0_is_zero_a;

    reg        s0_sign_b;
    reg [3:0]  s0_abs_b;
    reg        s0_is_zero_b;

    // -------------------------------
    // Stage in: unpack and multiplication
    // -------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            s0_valid        <= 0;

            s0_sign_a       <= 0;
            s0_exp_a        <= 0;
            s0_frac_a       <= 0;
            s0_is_zero_a    <= 1;

            s0_sign_b       <= 0;
            s0_abs_b        <= 0;
            s0_is_zero_b    <= 1;
        end

        // data move forward and new data fill stage 0
        else if (in_valid & s0_ready) begin
            s0_valid        <= 1;

            s0_sign_a       <= in_fp16[15];
            s0_exp_a        <= in_fp16[14:10];
            s0_frac_a       <= in_fp16[9:0];

            s0_is_zero_a    <= ((in_fp16[14:10] == 5'b0));

            s0_sign_b       <= in_int4[3];
            s0_abs_b        <= in_int4[3] ? ((~in_int4) + 4'b1) : in_int4;
            s0_is_zero_b    <= (in_int4 == 4'b0);
        end 

        // data moved forward, but no new data fill stage 0
        else if (s1_ready & s0_valid) begin
            s0_valid        <= 0; 
        end
    end

    // -------------------------------
    //  combinational calculation
    // -------------------------------
    wire       s0_comb_sign;
    wire       s0_comb_is_zero;

    wire [10:0] s0_mant_a;
    wire [13:0] s0_comb_product;

    assign s0_comb_sign = s0_sign_a ^ s0_sign_b;
    assign s0_comb_is_zero = s0_is_zero_a | s0_is_zero_b;

    assign s0_mant_a = {1'b1, s0_frac_a};
    assign s0_comb_product = s0_mant_a * s0_abs_b;

    // -------------------------------
    // Stage1: shifting and round
    // -------------------------------

    reg         s1_sign_out;
    reg [4:0]   s1_exp_a;
    reg         s1_is_zero;
    reg [13:0]  s1_product;


    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            s1_valid        <= 0;
            s1_sign_out     <= 0;
            s1_exp_a        <= 0;
            s1_is_zero      <= 0;
            s1_product      <= 0;
        end
        else if(s0_valid && s1_ready) begin
            s1_valid        <= 1;
            s1_sign_out     <= s0_comb_sign;
            s1_exp_a        <= s0_exp_a;
            s1_is_zero      <= s0_comb_is_zero;
            s1_product      <= s0_comb_product;
        end
        else if (out_ready && s1_valid) begin
            s1_valid <= 0; // data moved forward
        end
    end

    // leading-zero count
    reg [1:0] s1_shift_cnt;

    always@(*) begin
        casex(s1_product[13:10])
            4'b1xxx: s1_shift_cnt = 3;
            4'b01xx: s1_shift_cnt = 2;
            4'b001x: s1_shift_cnt = 1;
            4'b0001: s1_shift_cnt = 0;
            default: s1_shift_cnt = 0;
        endcase
    end

    // shifting
    reg [9:0] s1_mant_comb;
    reg [4:0] s1_exp_comb;

    always@(*) begin
        if (s1_is_zero) begin
            s1_mant_comb = 0;
            s1_exp_comb = 0;
        end
        else begin
            s1_mant_comb = s1_product >> s1_shift_cnt;
            s1_exp_comb = s1_exp_a + s1_shift_cnt;
        end
    end

    // -------------------------------
    // Stage output 
    // -------------------------------

    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid   <= 0;
            out_fp16    <= 0;
        end
        else if(s1_valid & out_ready) begin
            out_valid   <= s1_valid;
            out_fp16    <= {s1_sign_out, s1_exp_comb, s1_mant_comb};
        end
    end

endmodule
