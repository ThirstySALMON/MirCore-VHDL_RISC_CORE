# Test TOP-LEVEL fetch path: verify program.mem contents reach inst_out_fetch
vlib work

# --- Compilation step (comment out if sources are already compiled) -----------
# vcom -2008 src/01_components/memory_file.vhd
# vcom -2008 src/03_stages/FETCH.vhd
# vcom -2008 src/02_pipeline_registers/IFID.vhd
# vcom -2008 src/03_stages/DECODE.vhd
# vcom -2008 src/02_pipeline_registers/IDEX1.vhd
# vcom -2008 src/01_components/register_file.vhd
# vcom -2008 src/01_components/sign_extend.vhd
# vcom -2008 src/04_control/control_unit.vhd
# vcom -2008 src/05_top/top_level.vhd
# vcom -2008 src/06_tb/component_tests/top_level_tb.vhd

vsim work.top_level_tb

# --- Wave layout: grouped by stage -------------------------------------------
delete wave *

add wave -group "TB"        sim:/top_level_tb/*
add wave -group "Fetch"     sim:/top_level_tb/uut/u_fetch_stage/*
add wave -group "IF/ID"     sim:/top_level_tb/uut/u_IFID/*
add wave -group "Decode"    sim:/top_level_tb/uut/u_decode_stage/*
add wave -group "ID/EX1"    sim:/top_level_tb/uut/u_IDEX1/*
add wave -group "EX1"       sim:/top_level_tb/uut/u_EX1/*
add wave -group "EX1/EX2"    sim:/top_level_tb/uut/u_EX1EX2/*
add wave -group "Memory"    sim:/top_level_tb/uut/u_memory/*


run 5 ms 

puts "Simulation completed. Check transcript for test results."
