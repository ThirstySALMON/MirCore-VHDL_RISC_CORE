# ModelSim Zero-Hassle Setup Guide

## Step 1: Get latest structure and files

Pull from **Main** and make sure everything is up to date 

---

## Step 2: Create ModelSim project

**Location:** `Same as the project you cloned from git`

---

## Step 3: How to use compilation script

**Location:** `Project Root AKA MIRCORE-VHDL_RISC_CORE`

**What it does:**

All that it do is add the files in src directory (tb and everything) to the projects and compiles them

**To run**:  

`do Compile.do`

---

## Step 5: Initial Setup (First Time Only)

### On Each machine :

1. **Clone the repository:**

2. **Open ModelSim in GUI mode:**
  
  Create Project in the directory of the repo


3. **When you run the Compile.do file , ModelSim will:**
   - Add the vhd files in the project folder to your modelsim project
   - Compile all VHDL files
   - Load the testbench

---