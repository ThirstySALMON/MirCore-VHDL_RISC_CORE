# ============================================================================
# ModelSim Compilation Only Script
# Compiles all VHDL files - no simulation
# Place this in: sim/compile.do
# ============================================================================

# Set working directory to project root
set project_root [file dirname [info script]]/..
cd $project_root

echo "=========================================="
echo "Compiling all VHDL files in src/..."
echo "=========================================="

# Get all .vhd files from src/ directory
set vhdl_files [glob -nocomplain -directory src *.vhd]

if {[llength $vhdl_files] == 0} {
    echo "ERROR: No VHDL files found in src/ directory!"
    quit
}

foreach vhdl_file [lsort $vhdl_files] {
    echo "Compiling: $vhdl_file"
    vcom $vhdl_file
}

echo ""
echo "=========================================="
echo "Compilation Complete!"
echo "=========================================="
echo ""
echo "All files compiled successfully to work library"
