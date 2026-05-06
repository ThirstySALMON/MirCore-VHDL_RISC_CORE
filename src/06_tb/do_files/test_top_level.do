# Test TOP-LEVEL fetch path: verify program.mem contents reach inst_out_fetch
vlib work

vcom -2008 src/01_components/memory_file.vhd
vcom -2008 src/03_stages/FETCH.vhd
vcom -2008 src/06_tb/component_tests/top_level_tb.vhd

vsim work.top_level_tb

add wave -r *

run -all

puts "Simulation completed. Check transcript for test results."
