# Test ALU COMPONENT
vlib work

vcom -2008 src/04_control/predictor_2_bit.vhd
vcom -2008 src/06_tb/component_tests/predictor_2_bit_tb.vhd

vsim work.predictor_2_bit_tb

add wave -r *

run -all

puts "Simulation completed. Check transcript for test results."

