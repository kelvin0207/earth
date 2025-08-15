`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 09:33:19
// Design Name: 
// Module Name: buffer
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

// buffer depth (ADDR_WIDTH):
// simple estimation for synthesis, 256b is enough (addr_width=8)

// interface bandwidth (DATA_WIDTH):
// for act.: 1*4*16b = 64b
// for weight: 4*16*4b = 256b

module buffer#(
    parameter ADDR_WIDTH = 8,      // buffer 深度 = 2^ADDR_WIDTH
    parameter DATA_WIDTH = 64      // 每次读出的数据位宽
)(
    input  wire                   clk,

    // Port A (write)
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,

    // Port B (read)
    input  wire                   rd_en,
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output reg  [DATA_WIDTH-1:0]  rd_data
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // no_reset + sync read & write
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    always@(posedge clk) begin
        if(rd_en) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule
