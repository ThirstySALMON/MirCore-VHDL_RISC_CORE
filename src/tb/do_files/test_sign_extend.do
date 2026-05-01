# Test Sign Extend Module

vlib work
vcom -2008 src/components/sign_extend.vhd
vcom -2008 tb/test_programs/sign_extend_tb.vhd
vsim work.sign_extend_tb
run -all
# Print results
puts "Simulation completed. Check transcript for test results."