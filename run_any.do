# ============================================================
# GENERIC DO FILE RUNNER
# Just change "target_do_file" and run this script
# ============================================================

# ============================================================
# 🔧 CHANGE ONLY THIS LINE 👇
# ============================================================
set target_do_file "src/06_tb/do_files/test_predictor_2_bit.do"

# ============================================================
# Run selected .do file
# ============================================================

echo "========================================="
echo "Running DO file:"
echo $target_do_file
echo "========================================="

if {[file exists $target_do_file]} {
    do $target_do_file
} else {
    echo "ERROR: File not found -> $target_do_file"
}