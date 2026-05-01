# Test Zero Extend Module

# Compile
vlib work
vcom -2008 src/components/zero_extend.vhd
vcom -2008 tb/test_programs/zero_extend_tb.vhd

# Simulate
vsim work.zero_extend_tb

# Run simulation
run -all

# Print results
puts "Simulation completed. Check transcript for test results."