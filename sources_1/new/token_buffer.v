`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 09:59:08
// Design Name: 
// Module Name: token_buffer
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

module token_buffer(
    input  wire clk,
    input  wire rst_n,

    // Source select: 0=DRAM, 1=Dispatcher, 2=Collector, 3=Gating
    input  wire [1:0] in_src_sel,

    // ==== DRAM ====
    input  wire         in_dram_req,
    input  wire         in_dram_we,
    input  wire [7:0]   in_dram_addr,
    input  wire [63:0]  in_dram_wdata,
    output wire [63:0]  out_dram_rdata,

    // ==== Dispatcher ====
    input  wire         in_disp_req,
    input  wire [7:0]   in_disp_addr,
    output wire [63:0]  out_disp_rdata,

    // ==== Collector ====
    input  wire         in_col_req,
    input  wire [7:0]   in_col_addr,
    input  wire [63:0]  in_col_wdata,

    // ==== Gating ====
    input  wire         in_gate_req,
    input  wire         in_gate_we,
    input  wire [7:0]   in_gate_addr,
    input  wire [63:0]  in_gate_wdata,
    output wire [63:0]  out_gate_rdata
);

    // reg in
    reg [1:0]   src_sel;

    reg         dram_req;
    reg         dram_we;
    reg [7:0]   dram_addr;
    reg [63:0]  dram_wdata;

    reg         disp_req;
    reg [7:0]   disp_addr;

    reg         col_req;
    reg [7:0]   col_addr;
    reg [63:0]  col_wdata;

    reg         gate_req;
    reg         gate_we;
    reg [7:0]   gate_addr;
    reg [63:0]  gate_wdata;

    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            src_sel     <= 0;
            dram_req    <= 0;
            dram_we     <= 0;
            dram_addr   <= 0;
            dram_wdata  <= 0;

            disp_req    <= 0;
            disp_addr   <= 0;
            
            col_req     <= 0;
            col_addr    <= 0;
            col_wdata   <= 0;
            
            gate_req    <= 0;
            gate_we     <= 0;
            gate_addr   <= 0;
            gate_wdata  <= 0;
        end
        else begin
            src_sel     <= in_src_sel   ;
            dram_req    <= in_dram_req  ;
            dram_we     <= in_dram_we   ;
            dram_addr   <= in_dram_addr ;
            dram_wdata  <= in_dram_wdata;
            
            disp_req    <= in_disp_req  ;
            disp_addr   <= in_disp_addr ;
            
            col_req     <= in_col_req   ;
            col_addr    <= in_col_addr  ;
            col_wdata   <= in_col_wdata ;
            
            gate_req    <= in_gate_req  ;
            gate_we     <= in_gate_we   ;
            gate_addr   <= in_gate_addr ;
            gate_wdata  <= in_gate_wdata;
        end
    end
    
    // MUX for SRAM inputs
    reg             sram_we;
    reg  [7:0]      sram_addr;
    reg  [63:0]     sram_wdata;
    wire [63:0]     sram_rdata;

    // inst sram wrapper
    sram16_wrapper #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(64)
    ) sram_inst (
        .clk        (clk),
        .load_en    (sram_we),
        .load_addr  (sram_addr),
        .load_data  (sram_wdata),
        .fetch_en   (1),
        .fetch_addr (sram_addr),
        .fetch_data (sram_rdata)
    );

    always @(*) begin
        case (src_sel)
            2'd0: begin // DRAM
                sram_we    = dram_req & dram_we;
                sram_addr  = dram_addr;
                sram_wdata = dram_wdata;
            end
            2'd1: begin // Dispatcher (read only)
                sram_we    = 1'b0;
                sram_addr  = disp_addr;
                sram_wdata = {DATA_WIDTH{1'b0}};
            end
            2'd2: begin // Collector (write only)
                sram_we    = col_req;
                sram_addr  = col_addr;
                sram_wdata = col_wdata;
            end
            2'd3: begin // Gating
                sram_we    = gate_req & gate_we;
                sram_addr  = gate_addr;
                sram_wdata = gate_wdata;
            end
            default: begin
                sram_we    = 0;
                sram_addr  = 0;
                sram_wdata = 0;
            end
        endcase
    end

    // reg out 
    reg [1:0]   out_src_sel;
    reg [63:0]  out_sram_rdata;

    always@(posedge clk or negedge rst_n) begin
        if (rst_n) begin
            out_src_sel     <= 0;
            out_sram_rdata  <= 0;
        end
        else begin
            out_src_sel     <= src_sel;
            out_sram_rdata  <= sram_rdata;
        end
    end

    assign out_dram_rdata = (out_src_sel == 2'd0) ? out_sram_rdata : 0;
    assign out_disp_rdata = (out_src_sel == 2'd1) ? out_sram_rdata : 0;
    assign out_gate_rdata = (out_src_sel == 2'd3) ? out_sram_rdata : 0;

endmodule
