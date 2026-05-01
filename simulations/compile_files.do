# ============================================================================
# ModelSim Compilation & Simulation Script (Auto-Compile All VHDL Files)
# Place this file in: sim/run_sim.do
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
echo "Auto-Compiling All VHDL Files in src/..."
echo "=========================================="

# Get all .vhd files from src/ directory and compile them
set vhdl_files [glob -nocomplain src/*.vhd]

if {[llength $vhdl_files] == 0} {
    echo "ERROR: No VHDL files found in src/ directory!"
    echo "Make sure your VHDL files are in: project_root/src/"
    quit
}

foreach vhdl_file [lsort $vhdl_files] {
    echo "Compiling: $vhdl_file"
    if {[catch {vcom -work work $vhdl_file} result]} {
        echo "ERROR compiling $vhdl_file:"
        echo $result
    }
}

echo "=========================================="
echo "Compilation Complete!"
echo "=========================================="

# Find and load testbench (assumes testbench is the last compiled file or named testbench)
# Automatically detects testbench entity (looks for entity with "testbench" in name)
echo "Loading simulation environment..."

# Try to launch the simulation
# If you have multiple testbenches, specify which one to use:
# Change "testbench" to your actual testbench entity name if different

if {[catch {vsim -work work testbench} result]} {
    echo "WARNING: Could not auto-load testbench 'testbench'"
    echo "Compiled entities available. Please specify testbench manually."
    echo "Example: vsim -work work your_testbench_name"
} else {
    echo "=========================================="
    echo "Simulation Ready!"
    echo "=========================================="
    echo "Type 'run -all' in the ModelSim console to execute"
    
    # Optional: Load waveform configuration if you have one
    # Uncomment the line below after you create sim/waveform.do
    # do sim/waveform.do
}
