# Test ALU COMPONENT
vlib work

vcom -2008 src/01_components/conditional_jump_decoder.vhd
vcom -2008 src/06_tb/component_tests/conditional_jump_decoder_tb.vhd

vsim work.conditional_jump_decoder_tb

add wave -r *

run -all

puts "Simulation completed. Check transcript for test results."

