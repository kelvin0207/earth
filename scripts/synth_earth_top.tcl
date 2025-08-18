############################################################
# Synopsys Design Compiler TCL Script for earth_top
# Author: Jingkui Yang
# Date  : 2025-08-18
############################################################

# ========== 基本设置 ==========
set DESIGN_NAME "earth_top"
set FILELIST    "/home/yangjingkui/CodeField/earth/rtl/filelist.v"
set SDC_FILE    "/home/yangjingkui/CodeField/earth/sdc/earth_top.sdc"
set TARGET_LIB  "/home/yangjingkui/CodeField/earth/lib/tcbn28hpcplusbwp12t40p140lvttt1v25c_ccs.db"

# 获取时间戳 (格式: YYYYMMDD_HHMMSS)
set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]

# 设置输出目录为 syn/syn_时间戳
set REPORT_DIR "./syn/syn_$timestamp"

# 如果目录不存在则创建
if {![file isdirectory $REPORT_DIR]} {
    file mkdir $REPORT_DIR
}

# 设置网表/SDC输出路径
set NETLIST_OUT "$REPORT_DIR/${DESIGN_NAME}_syn.v"
set SDC_OUT     "$REPORT_DIR/${DESIGN_NAME}_syn.sdc"

# ========== 读库 ==========
set target_library $TARGET_LIB
set link_library   "* $TARGET_LIB"

# ========== 读 RTL ==========
set fp [open $FILELIST r]
set file_data [read $fp]
close $fp
set file_lines [split $file_data "\n"]

foreach f $file_lines {
    if {$f ne ""} {
        read_verilog $f
    }
}

# ========== 设置顶层 ==========
current_design $DESIGN_NAME

# ========== 读约束 ==========
read_sdc $SDC_FILE

# ========== 编译综合 ==========
compile_ultra -timing

# ========== 报告 ==========
report_area  > $REPORT_DIR/${DESIGN_NAME}_area.rpt
report_power > $REPORT_DIR/${DESIGN_NAME}_power.rpt
report_timing -max_paths 20 > $REPORT_DIR/${DESIGN_NAME}_timing.rpt

# ========== 导出结果 ==========
write_verilog -hierarchy -output $NETLIST_OUT
write_sdc -output $SDC_OUT
