# 创建顶层时钟，周期 1ns -> 1GHz
# 定义时钟
create_clock -name clk -period 1.0 [get_ports clk] -waveform {0 0.5}

# 复位信号通常不约束（异步）
set_false_path -from [get_ports rst_n]

# 输入延时（示例：0.1ns）
set_input_delay -clock clk 0.1 [get_ports { \
    dram_rd_data[*] \
    dram_rd_valid \
    dram_wr_ready \
    cfg_start \
    cfg_status[*] \
}]

# 输出延时（示例：0.1ns）
set_output_delay -clock clk 0.1 [get_ports { \
    dram_rd_en \
    dram_rd_addr[*] \
    dram_wr_en \
    dram_wr_addr[*] \
    dram_wr_data[*] \
    done \
}]
