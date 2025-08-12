`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jingkui Yang
// 
// Create Date: 2025/08/12 11:24:15
// Design Name: processing element array
// Module Name: pe array
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

module pe_array (
    input  wire         clk,
    input  wire         rst_n,

    // Global handshake
    input  wire         in_valid,
    output wire         in_ready,
    input  wire         out_ready,

    // 16 sets of activations and weights
    // Activations: { pe15.act3, pe15.act2, pe15.act1, pe15.act0, pe14.act3, ..., pe0.act0 }
    input  wire [1023:0] in_fp16_acts, // 16 groups × 4 × 16bit = 1024 bits
    // Weights: { pe15.weights[255:0], pe14.weights[255:0], ..., pe0.weights[255:0] }
    input  wire [4095:0] in_int4s,     // 16 groups × 256 bits

    // Outputs
    output wire [15:0]   out_valid_vec,  // one valid bit per PE
    output wire [4095:0] out_fp16s       // 16 groups × 256 bits
);

    wire [15:0] pe_in_ready;
    wire [15:0] pe_out_valid;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : PE_GEN
            // Extract this PE's activations
            wire [15:0] act0 = in_fp16_acts[(i*64)    +: 16];
            wire [15:0] act1 = in_fp16_acts[(i*64)+16 +: 16];
            wire [15:0] act2 = in_fp16_acts[(i*64)+32 +: 16];
            wire [15:0] act3 = in_fp16_acts[(i*64)+48 +: 16];

            // Extract this PE's weights
            wire [255:0] weights = in_int4s[(i*256) +: 256];

            pe16 u_pe16 (
                .clk        (clk),
                .rst_n      (rst_n),
                .in_fp16_0  (act0),
                .in_fp16_1  (act1),
                .in_fp16_2  (act2),
                .in_fp16_3  (act3),
                .in_int4s   (weights),
                .in_valid   (in_valid),
                .in_ready   (pe_in_ready[i]),
                .out_valid_vec(out_valid_vec[(i)]), // Each PE has its own valid
                .out_ready  (out_ready),
                .out_fp16s  (out_fp16s[(i*256) +: 256])
            );
        end
    endgenerate

    // Global in_ready: all PEs must be ready
    assign in_ready = &pe_in_ready;

endmodule
