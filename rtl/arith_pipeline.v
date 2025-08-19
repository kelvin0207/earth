`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/17 14:47:26
// Design Name: Arithmetic pipeline
// Module Name: arith_pipeline
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

// Arithmetic pipeline
// 完成top-k之后就剩下了算术模块，它的主要作用是挨个处理output collector发来的结果，
// 并进行pipeline的计算，计算需要支持：

// softmax：exp、累加、除法（牛顿迭代法），
// activation function（GeLU as example), 
// 累加（乘以一个权重并于psum累加），

// 我希望一条流水线或者一套硬件能够通过可配置支持，不需要为每个单独写一套
// 将复杂计算都近似为乘法与查表，这样硬件实现会简单很多，
// 我们只需要实现对FP的乘法与加法支持，辅以LUT查表，便可以支持所有的计算

// 因此，我们只需要
// 1. LUT 实现exp (softmax中)，GeLU, b->1/b
// 2. 乘法器和累加器

module arith_pipeline(
    input wire          clk,
    input wire          rst_n,

    // input side
    input wire          in_valid,
    input wire [15:0]   in_data,
    input wire [15:0]   in_psum, // only valid in AGG mode
    input wire [1:0]    in_mode, 
    // 0: exp+sum (softmax)
    // 1: div (norm.)
    // 2. GeLU
    // 3. AGG
    
    // output side
    output reg           out_valid,
    output reg   [15:0]  out_data
    );

    // 256-entry LUT
    reg [15:0] rom_exp [0:255];
    reg [15:0] rom_div [0:255];
    reg [15:0] rom_gelu [0:255];
    
    // 写入假数据避免被优化掉
    // integer i;
    // initial begin
    //     for (i = 0; i < 256; i = i + 1) begin
    //         rom_exp[i]  = i;        // placeholder
    //         rom_div[i]  = 16'h0001; // placeholder
    //         rom_gelu[i] = 16'h0000; // placeholder
    //     end
    // end

    // stage in
    reg [15:0]  s0_data;
    reg [15:0]  s0_psum;
    reg [1:0]   s0_mode;
    reg         s0_valid;

    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            s0_data     <= 0;
            s0_psum     <= 0;
            s0_mode     <= 0;
            s0_valid    <= 0;
        end
        else if(in_valid) begin
            s0_data     <= in_data;
            s0_psum     <= in_psum;
            s0_mode     <= in_mode;
            s0_valid    <= 1;
        end
    end
    
    // expert weight (gating score) stored in local buffer
    // write in mode 1, read in mode 3,
    reg [15:0]  buffer_weight [0:7];
    reg [2:0]   buffer_idx;

    // mode = 0: LUT get exp and acc
    // mode = 1: LUT get frac and mul, stored in 
    // mode = 2: LUT get GeLU
    // mode = 3: mul with weight and add

    reg         mul_in_valid;
    reg [15:0]  mul_in_a;
    reg [15:0]  mul_in_b;
    wire         mul_out_valid;
    wire [15:0]  mul_out_prod;
    
    reg         add_in_valid;
    reg [15:0]  add_in_a;
    reg [15:0]  add_in_b;
    wire         add_out_valid;

    integer i;
    
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            buffer_idx <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                buffer_weight[i] <= 0;
            end
        end
        else if (s0_mode==2'b00 || s0_mode==2'b10) begin
            buffer_idx <= 0; // only reset idx is enough
        end
        else if (s0_mode == 2'b01) begin
            buffer_weight[buffer_idx] <= mul_out_prod;
            buffer_idx <= buffer_idx + 3'b1;
        end
        else if(s0_mode == 2'b11) begin
            buffer_idx <= buffer_idx + 3'b1;
        end
    end


    wire [15:0]  add_out_sum;

    always@(*) begin
        case(s0_mode)
            2'b00: begin
                // don't need mul
                mul_in_valid = 0;
                mul_in_a = 0;
                mul_in_b = 0;
                add_in_valid = 1;
                add_in_a = rom_exp[s0_data[7:0]];
                add_in_b = add_out_sum;
            end
            2'b01: begin
                mul_in_valid = 1;
                mul_in_a = rom_div[add_out_sum[7:0]];
                mul_in_b = s0_data;
                add_in_valid = 0;
                add_in_a = 0;
                add_in_b = 0;
            end
            2'b10: begin
                mul_in_valid = 0;
                mul_in_a = 0;
                mul_in_b = 0;
                add_in_valid = 0;
                add_in_a = 0;
                add_in_b = 0;
            end
            2'b11: begin
                mul_in_valid = 1;
                mul_in_a = buffer_weight[buffer_idx];
                mul_in_b = s0_data;
                add_in_valid = 1;
                add_in_a = s0_psum;
                add_in_b = mul_out_prod;
            end
        endcase
    end
    
    // inst a mul and a adder
    fp16_mul mul(
        .clk        (clk),
        .rst_n      (rst_n),
        // Input side
        .in_valid   (mul_in_valid),
        .in_ready   (),
        .in_a       (mul_in_a),
        .in_b       (mul_in_b),
        // Output side
        .out_valid  (mul_out_valid),
        .out_ready  (1'b1),
        .out_prod   (mul_out_prod)
    );

    fp16_adder adder(
        .clk        (clk),
        .rst_n      (rst_n),
        // Input side
        .in_valid   (add_in_valid),
        .in_ready   (),
        .in_a       (add_in_a),
        .in_b       (add_in_b),
        // Output side
        .out_valid  (add_out_valid),
        .out_ready  (1'b1),
        .out_sum    (add_out_sum)
    );

    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            out_valid   <= 0;
            out_data    <= 0;
        end
        else if (s0_mode==2'b00 || s0_mode==2'b01) begin
            out_valid   <= 0;
            out_data    <= 0;
        end
        else if (s0_mode==2'b10 && s0_valid) begin
            out_valid   <= 1;
            out_data    <= rom_gelu[s0_data[7:0]];
        end
        else begin
            out_valid   <= 1;
            out_data    <= add_out_sum;
        end
    end

endmodule
