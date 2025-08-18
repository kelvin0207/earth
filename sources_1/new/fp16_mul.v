`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/16 16:30:53
// Design Name:  fp16*fp16 multiplier
// Module Name: fp16_mul
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


module fp16_mul(
    input   wire        clk,
    input   wire        rst_n,

    // Input side
    input  wire         in_valid,
    output wire         in_ready,
    input  wire [15:0]  in_a,
    input  wire [15:0]  in_b,

    // Output side
    output reg          out_valid,
    input  wire         out_ready,
    output reg  [15:0]  out_prod
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
    reg [4:0]  s0_exp_b;
    reg [9:0]  s0_frac_b;
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
            s0_exp_b        <= 0;
            s0_frac_b       <= 0;
            s0_is_zero_b    <= 1;
        end

        // data move forward and new data fill stage 0
        else if (in_valid & s0_ready) begin
            s0_valid        <= 1;

            s0_sign_a       <= in_a[15];
            s0_exp_a        <= in_a[14:10];
            s0_frac_a       <= in_a[9:0];

            s0_is_zero_a    <= ((in_a[14:10] == 5'b0));

            s0_sign_b       <= in_b[15];
            s0_exp_b        <= in_b[14:10];
            s0_frac_b       <= in_b[9:0];

            s0_is_zero_b    <= ((in_b[14:10] == 5'b0));
        end 

        // data moved forward, but no new data fill stage 0
        else if (s1_ready & s0_valid) begin
            s0_valid        <= 0; 
        end
    end

    // -------------------------------
    //  combinational calculation
    // -------------------------------
    wire        s0_comb_sign;
    wire        s0_comb_is_zero;

    wire [5:0]  s0_exp_sum;
    
    wire [10:0] s0_mant_a;
    wire [10:0] s0_mant_b;
    wire [21:0] s0_comb_product;

    assign s0_comb_sign = s0_sign_a ^ s0_sign_b;
    assign s0_comb_is_zero = s0_is_zero_a | s0_is_zero_b;

    assign s0_exp_sum = s0_exp_a + s0_exp_b - 6'd15;

    assign s0_mant_a = {1'b1, s0_frac_a};
    assign s0_mant_b = {1'b1, s0_frac_b};

    assign s0_comb_product = s0_mant_a * s0_mant_b;

    // -------------------------------
    // Stage1: shifting and round
    // -------------------------------

    reg         s1_sign_out;
    reg [5:0]   s1_exp_sum;
    reg         s1_is_zero;
    reg [11:0]  s1_product;


    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            s1_valid        <= 0;
            s1_sign_out     <= 0;
            s1_exp_sum      <= 0;
            s1_is_zero      <= 0;
            s1_product      <= 0;
        end
        else if(s0_valid && s1_ready) begin
            s1_valid        <= 1;
            s1_sign_out     <= s0_comb_sign;
            s1_exp_sum      <= s0_exp_sum;
            s1_is_zero      <= s0_comb_is_zero;
            // truncate to 2+10 bit
            s1_product      <= s0_comb_product[21:10];
        end
        else if (out_ready && s1_valid) begin
            s1_valid <= 0; // data moved forward
        end
    end

    // whether shift right
    wire s1_shift;

    assign s1_shift = s1_product[11];
    
    // shifting
    wire [5:0]  s1_exp_shift;
    wire [10:0] s1_mant_shift;

    assign s1_exp_shift = s1_exp_sum + s1_shift;
    assign s1_mant_shift = s1_shift? s1_product[11:1] : s1_product[10:0];

    // -------------------------------
    // Stage output 
    // -------------------------------

    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid   <= 0;
            out_prod    <= 0;
        end
        else if(s1_valid & out_ready) begin
            out_valid   <= s1_valid;
            out_prod    <= {s1_sign_out, s1_exp_shift, s1_mant_shift[9:0]};
        end
    end

endmodule
