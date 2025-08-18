`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 09:59:08
// Design Name: 
// Module Name: weight_buffer
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


module weight_buffer(
    input  wire clk,
    input  wire rst_n,

    // ==== DRAM ====
    input  wire             in_dram_req,
    input  wire             in_dram_we,
    input  wire [7:0]       in_dram_addr,
    input  wire [4095:0]    in_dram_wdata,

    // ==== Dispatcher ====
    input  wire             in_disp_req,
    input  wire [7:0]       in_disp_addr,
    output reg  [4095:0]    out_disp_rdata
);

    // reg in
    reg             dram_req;
    reg             dram_we;
    reg [7:0]       dram_addr;
    reg [4095:0]    dram_wdata;

    reg             disp_req;
    reg [7:0]       disp_addr;

    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            dram_req    <= 0;
            dram_we     <= 0;
            dram_addr   <= 0;
            dram_wdata  <= 0;

            disp_req    <= 0;
            disp_addr   <= 0;
        end
        else begin
            dram_req    <= in_dram_req  ;
            dram_we     <= in_dram_we   ;
            dram_addr   <= in_dram_addr ;
            dram_wdata  <= in_dram_wdata;
            
            disp_req    <= in_disp_req  ;
            disp_addr   <= in_disp_addr ;
        end
    end
    
    // MUX for SRAM inputs
    wire            sram_we;
    wire [7:0]      sram_addr;
    wire [4095:0]   sram_wdata;
    wire [4095:0]   sram_rdata;

    assign sram_we = dram_req & dram_we;
    assign sram_addr = (sram_we)? dram_addr : disp_addr;
    assign sram_wdata = dram_wdata;

    // inst sram wrapper
    sram16_wrapper #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(256)
    ) sram_inst (
        .clk        (clk),
        .load_en    (sram_we),
        .load_addr  (sram_addr),
        .load_data  (sram_wdata),
        .fetch_en   (1'b1),
        .fetch_addr (sram_addr),
        .fetch_data (sram_rdata)
    );

    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_disp_rdata  <= 0;
        end
        else begin
            out_disp_rdata  <= disp_req? sram_rdata : 0;
        end
    end

endmodule
