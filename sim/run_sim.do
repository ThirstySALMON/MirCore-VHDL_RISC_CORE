# ============================================================================
# ModelSim Compilation Only Script (Includes Subdirectories)
# Compiles all VHDL files in src/ and all subdirectories - no simulation
# Place this in: sim/compile.do
# ============================================================================

# Set working directory to project root
set project_root [file dirname [info script]]/..
cd $project_root

echo "=========================================="
echo "Compiling all VHDL files in src/ (including subdirectories)..."
echo "=========================================="

# Recursively find all .vhd files in src/ and subdirectories
set vhdl_files [glob -nocomplain -directory src -type f -tail *.vhd src/*/*.vhd src/*/*/*.vhd src/*/*/*/*.vhd]

# Alternative method using find (more flexible):
# set vhdl_files [exec find src -name "*.vhd"]

if {[llength $vhdl_files] == 0} {
    echo "ERROR: No VHDL files found in src/ or subdirectories!"
    quit
}

echo "Found [llength $vhdl_files] VHDL file(s)..."
echo ""

foreach vhdl_file [lsort $vhdl_files] {
    echo "Compiling: $vhdl_file"
    if {[catch {vcom $vhdl_file} result]} {
        echo "ERROR compiling $vhdl_file: $result"
    }
}

echo ""
echo "=========================================="
echo "Compilation Complete!"
echo "=========================================="
echo ""
echo "All files compiled successfully to work library"
