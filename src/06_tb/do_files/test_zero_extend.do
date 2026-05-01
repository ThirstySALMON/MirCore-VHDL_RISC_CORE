# Test Zero Extend Module

# Compile
vlib work
vcom -2008 src/01_components/zero_extend.vhd
vcom -2008 src/06_tb/component_tests/zero_extend_tb.vhd

# Simulate
vsim work.zero_extend_tb

# Run simulation
run -all

# Print results
puts "Simulation completed. Check transcript for test results."