`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/11 16:47:29
// Design Name: 
// Module Name: tb_fp_mul
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


module tb_fp16_int4_mul;

    // Clock & reset
    reg clk;
    reg rst_n;

    // Clock: 10ns period (100 MHz)
    initial begin
        clk = 1'b0;  // 初始化为0，更符合常规
        forever #5 clk = ~clk;  // 用forever确保时钟持续翻转
    end

    // DUT interface signals
    reg         in_valid;
    wire        in_ready;
    reg  [15:0] in_fp16;
    reg  [3:0]  in_int4;

    wire        out_valid;
    reg         out_ready;
    wire [15:0] out_fp16;

    // Instantiate DUT
    fp16_int4_mul dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (in_valid),
        .in_ready  (in_ready),
        .in_fp16   (in_fp16),
        .in_int4   (in_int4),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .out_fp16  (out_fp16)
    );


    // Test vectors (include zero cases)
    localparam NUM_VEC = 8;
    reg [15:0] tv_fp16 [0:NUM_VEC-1];
    reg  [3:0] tv_int4  [0:NUM_VEC-1];

    initial begin
        // prepare vectors (FP16 hex literals)
        // 0x3C00 = +1.0 ; 0x4000 = +2.0 ; 0x3E00 = +1.5 ; 0x3800 = +0.5
        // 0x0000 = +0.0 ; 0xC000 = -2.0
        tv_fp16[0] = 16'h3C00; tv_int4[0] = 4'd1;    // 1.0 * +1
        tv_fp16[1] = 16'h4000; tv_int4[1] = 4'd3;    // 2.0 * +3
        tv_fp16[2] = 16'h3E00; tv_int4[2] = 4'b1111; // 1.5 * -1
        tv_fp16[3] = 16'h0000; tv_int4[3] = 4'd5;    // 0.0 * +5  (left operand zero)
        tv_fp16[4] = 16'h3C00; tv_int4[4] = 4'd0;    // 1.0 * 0   (weight zero)
        tv_fp16[5] = 16'h3800; tv_int4[5] = 4'b1000; // 0.5 * -8
        tv_fp16[6] = 16'hC000; tv_int4[6] = 4'd6;    // -2.0 * +6
        tv_fp16[7] = 16'h3C00; tv_int4[7] = 4'b0111; // 1.0 * +7

        // init signals
        rst_n     = 0;
        in_valid  = 0;
        in_fp16   = 16'h0;
        in_int4   = 4'h0;
        out_ready = 1;

        #20;
        rst_n = 1;
        in_valid = 1;
        in_fp16 = tv_fp16[0];
        in_int4 = tv_int4[0];
        // expect res = 0x3c00

        #10;
        in_fp16 = tv_fp16[1];
        in_int4 = tv_int4[1];
        // expect res = 0x4c00
        
        #10;
        in_fp16 = tv_fp16[2];
        in_int4 = tv_int4[2];

        #10;
        in_fp16 = tv_fp16[3];
        in_int4 = tv_int4[3];

        #10;
        in_fp16 = tv_fp16[4];
        in_int4 = tv_int4[4];

        #10;
        in_fp16 = tv_fp16[5];
        in_int4 = tv_int4[5];
        
        #10;
        in_fp16 = tv_fp16[6];
        in_int4 = tv_int4[6];

        #10;
        in_fp16 = tv_fp16[7];
        in_int4 = tv_int4[7];

        #10 $finish;
    end

endmodule
