# --- Configuration ---
set SRC_DIR "./src"

# --- 1. Recursive Search Procedure (Disk) ---
proc find_vhdl_files {dir} {
    set vhdl_files {}
    foreach item [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $item]} {
            set vhdl_files [concat $vhdl_files [find_vhdl_files $item]]
        } elseif {[file extension $item] eq ".vhd"} {
            # Normalize path so comparison works reliably
            lappend vhdl_files [file normalize $item]
        }
    }
    return $vhdl_files
}

# --- 2. Get Current Project State ---
set disk_files [find_vhdl_files $SRC_DIR]
set project_files {}
foreach p_file [project filenames] {
    lappend project_files [file normalize $p_file]
}

# --- 3. Remove "Ghost" Files ---
# If it's in the project but NOT on the disk, delete it
foreach f $project_files {
    if {$f ni $disk_files} {
        echo "Removing missing file from project: $f"
        project removefile $f
    }
}

# --- 4. Add New Files & Compile ---
foreach f $disk_files {
    if {$f ni $project_files} {
        echo "Adding new file to project: $f"
        project addfile $f
    }
}
project compileoutofdate
echo "--- Project Sync and Compilation Complete ---"