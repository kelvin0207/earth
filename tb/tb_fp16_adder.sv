`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/12 10:53:58
// Design Name: 
// Module Name: tb_fp16_adder
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


module tb_fp16_adder;

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
    reg  [15:0] in_a;
    reg  [15:0] in_b;

    wire        out_valid;
    reg         out_ready;
    wire [15:0] out_sum;

    // Instantiate DUT
    fp16_adder dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (in_valid),
        .in_ready  (in_ready),
        .in_a      (in_a),
        .in_b      (in_b),
        .out_valid (out_valid),
        .out_ready (out_ready),
        .out_sum   (out_sum)
    );


    // Test vectors (include zero cases)
    localparam NUM_VEC = 6;
    reg [15:0] tv_fp16 [0:NUM_VEC-1];

    initial begin
        // prepare vectors (FP16 hex literals)
        // 0x3C00 = +1.0 ; 0x4000 = +2.0 ; 0x3E00 = +1.5 ; 0x3800 = +0.5
        // 0x0000 = +0.0 ; 0xC000 = -2.0
        tv_fp16[0] = 16'h0000;  // 0.0 
        tv_fp16[1] = 16'h3800;  // 0.5 
        tv_fp16[2] = 16'h3C00;  // 1.0 
        tv_fp16[3] = 16'h3E00;  // 1.5 
        tv_fp16[4] = 16'h4000;  // 2.0 
        tv_fp16[5] = 16'hC000;  // -2.0

        // init signals
        rst_n     = 0;
        in_valid  = 0;
        in_a      = 16'h0;
        in_b      = 4'h0;
        out_ready = 1;

        #20;
        rst_n = 1;
        in_valid = 1;
        in_a = tv_fp16[0];
        in_b = tv_fp16[1];

        #10;
        in_a = tv_fp16[1];
        in_b = tv_fp16[2];
        
        #10;
        in_a = tv_fp16[2];
        in_b = tv_fp16[3];

        #10;
        in_a = tv_fp16[3];
        in_b = tv_fp16[4];

        #10;
        in_a = tv_fp16[4];
        in_b = tv_fp16[5];

        #10;
        in_a = tv_fp16[3];
        in_b = tv_fp16[5];

        #10 $finish;
    end

endmodule