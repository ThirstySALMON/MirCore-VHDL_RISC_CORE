# ============================================================================
# ModelSim Compilation & Simulation Script
# ============================================================================

# Navigate to project root (assuming run_sim.do is in sim/ directory)
cd [file dirname [info script]]/..

echo "=========================================="
echo "Starting Fresh Compilation..."
echo "=========================================="

# Delete old work library (IMPORTANT - prevents stale objects)
if {[file exists build/work]} {
    echo "Cleaning old build/work library..."
    vdel -all -lib build/work
}

# Create build directory if it doesn't exist
if {![file exists build]} {
    file mkdir build
}

# Create fresh work library
echo "Creating fresh work library..."
vlib build/work
vmap work build/work

echo "=========================================="
echo "Compiling VHDL Files..."
echo "=========================================="

# Compile in dependency order (low-level to high-level)
# Adjust filenames to match your actual files

echo "Compiling ALU..."
vcom -work work src/alu.vhd

echo "Compiling Registers..."
vcom -work work src/registers.vhd

echo "Compiling Memory..."
vcom -work work src/memory.vhd

echo "Compiling Control Unit..."
vcom -work work src/control_unit.vhd

echo "Compiling Pipeline Registers..."
vcom -work work src/pipeline_registers.vhd

echo "Compiling Processor Top Module..."
vcom -work work src/processor_top.vhd

echo "Compiling Testbench..."
vcom -work work src/testbench.vhd

echo "=========================================="
echo "Launching Simulation..."
echo "=========================================="

# Load simulation
vsim -work work testbench

# Optional: Load waveform configuration if you have one
# do sim/waveform.do

echo "Simulation Ready!"
echo "Type 'run -all' to execute"