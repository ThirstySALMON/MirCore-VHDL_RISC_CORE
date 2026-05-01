# Test ALU COMPONENT
vlib work

vcom -2008 src/01_components/alu.vhd
vcom -2008 src/06_tb/component_tests/alu_tb.vhd

vsim work.alu_tb

add wave -r *

run -all

puts "Simulation completed. Check transcript for test results."

