# PHASE 2 IMPLEMENTATION GUIDE - 6-STAGE PIPELINED PROCESSOR

Cairo University CMPS 301 - Team 10  
Duration: 1 Week | Team Size: 4 People

---

## Table of Contents

1. [Overview](#1-overview)
2. [Team Structure & Task Distribution](#2-team-structure--task-distribution)
3. [Critical Success Factors](#3-critical-success-factors)
4. [Week-by-Week Breakdown](#4-week-by-week-breakdown)
5. [What to Start Implementing First](#5-what-to-start-implementing-first-priority-order)
6. [How to Integrate Components](#6-how-to-integrate-components-the-right-way)
7. [Understanding .mem Files & How to Use Them](#7-understanding-mem-files--how-to-use-them)
8. [Understanding .do Files (Simulation Scripts)](#8-understanding-do-files-simulation-scripts)
9. [Components to Code (With VHDL Structure)](#9-components-to-code-with-vhdl-structure)
10. [Testing Strategy](#10-testing-strategy-how-to-verify-each-component)
11. [VHDL Coding Best Practices](#11-vhdl-coding-best-practices-for-this-project)
12. [.mem File Generation (For Assembler Developer)](#12-mem-file-generation-for-assembler-developer)
13. [Debugging .do Files](#13-debugging-do-files-common-issues)
14. [Final Checklist](#14-final-checklist-end-of-week-7)
15. [Summary: One Week Schedule At a Glance](#15-summary-one-week-schedule-at-a-glance)

---

## 1. Overview

This guide provides a task-parallel approach where all team members work simultaneously on different components, with structured integration points. The goal is a WORKING processor by end of week, even if not all instructions are implemented.

---

## 2. Team Structure & Task Distribution

### 2.1 Person 1: Assembler & Test Program Developer

- Write assembler (converts assembly to machine code/hex)
- Create test programs for each instruction type
- Generate .mem files (memory initialization files)
- Prepare test data and expected outputs
- **CRITICAL: Wait until Person 3 finishes component interface definitions**

### 2.2 Person 2: Memory & Register File

- Implement Memory (RAM) module with .mem file loading
- Implement Register File with forwarding outputs
- These are data storage modules (lowest dependency)
- Can work independently from the start

### 2.3 Person 3: ALU, Control Unit & Hazard Management

- Implement ALU with all operations (ADD, SUB, AND, NOT, INC, MOV, etc.)
- Implement Control Unit / Instruction Decoder
- Implement Hazard Detection Unit and Forwarding Unit
- **CRITICAL: Define all signal interfaces early (by Day 1 EOD)**
- This person sets the "contract" for how other modules work

### 2.4 Person 4: Pipeline Registers & Top-Level Integration

- Implement all pipeline registers (IF/ID, ID/EX1, EX1/EX2, EX2/MEM, MEM/WB)
- Implement Fetch Stage logic (PC increment, branch handling)
- Create the TOP-LEVEL PROCESSOR MODULE
- Integrates all components as they're completed
- Manages clock, reset, and pipeline flow

---

## 3. Critical Success Factors (Read This First)

### 3.1 Define Interfaces First (Day 1)

- Person 3 creates a document with ALL signal definitions (names, widths, timing)
- All other modules must conform to these signals
- Without this, you'll waste days on integration

### 3.2 Use .mem Files for Testing

- Memory is loaded from .mem file during simulation
- Format: Each line = one 32-bit word in hex (one instruction per line)
- Example: "11010101010101010101010101010101" or "D5555555" (hex)
- Tools: Your assembler generates .mem files automatically

### 3.3 Do Files for Simulation

- A .do file is a script that runs simulation commands automatically
- Eliminates manual clicking in ModelSim
- Loads .mem files, runs clock cycles, displays waveforms
- One .do file per test = one test program

### 3.4 VHDL Best Practices for This Project

- Use separate entities for each component (Memory, RegFile, ALU, etc.)
- Use a top-level entity that instantiates all components
- Don't over-complicate: if it works, it works. Polish = luxury at 1 week.
- Comment like your professor is grading it (they are)
- Use consistent naming: signal_name, not s_signalname or SignalName

### 3.5 Testing Strategy

- Start with simplest instructions (NOP, HLT)
- Then single-operand (NOT, INC)
- Then register-to-register (MOV, ADD, SUB)
- Then memory ops (LDD, STD, PUSH, POP)
- Finally branches/jumps (JZ, JN, JMP, CALL, RET)
- DON'T try all instructions at once; test incrementally

---

## 4. Week-by-Week Breakdown (Days 1-7)

### 4.1 Day 1: Interface Definition & Module Skeleton

#### Person 1 (Assembler):
- Wait and listen to Person 3's interface definitions
- Create template for assembler (input: .asm file, output: .mem file)
- Study ISA encoding from Team_10__ISA__Sheet1.pdf
- Prep test assembly programs (not implemented yet, just planned)

#### Person 2 (Memory & Registers):
- Create Memory module skeleton:
  * Inputs: clk, rst, addr, data_in, write_enable, read_enable
  * Outputs: data_out
  * Feature: Load from .mem file in simulation
- Create Register File skeleton:
  * Inputs: read_addr1, read_addr2, write_addr, write_data, write_enable, clk
  * Outputs: read_data1, read_data2
  * 8 registers (R0-R7)
- Create file: define_interfaces.vhd (shared with everyone)

#### Person 3 (ALU, Control, Hazard):
- **PRIORITY: Create and share interface definitions document**
  * Signal names, widths, timing info
  * Control signal encoding (from ISA sheet)
  * Forwarding signal definitions
- Create ALU skeleton with all operations
- Create Control Unit skeleton (maps opcode to control signals)
- DO NOT implement yet, just structure

#### Person 4 (Pipeline & Integration):
- Design pipeline register structure (widths, what signals pass through each stage)
- Create top-level processor entity skeleton
- Decide on clocking strategy (single clock for all components)
- Plan integration flow

**END OF DAY 1 DELIVERABLE:** Interface definitions locked in, all have skeleton files

---

### 4.2 Days 2-3: Implement Core Modules (Parallel Work)

#### Person 1 (Assembler):
- NOW implement assembler based on finalized interfaces
- Support instructions in priority order:
  * NOP, HLT, SETC (trivial)
  * NOT, INC, OUT, IN (single register)
  * MOV, SWAP (register-to-register)
  * ADD, SUB, AND (three register)
  * IADD (immediate)
  * Later: LDM, LDD, STD, PUSH, POP, CALL, RET, JZ, JN, JC, JMP
- Write 2-3 simple test .asm files
- Generate corresponding .mem files

#### Person 2 (Memory & Registers):
- Implement Memory module (READ/WRITE logic, .mem file loading)
- Implement Register File (basic read/write, no hazard handling yet)
- Add CCR (Condition Code Register) to register file or separate
- Test: Create simple testbench for each
  * Testbench 1: Load .mem file, read a few addresses
  * Testbench 2: Write/read from register file
- Get these WORKING before moving on

#### Person 3 (ALU, Control, Hazard):
- Implement ALU fully:
  * All 8 operations (NOT, INC, MOV, ADD, SUB, AND, Pass, NOP)
  * Generate Z (zero), N (negative), C (carry) flags
  * Output: result, flags
- Implement Control Unit:
  * Input: opcode (5 bits)
  * Output: All 20+ control signals (from ISA sheet)
  * Use a case statement or lookup table
- Test: Create testbenches for ALU with all operations

#### Person 4 (Pipeline & Integration):
- Start integrating Memory + Register File + ALU
- Create IF/ID pipeline register
- Implement Fetch logic (PC increment)
- Test: Can you fetch and increment PC?
- **DO NOT try full pipeline yet, just prove basic fetch works**

**END OF DAY 3 DELIVERABLE:** Core modules (Memory, RegFile, ALU, Control) are implemented and individually testable. Assembler generates first .mem files.

---

### 4.3 Days 4-5: Pipeline Implementation & Hazard Handling

#### Person 1 (Assembler):
- Expand to support more instructions as integration progresses
- Create test .mem files that test:
  * Day 4: Basic arithmetic (ADD, SUB, AND)
  * Day 5: Memory operations (PUSH, POP, LDD, STD)
- Create .do files for each test (script-based testing)

#### Person 2 (Memory & Registers):
- Optimize Memory and RegFile for speed
- Add any forwarding output signals Person 3 needs
- Ensure CCR can be read/written from pipeline
- Support both normal and interrupt-driven access

#### Person 3 (ALU, Control, Hazard):
- Implement Hazard Detection Unit:
  * Detect RAW (Read-After-Write) hazards
  * Detect WAW, WAR (if relevant)
  * Output: stall signal
- Implement Forwarding Unit:
  * Pass through EX/MEM and MEM/WB results to input of ALU
  * Select between original register value vs forwarded value
  * Mux 3-way: normal value, EX/MEM forward, MEM/WB forward
- Test: Hazard testbenches (execute instruction that depends on previous)

#### Person 4 (Pipeline & Integration):
- NOW integrate complete pipeline:
  * Implement all 5 pipeline registers (IF/ID, ID/EX1, EX1/EX2, EX2/MEM, MEM/WB)
  * Connect Fetch → Decode (ID) → EX1 → EX2 → Memory → WriteBack
  * Wire up hazard and forwarding units
  * Implement pipeline flushes (for branches)
- Test with simple programs (no branches yet)
- Focus: Does a sequence of ADD instructions work?

**END OF DAY 5 DELIVERABLE:** Full pipeline implemented, passes simple arithmetic sequences. Hazard detection prevents RAW conflicts. Assembler supports ~12 instructions.

---

### 4.4 Day 6: Branch Handling & Advanced Instructions

#### Person 1 (Assembler):
- Add branch instructions (JZ, JN, JMP, CALL, RET)
- Create test program with branches
- Generate .mem and corresponding .do file

#### Person 2 (Memory & Registers):
- Ensure SP (Stack Pointer) is accessible and modifiable
- Verify PUSH/POP sequences work correctly
- Stack grows downward (SP -= 1 for push)

#### Person 3 (ALU, Control, Hazard):
- Implement Branch Resolution logic
- Implement CALL/RET handling (affects SP, PC)
- Handle conditional branches (JZ, JN, JC)
- Update control unit for branch operations

#### Person 4 (Pipeline & Integration):
- Implement Branch Prediction (or static prediction: always fall-through)
- Implement pipeline flush on branch mispredict
- Connect branch_decision to PC mux
- Test: Programs with branches and jumps

**END OF DAY 6 DELIVERABLE:** Branches work. Programs can jump and return. Assembler supports all major instructions except interrupts.

---

### 4.5 Day 7: Final Integration, Testing & Debugging

#### Person 1 (Assembler):
- Finalize assembler; ensure all instructions generate correct machine code
- Create 3-4 comprehensive test programs covering:
  * Arithmetic and logic
  * Memory operations
  * Branching
  * Interrupt handling (if time)
- Generate .mem files and .do test scripts

#### Person 2 (Memory & Registers):
- Final verification: Can all registers be read/written?
- Verify stack operations work
- Test CCR flag updates

#### Person 3 (ALU, Control, Hazard):
- Verify all control signals are correct for all implemented instructions
- Test hazard detection doesn't over-stall
- Verify forwarding doesn't cause false positives

#### Person 4 (Pipeline & Integration):
- Run comprehensive tests using .mem/.do files
- Debug any remaining issues
- Clean up waveforms (for demo)
- Document any design changes from Phase 1

**END OF DAY 7 DELIVERABLE:** WORKING PROCESSOR  
Passes all test programs. Waveforms show correct behavior. Ready for TA demo.

---

## 5. What to Start Implementing First (Priority Order)

### 5.1 Memory Module (Person 2)

**WHY FIRST:** It's simple, independent, and all tests need it  
**WHAT:** Read/write with address decoding  
**HOW TO TEST:** Load .mem file, verify you can read back data  
**DEPENDENCY:** None  
**ESTIMATE:** 2-3 hours

### 5.2 Register File (Person 2)

**WHY SECOND:** Also independent; tests can't run without register results  
**WHAT:** 8 registers, read two ports, write one port  
**HOW TO TEST:** Write to R1, read back same address  
**DEPENDENCY:** None (can start Day 1)  
**ESTIMATE:** 2-3 hours

### 5.3 ALU (Person 3)

**WHY THIRD:** Pipeline depends on ALU results  
**WHAT:** Implement all operations, compute flags  
**HOW TO TEST:** ALU testbench with known inputs/outputs  
**DEPENDENCY:** None  
**ESTIMATE:** 3-4 hours

### 5.4 Control Unit (Person 3)

**WHY FOURTH:** Once ALU works, map opcodes to control signals  
**WHAT:** Decode 5-bit opcode to 20+ control signals  
**HOW TO TEST:** For each instruction, verify correct control signals output  
**DEPENDENCY:** Finalized interface definitions  
**ESTIMATE:** 2-3 hours

### 5.5 Fetch Stage (Person 4)

**WHY FIFTH:** PC logic is critical to pipeline  
**WHAT:** PC register, PC+1 adder, branch mux  
**HOW TO TEST:** Verify PC increments each cycle; jumps change PC  
**DEPENDENCY:** Partial (PC mux depends on branch decision)  
**ESTIMATE:** 2-3 hours

### 5.6 Pipeline Registers (Person 4)

**WHY SIXTH:** Connect stages together  
**WHAT:** IF/ID, ID/EX1, EX1/EX2, EX2/MEM, MEM/WB registers  
**HOW TO TEST:** Data flow through pipeline (simple instruction sequence)  
**DEPENDENCY:** All stages implemented  
**ESTIMATE:** 3-4 hours

### 5.7 Hazard & Forwarding (Person 3 & 4 Collaboration)

**WHY SEVENTH:** Prevents stalls and data corruption  
**WHAT:** Detect dependencies, forward EX/MEM and MEM/WB results  
**HOW TO TEST:** Back-to-back ADD instructions with dependencies  
**DEPENDENCY:** Full pipeline  
**ESTIMATE:** 3-4 hours

### 5.8 Branch Handling (Person 4)

**WHY EIGHTH:** Control flow critical for real programs  
**WHAT:** Conditional jump logic, pipeline flush, CALL/RET  
**HOW TO TEST:** Branch test program (.mem file)  
**DEPENDENCY:** Full pipeline with hazard handling  
**ESTIMATE:** 2-3 hours

### 5.9 Interrupts (Person 3 & 4)

**WHY LAST:** Complex; skip if time-constrained  
**WHAT:** INT/RTI, interrupt vector handling  
**HOW TO TEST:** Interrupt test program  
**DEPENDENCY:** Everything else  
**ESTIMATE:** 3-4 hours (OPTIONAL)

---

## 6. How to Integrate Components (The Right Way)

### 6.1 Integration Sequence

#### Step 1: Memory + RegFile (Day 2-3)
- Create simple test: Write to register, read back same value
- Create simple test: Load .mem file, read instruction from memory
- Both must pass before proceeding

#### Step 2: Add ALU (Day 3)
- Wire Memory output → Control Unit input
- Wire Control Unit output → ALU control lines
- Wire ALU output to register file write port
- Test: Memory → Control → ALU → RegFile loop
- Test program: Load instruction, execute, store result

#### Step 3: Add Fetch Stage (Day 4)
- Wire PC to memory address port
- Wire PC+1 adder output to PC register
- Wire IF/ID register between fetch and decode
- Test: PC increments; instructions fetched sequentially

#### Step 4: Add IF/ID Pipeline Register (Day 4)
- Instruction flows from memory through IF/ID to decode stage
- Test: Fetch two instructions, verify both are in pipeline correctly

#### Step 5: Add ID/EX1, EX1/EX2 Pipeline Registers (Day 4)
- Decode outputs flow through these registers
- Control signals propagate through pipeline
- Test: Can still execute instructions correctly

#### Step 6: Add EX2/MEM, MEM/WB Pipeline Registers (Day 4-5)
- ALU results stored in pipeline
- Memory access happens in MEM stage
- Results written back in WB stage
- Test: Full 6-stage pipeline executes one instruction

#### Step 7: Add Hazard Detection & Forwarding (Day 5)
- Hazard Unit reads pipeline stages, detects RAW dependencies
- Forwarding Unit passes EX/MEM and MEM/WB results to ALU input mux
- Test program: ADD R1, R2, R3 followed by ADD R4, R1, R5
  * R1 not yet written when second instruction reads it
  * Forwarding unit should provide correct value from pipeline
  * If no forwarding: stall signal delays second instruction

#### Step 8: Add Branch Logic (Day 5-6)
- Condition evaluation in EX2 stage (JZ, JN, JC conditions)
- PC mux selects between PC+1 and branch target
- Pipeline flush on branch misprediction
- Test program: Conditional jump that depends on previous instruction

#### Step 9: Add CALL/RET Support (Day 6)
- CALL: Push PC+1 to stack (SP -= 1)
- RET: Pop return address from stack (SP += 1)
- Test: Function call and return

#### Step 10: Add Interrupt Support (Day 6-7, if time)
- INT: Push PC+1, jump to interrupt vector
- RTI: Restore PC from stack
- Test: Simple interrupt program

---

## 7. Understanding .mem Files & How to Use Them

### 7.1 What Is a .mem File?

- A file that initializes memory (RAM) in simulation
- Each line = one 32-bit word
- Format: 32 bits in binary OR 8 hex digits
- ModelSim reads this file during simulation startup

### 7.2 Example .mem File (Binary Format)

```
00000000000000000000000000000001  (NOP instruction, opcode = 00000)
00000000000000000000000000000010  (HLT instruction, opcode = 00001)
11010101010101010101010101010101  (Some other instruction)
```

### 7.3 Example .mem File (Hex Format - Preferred)

```
00000001
00000002
D5555555
```

### 7.4 How Your Assembler Generates .mem Files

**Input assembly:**
```
NOP
HLT
ADD R1, R2, R3
```

**Assembler output (.mem file):**
```
00000000  (NOP)
00000001  (HLT)
01001001  (ADD, with register encoding)
...
```

### 7.5 How ModelSim Loads .mem Files

In VHDL code:
```vhdl
PROCEDURE init_mem IS
  FILE mem_file : TEXT;
  VARIABLE line : STRING(1 TO 256);
  VARIABLE addr : INTEGER := 0;
BEGIN
  FILE_OPEN(mem_file, "memory_init.mem", READ_MODE);
  WHILE NOT ENDFILE(mem_file) LOOP
    READLINE(mem_file, line);
    memory(addr) := ... parse line ...
    addr := addr + 1;
  END LOOP;
  FILE_CLOSE(mem_file);
END init_mem;
```

---

## 8. Understanding .do Files (Simulation Scripts)

### 8.1 What Is a .do File?

- A script that automates ModelSim commands
- Eliminates manual clicking; fully automated testing
- Runs: compile, load, initialize, clock cycles, display waveform, assertions

### 8.2 Example .do File

```tcl
# Compile VHDL files
vcom -93 memory.vhd
vcom -93 regfile.vhd
vcom -93 alu.vhd
vcom -93 control_unit.vhd
vcom -93 processor.vhd
vcom -93 testbench.vhd

# Load testbench
vsim -gui work.testbench

# Load memory file
mem load -infile test_program_1.mem /testbench/processor_inst/memory_inst/memory_array

# Reset processor
force /testbench/clk 0
force /testbench/reset 1
run 1 ns
force /testbench/reset 0

# Run for N clock cycles
force /testbench/clk 1
run 10 ns
force /testbench/clk 0
run 10 ns

# Repeat above for 20 cycles:
for {set i 0} {$i < 20} {incr i} {
  force /testbench/clk 1
  run 10 ns
  force /testbench/clk 0
  run 10 ns
}

# Display waveform
wave zoom full
run 1 us

# Add signals to waveform
add wave /testbench/clk
add wave /testbench/reset
add wave /testbench/processor_inst/pc
add wave /testbench/processor_inst/registers
add wave /testbench/processor_inst/alu_result
add wave /testbench/processor_inst/ccr

# Run until halt
run 1 us

# Assertion: Check final register state
if {[examine /testbench/processor_inst/registers/reg_file(1)] != 10} {
  puts "ERROR: R1 should be 10, but is [examine /testbench/processor_inst/registers/reg_file(1)]"
}
```

### 8.3 How to Use .do Files

1. Create file: test_add.do (contains above script)
2. In ModelSim command prompt: "do test_add.do"
3. Simulation runs automatically; waveform displayed; assertions checked
4. No manual clicking = faster debugging

---

## 9. Components to Code (With VHDL Structure)

### 9.1 Component 1: Memory

```vhdl
entity Memory is
  port (
    clk : in std_logic;
    rst : in std_logic;
    addr : in std_logic_vector(11 downto 0);  -- 4KB = 2^12 locations
    data_in : in std_logic_vector(31 downto 0);
    write_enable : in std_logic;
    read_enable : in std_logic;
    data_out : out std_logic_vector(31 downto 0)
  );
end Memory;
```

#### What This Does
- Stores 4096 x 32-bit words
- Reads asynchronously (combinatorial: no clock delay)
- Writes synchronously (updates on clock edge)
- Loads initial state from .mem file

#### Key Decisions
- Single port or dual-port? **(SINGLE PORT is simpler for 1 week)**
- Synchronous or asynchronous writes? **(SYNCHRONOUS is standard)**
- How to load .mem file? **(Use VHDL file I/O in initialization)**

---

### 9.2 Component 2: Register File

```vhdl
entity RegisterFile is
  port (
    clk : in std_logic;
    rst : in std_logic;
    read_addr1 : in std_logic_vector(2 downto 0);   -- 3 bits for R0-R7
    read_addr2 : in std_logic_vector(2 downto 0);
    write_addr : in std_logic_vector(2 downto 0);
    write_data : in std_logic_vector(31 downto 0);
    write_enable : in std_logic;
    read_data1 : out std_logic_vector(31 downto 0);
    read_data2 : out std_logic_vector(31 downto 0)
  );
end RegisterFile;
```

#### What This Does
- Stores 8 x 32-bit registers (R0-R7)
- Reads two ports asynchronously
- Writes one port synchronously
- Special case: R0 is always 0 (hardwired)

#### Key Decisions
- Should SP be part of RegisterFile or separate? **(SEPARATE is cleaner)**
- Asynchronous reads or synchronous? **(ASYNCHRONOUS for speed)**
- How to handle forwarding? **(Do this at mux level, not in RegFile)**

---

### 9.3 Component 3: ALU

```vhdl
entity ALU is
  port (
    operand1 : in std_logic_vector(31 downto 0);
    operand2 : in std_logic_vector(31 downto 0);
    alu_op : in std_logic_vector(2 downto 0);  -- 3 bits for 8 operations
    result : out std_logic_vector(31 downto 0);
    flags_out : out std_logic_vector(3 downto 0)  -- Z, N, C, ...
  );
end ALU;
```

#### ALU_OP Codes (from ISA sheet)
- 000 = NOP (pass through operand1)
- 001 = NOT
- 010 = INC
- 011 = MOV (pass operand1)
- 100 = ADD
- 101 = SUB
- 110 = AND
- 111 = Pass operand1

#### FLAGS
- flags_out(0) = Z (zero flag)
- flags_out(1) = N (negative flag)
- flags_out(2) = C (carry flag)
- flags_out(3) = unused

#### What This Does
- Performs arithmetic/logical operations
- Computes condition flags (Z, N, C)
- Combinatorial (no clock): output available same cycle as input

#### Key Decisions
- Carry generation for ADD/SUB? **(Use VHDL overflow detection)**
- Flag generation timing? **(Combinatorial: output flags same cycle)**
- All operations, or subset? **(START WITH SUBSET: NOT, INC, MOV, ADD, SUB, AND)**

---

### 9.4 Component 4: Control Unit

```vhdl
entity ControlUnit is
  port (
    opcode : in std_logic_vector(4 downto 0);
    alu_src : out std_logic;
    alu_op : out std_logic_vector(2 downto 0);
    ccr_sel : out std_logic_vector(2 downto 0);
    branch_op : out std_logic_vector(3 downto 0);
    reg_write : out std_logic;
    reg_data : out std_logic_vector(2 downto 0);
    mem_write : out std_logic;
    mem_read : out std_logic;
    ... (many more control signals from ISA sheet)
  );
end ControlUnit;
```

#### What This Does
- Decodes 5-bit opcode
- Outputs 20+ control signals (from ISA sheet)
- Combinatorial: control signals available immediately

#### Key Decisions
- Use case statement or lookup table? **(CASE STATEMENT is cleaner)**
- All signals or subset? **(ONLY SIGNALS YOU IMPLEMENT INSTRUCTIONS FOR)**
- How to handle unimplemented instructions? **(Drive all outputs to 0 / NOP)**

---

### 9.5 Component 5: Pipeline Registers

```vhdl
entity PipelineReg_IF_ID is
  port (
    clk : in std_logic;
    rst : in std_logic;
    enable : in std_logic;
    instruction_in : in std_logic_vector(31 downto 0);
    pc_in : in std_logic_vector(31 downto 0);
    instruction_out : out std_logic_vector(31 downto 0);
    pc_out : out std_logic_vector(31 downto 0)
  );
end PipelineReg_IF_ID;
```

#### Pattern For All Pipeline Registers
- Each is a simple register with enable and reset
- IF/ID: passes instruction and PC from fetch to decode
- ID/EX1: passes registers, immediate, control signals to EX1
- EX1/EX2: passes ALU result, operands, control signals to EX2
- EX2/MEM: passes ALU result, address, data to MEM stage
- MEM/WB: passes ALU result, memory data to WB stage

#### Key Decisions
- What signals pass through each stage? **(Defined in interface doc)**
- Width of each register? **(Varies by stage)**
- Enable or always update? **(ENABLE: hazard control uses this)**

---

### 9.6 Component 6: Hazard Detection Unit

```vhdl
entity HazardDetection is
  port (
    id_rs1 : in std_logic_vector(2 downto 0);      -- Decode stage source reg 1
    id_rs2 : in std_logic_vector(2 downto 0);      -- Decode stage source reg 2
    ex_rd : in std_logic_vector(2 downto 0);       -- EX stage destination
    ex_reg_write : in std_logic;                    -- EX stage write enable
    mem_rd : in std_logic_vector(2 downto 0);      -- MEM stage destination
    mem_reg_write : in std_logic;                   -- MEM stage write enable
    stall : out std_logic;                          -- 1 = stall pipeline
    flush : out std_logic
  );
end HazardDetection;
```

#### What This Does
- Detects Read-After-Write (RAW) hazards
- If ID stage needs register that EX or MEM is writing: stall = 1
- Stall pauses ID/EX1 register (instruction doesn't advance)
- Next cycle: forwarding unit provides correct value

#### Example RAW Hazard
```
Cycle 1: ADD R1, R2, R3      (ID stage: will write R1)
Cycle 2: ADD R4, R1, R5      (ID stage: needs R1)
         ↑ R1 not yet available; must stall
```

#### Key Decisions
- Detect all types of hazards or just RAW? **(RAW only is 80% of solution)**
- Stall or forward? **(BOTH: forward when possible, stall when necessary)**

---

### 9.7 Component 7: Forwarding Unit

```vhdl
entity ForwardingUnit is
  port (
    ex_rs1 : in std_logic_vector(2 downto 0);
    ex_rs2 : in std_logic_vector(2 downto 0);
    mem_rd : in std_logic_vector(2 downto 0);
    mem_reg_write : in std_logic;
    wb_rd : in std_logic_vector(2 downto 0);
    wb_reg_write : in std_logic;
    forward_a : out std_logic_vector(1 downto 0);  -- 00=normal, 01=mem, 10=wb
    forward_b : out std_logic_vector(1 downto 0)
  );
end ForwardingUnit;
```

#### What This Does
- Compares EX stage operands (rs1, rs2) against MEM and WB stage writes
- If match: forward signal tells ALU mux to use forwarded value instead
- Reduces stalls; allows back-to-back dependent instructions

#### Forwarding Cases
- **Case 1:** EX stage needs value being written in MEM stage
  * `forward_a = "01"` (select MEM result)
- **Case 2:** EX stage needs value being written in WB stage
  * `forward_a = "10"` (select WB result)
- **Case 3:** Both MEM and WB match (shouldn't happen, take most recent)
  * `forward_a = "01"` (MEM is more recent)

#### Key Decisions
- Forward at ALU input (mux before ALU) or pipeline register?
  * **(BEFORE ALU is faster; updates result same cycle)**

---

### 9.8 Component 8: Top-Level Processor

```vhdl
entity Processor is
  port (
    clk : in std_logic;
    rst : in std_logic;
    interrupt : in std_logic;
    input_port : in std_logic_vector(31 downto 0);
    output_port : out std_logic_vector(31 downto 0);
    halt : out std_logic
  );
end Processor;
```

#### What This Does
- Instantiates all components above
- Wires them together
- Manages top-level signals (clk, rst, halt)

#### Instantiation Pattern
```vhdl
memory_inst : entity work.Memory port map (
  clk => clk,
  rst => rst,
  addr => mem_addr,
  data_in => mem_data_in,
  write_enable => mem_write,
  read_enable => mem_read,
  data_out => mem_data_out
);

regfile_inst : entity work.RegisterFile port map (
  clk => clk,
  read_addr1 => reg_read_addr1,
  ...
);

... (etc for ALU, Control, Hazard, Forwarding, etc.)
```

---

## 10. Testing Strategy (How to Verify Each Component)

### 10.1 Phase 1: Unit Testing (Test Each Component in Isolation)

#### Test 1: Memory Module
- .mem file: Write some values (e.g., 0x12345678 at addr 0, 0xABCDEF00 at addr 1)
- Test steps:
  1. Reset memory
  2. Read addr 0, verify data = 0x12345678
  3. Read addr 1, verify data = 0xABCDEF00
  4. Write 0xDEADBEEF to addr 2
  5. Read addr 2, verify write successful
- Expected: All reads match expectations

#### Test 2: Register File
- Test steps:
  1. Write 0x11111111 to R1
  2. Read R1 (port 1), verify = 0x11111111
  3. Write 0x22222222 to R2
  4. Read both R1 and R2 simultaneously, verify both correct
  5. Verify R0 always reads as 0 (hardwired)
- Expected: All reads match expected values

#### Test 3: ALU
- Test cases:
  * ADD: 5 + 3 = 8, Z=0, N=0, C=0
  * ADD: (-1) + 1 = 0, Z=1, N=0, C=1 (carry set for 32-bit overflow)
  * SUB: 10 - 3 = 7, Z=0, N=0, C=0
  * AND: 0xFFFF & 0x0F0F = 0x0F0F, Z=0, N=0, C=0
  * NOT: NOT(0xFFFFFFFF) = 0x00000000, Z=1, N=0
  * INC: 5+1=6, Z=0, N=0
- Expected: All results and flags match expected values

#### Test 4: Control Unit
- For each instruction opcode:
  * Input: opcode (5 bits)
  * Output: Should match ISA sheet control signal encoding
  * Example: opcode = 01001 (ADD) → alu_op = 100, reg_write = 1, etc.
- Expected: All control signals match ISA sheet

### 10.2 Phase 2: Integration Testing (Test Components Working Together)

#### Test 5: Memory + RegFile + ALU + Control
- Instruction: ADD R1, R2, R3
- Setup: R2 = 5, R3 = 3
- Steps:
  1. Fetch instruction from memory
  2. Decode: opcode = 01001
  3. Control unit outputs: alu_op = 100 (ADD)
  4. ALU reads R2 and R3, computes 5+3=8
  5. Result 8 written to R1
- Expected: R1 = 8 after instruction

#### Test 6: Pipeline Fetch-Decode-Execute
- Program (4 instructions):
  ```
  Inst 0: ADD R1, R2, R3
  Inst 1: ADD R4, R5, R6
  Inst 2: ADD R7, R1, R4  (depends on Inst 0 and 1)
  Inst 3: NOP
  ```
- Steps:
  1. Run 20 clock cycles
  2. Verify PC increments each cycle (Inst 0→1→2→3)
  3. Verify each instruction executes in correct stage at correct time
- Expected:
  ```
  Cycle 1: Inst 0 in IF stage
  Cycle 2: Inst 0 in ID stage, Inst 1 in IF stage
  ...
  Cycle 5: Inst 0 in WB stage, Inst 1 in EX2, Inst 2 in EX1, Inst 3 in ID, next in IF
  ```

#### Test 7: Hazard Detection & Forwarding
- Program:
  ```
  Inst 0: ADD R1, R2, R3
  Inst 1: ADD R4, R1, R5     (reads R1, written by Inst 0)
  ```
- Steps:
  1. Run until Inst 1 is in EX stage
  2. Verify: Either stall OR forwarding provides correct R1 value (result of Inst 0)
  3. Verify final R4 = (R2+R3) + R5
- Expected:
  * **Option A:** Stall in cycle 3 (Inst 1 pauses until R1 available)
  * **Option B:** Forward in cycle 3 (Inst 1 proceeds with forwarded R1 value)

#### Test 8: Branches
- Program:
  ```
  Inst 0: ADD R1, R2, R3     (produces result, sets flags)
  Inst 1: JZ target_addr     (jump if result was zero)
  ```
- If R2+R3 = 0:
  * Expected: PC jumps to target_addr
- If R2+R3 ≠ 0:
  * Expected: PC continues to next instruction

### 10.3 Phase 3: System Testing (Full Processor with Real Programs)

#### Test 9: Comprehensive Test Program 1
- Program: Sum of array
  ```
  Initialize: R1 = array start address, R2 = array size, R3 = 0 (sum)
  Loop: Load word, add to sum, increment pointer, check if done
  Result: R3 should contain sum of all array values
  ```

#### Test 10: Comprehensive Test Program 2
- Program: Function call and return
  ```
  Call function (CALL), pass parameter in R1
  Function: Square value, return in R1
  Back in main: Use result
  Result: R1 should contain squared value
  ```

#### Test 11: Comprehensive Test Program 3
- Program: Mixed instruction types
  * Arithmetic, memory, branches, all together
  * Stress-test the entire pipeline
  * Result: Final state should match expected register values

---

## 11. VHDL Coding Best Practices for This Project

### 11.1 File Organization

Each component in separate file:
```
memory.vhd
regfile.vhd
alu.vhd
control_unit.vhd
fetch_stage.vhd
pipeline_regs.vhd
hazard_unit.vhd
forwarding_unit.vhd
processor_top.vhd
testbench.vhd
```

**Benefits:** Easier to divide work, merge later, cleaner codebase

### 11.2 Naming Conventions

#### Signals
- **Good:** `data_out`, `address`, `write_enable` (lowercase, underscores)
- **Avoid:** `dout`, `DataOut`, `d_out` (inconsistent), `wr_en` (too abbreviated), `sig_data` (unnecessary prefix)

#### Generics/Constants
```vhdl
REG_WIDTH : INTEGER := 32;
NUM_REGS : INTEGER := 8;
MEM_SIZE : INTEGER := 4096;
```

### 11.3 Comments and Documentation

- Every port: explain what it does
- Every process: explain logic
- Every signal: explain purpose

**GOOD:**
```vhdl
-- Selects ALU operand 2: immediate or register value
-- 0 = use register, 1 = use immediate (sign-extended)
alu_src : in std_logic;
```

**BAD:**
```vhdl
alu_src : in std_logic;  -- source
```

### 11.4 VHDL Style

- Use `std_logic_vector`, not `bit_vector`
- Use `std_logic`, not `bit`
- Use `others => '0'` for initialization
- Use `rising_edge(clk)`, not `clk'event and clk='1'`

**GOOD:**
```vhdl
process(clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      counter <= (others => '0');
    else
      counter <= counter + 1;
    end if;
  end if;
end process;
```

**BAD:**
```vhdl
process(clk)
begin
  if clk'event and clk='1' then
    if rst = '1' then
      counter <= "00000000";
    else
      counter <= counter + 1;
    end if;
  end if;
end process;
```

### 11.5 Avoid Latches (Critical)

Latches occur when not all branches of if/case assign outputs. Result: Unpredictable synthesis, simulation doesn't match hardware

**BAD (creates latches):**
```vhdl
process(a, b)
begin
  if a = '1' then
    output <= b;
  end if;
end process;
-- What happens when a='0'? Synthesizer infers latch
```

**GOOD (combinatorial):**
```vhdl
process(a, b)
begin
  if a = '1' then
    output <= b;
  else
    output <= '0';
  end if;
end process;
```

**GOOD (fully specified):**
```vhdl
output <= b when a = '1' else '0';
```

### 11.6 Reset Signals

All sequential logic must have reset condition:
```vhdl
if rst = '1' then
  signal <= (others => '0');  -- or initial value
elsif rising_edge(clk) then
  signal <= next_value;
end if;
```

**Benefits:** Simulation consistency, hardware reset behavior

### 11.7 Clock Distribution

- Single global clock input to all registers
- No derived clocks (no clock dividers unless necessary)
- All clocking statements: `if rising_edge(clk)`

### 11.8 Testbench Structure

Create separate testbench entity. Instantiate component under test. Generate clock with process. Apply test inputs. Check outputs.

**TEMPLATE:**
```vhdl
entity testbench is
end testbench;

architecture behavioral of testbench is
  signal clk, rst : std_logic := '0';
  signal input : std_logic_vector(7 downto 0);
  signal output : std_logic_vector(7 downto 0);
begin
  -- Clock generation: 50% duty cycle, period = 20 ns
  process
  begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
  end process;

  -- DUT (Device Under Test)
  dut : entity work.MyModule port map (
    clk => clk, rst => rst, input => input, output => output
  );

  -- Stimulus
  process
  begin
    rst <= '1';
    wait for 30 ns;
    rst <= '0';
    wait for 10 ns;

    -- Test case 1
    input <= "00000001";
    wait for 20 ns;
    assert output = "00000010" report "Test 1 failed" severity ERROR;

    -- Test case 2
    input <= "00000010";
    wait for 20 ns;
    assert output = "00000100" report "Test 2 failed" severity ERROR;

    wait;
  end process;
end architecture;
```

### 11.9 Assertions in Testbench

Automatically check expected values. Helps catch bugs quickly.

**EXAMPLE:**
```vhdl
assert output = expected
  report "Output mismatch: got " & integer'image(to_integer(output)) &
         ", expected " & integer'image(to_integer(expected))
  severity ERROR;
```

### 11.10 Debugging Common Issues

#### Issue: Signal is 'X' (undefined)
- **Cause:** Reset missing or not initialized
- **Fix:** Add reset statement, initialize to '0' or specific value

#### Issue: Signal is 'U' (uninitialized)
- **Cause:** No default value in process
- **Fix:** Assign all branches of if/case

#### Issue: Synthesis fails with "latch inferred"
- **Cause:** Missing else clause in combinatorial logic
- **Fix:** Add else clause or use when/else statement

#### Issue: Simulation works, hardware doesn't
- **Cause:** Timing violations, setup/hold violations, or asynchronous reset issues
- **Fix:** Use synchronous logic, ensure proper reset strategy

---

## 12. .mem File Generation (For Assembler Developer)

### 12.1 Your Assembler Must Output

- One 32-bit instruction per line
- Format: 8 hex digits (preferred) OR 32 binary bits
- Example for ADD R1, R2, R3:
  * Opcode (bits 31:27): 01001
  * Rdst (bits 26:24): 001 (R1)
  * Rsrc1 (bits 23:21): 010 (R2)
  * Rsrc2 (bits 20:18): 011 (R3)
  * Unused (bits 17:0): 000...0
  * Full: 01001001010011000000000000000000 (binary)
  * = 24CC0000 (hex)
  * Output line: 24CC0000

### 12.2 Assembler Algorithm

1. Read assembly file line by line
2. Parse instruction (mnemonic + operands)
3. Look up opcode from ISA encoding table
4. Encode operands (register addresses, immediates, offsets)
5. Combine opcode + operands into 32-bit word
6. Convert to hex
7. Write to .mem file

### 12.3 Example Assembler (Pseudo-code)

```python
function assemble(asm_file):
  mem_file = open("output.mem", "write")
  addr = 0

  for each line in asm_file:
    line = line.strip()
    if line.empty() or line.startswith("#"):
      continue  -- skip empty lines and comments

    tokens = line.split()
    mnemonic = tokens[0]

    -- Look up instruction encoding
    instr = lookup_instruction(mnemonic)
    opcode = instr.opcode

    if mnemonic == "NOP":
      machine_code = opcode
    elif mnemonic == "ADD":
      rdst = encode_register(tokens[1])    -- R1 → 001
      rsrc1 = encode_register(tokens[2])   -- R2 → 010
      rsrc2 = encode_register(tokens[3])   -- R3 → 011
      machine_code = opcode << 27 | rdst << 24 | rsrc1 << 21 | rsrc2 << 18
    elif mnemonic == "MOV":
      rdst = encode_register(tokens[1])
      rsrc = encode_register(tokens[2])
      machine_code = opcode << 27 | rdst << 24 | rsrc << 21
    elif mnemonic == "LDM":
      rdst = encode_register(tokens[1])
      imm = decode_immediate(tokens[2])
      machine_code = opcode << 27 | rdst << 24 | imm
    ... (etc for all instructions)

    hex_value = format(machine_code, "08X")  -- 8 hex digits
    mem_file.write(hex_value + "\n")
    addr += 1

  mem_file.close()
  print(f"Generated {addr} instructions in output.mem")
```

### 12.4 Testing Your Assembler

**Input assembly:**
```
NOP
ADD R1, R2, R3
MOV R4, R1
```

**Output .mem:**
```
00000000  (NOP, opcode 00000, all zeros)
24CC0000  (ADD R1, R2, R3)
238C0000  (MOV R4, R1)
```

**Verify** each line with ISA encoding table

---

## 13. Debugging .do Files (Common Issues)

### 13.1 Issue 1: "Error: Can't find file 'memory.vhd'"

- **CAUSE:** .do file run from wrong directory
- **FIX:** Use absolute paths, or change directory in .do file
  ```tcl
  cd C:/your/project/path
  vcom -93 memory.vhd
  ```

### 13.2 Issue 2: Memory not loading from .mem file

- **CAUSE:** Wrong path or file format
- **FIX:** Verify .mem file exists and has correct format
  * Each line: 8 hex digits or 32 binary bits
  * No extra spaces or comments
  * Check path is absolute or relative to simulation directory

### 13.3 Issue 3: Signals show 'X' or 'U' in waveform

- **CAUSE:** Not initialized
- **FIX:** Add force statements in .do file
  ```tcl
  force /testbench/clk 0
  force /testbench/reset 1
  run 1 ns
  force /testbench/reset 0
  run 1 ns
  ```

### 13.4 Issue 4: Simulation runs forever or hangs

- **CAUSE:** No "run" statement or incorrect timing
- **FIX:** Add explicit time bounds
  ```tcl
  run 10 us   -- Run for 10 microseconds
  or
  run 1000 ns  -- Run for 1000 nanoseconds
  ```

### 13.5 Issue 5: Assertions don't trigger

- **CAUSE:** Assertions only print to transcript, not automatic fail
- **FIX:** Check ModelSim transcript window for assertion messages
  ```tcl
  Add explicit echo statements:
  echo "Test 1: R1 should be 10"
  echo "Test 1: R1 is [examine /path/to/r1]"
  ```

---

## 14. Final Checklist (End of Week 7)

### 14.1 Before Demo, Verify

#### Memory Module
- ☐ Loads .mem file correctly
- ☐ Read/write working
- ☐ Single-cycle latency
- ☐ No warnings in synthesis

#### Register File
- ☐ All 8 registers (R0-R7) accessible
- ☐ R0 hardwired to 0
- ☐ Read/write working
- ☐ No latches inferred

#### ALU
- ☐ All implemented operations produce correct results
- ☐ Flags (Z, N, C) calculated correctly
- ☐ Combinatorial (no registers inside)
- ☐ No latches

#### Control Unit
- ☐ All implemented instructions produce correct control signals
- ☐ Matches ISA sheet encodings
- ☐ Unimplemented instructions produce NOP signals
- ☐ Combinatorial

#### Fetch Stage
- ☐ PC increments each cycle
- ☐ Branches change PC correctly
- ☐ PC reset to M[0] on reset signal
- ☐ Synchronous updates

#### Pipeline Registers
- ☐ IF/ID passes instruction and PC
- ☐ ID/EX1 passes operands and control signals
- ☐ EX1/EX2 passes ALU result
- ☐ EX2/MEM passes memory address
- ☐ MEM/WB passes data to write back
- ☐ All synchronous (clock-driven)

#### Hazard Detection
- ☐ Detects RAW dependencies
- ☐ Stalls pipeline when needed
- ☐ Doesn't stall unnecessarily
- ☐ No false positives

#### Forwarding
- ☐ Passes EX/MEM results to ALU input
- ☐ Passes MEM/WB results to ALU input
- ☐ Selects correct value in priority (MEM before WB)
- ☐ Mux logic correct

#### Processor Top-Level
- ☐ All components instantiated
- ☐ All signals connected
- ☐ Clock distributed to all registers
- ☐ Reset distributed to all registers
- ☐ Compiles without errors
- ☐ Compiles without unresolved references

#### Testbench
- ☐ Instantiates processor
- ☐ Generates clock correctly
- ☐ Applies reset signal
- ☐ Loads .mem file

#### Test Programs
- ☐ Assembler produces correct .mem files
- ☐ .mem files load without errors
- ☐ Each test program runs to completion
- ☐ Results match expected values for at least 6 basic instructions

#### Waveforms
- ☐ Shows clock, reset, halt
- ☐ Shows PC and all registers (R0-R7, SP)
- ☐ Shows instruction in each pipeline stage
- ☐ Shows control signals
- ☐ Shows memory addresses and data
- ☐ Clean (no clutter, easy to read)
- ☐ Demonstrates pipeline operation (6 stages visible)

#### Documentation
- ☐ Phase 1 design changes documented (if any)
- ☐ Hazards handled documented (which hazards, how solved)
- ☐ Instructions implemented list
- ☐ Known limitations documented (if any instructions skipped)

#### Code Quality
- ☐ No latches inferred
- ☐ No unresolved references
- ☐ No undefined signals
- ☐ All resets properly handled
- ☐ Comments explain complex logic
- ☐ Consistent naming conventions

#### Demo Readiness
- ☐ Can load a test program from .mem file
- ☐ Can run simulation from .do file
- ☐ Can show waveform with main signals
- ☐ Can explain what each signal means
- ☐ Can identify which stage each instruction is in
- ☐ Can explain pipeline flow
- ☐ Can explain hazard solution
- ☐ Can explain forwarding solution

---

## 15. Summary: One Week Schedule At a Glance

### 15.1 Day 1 (Monday): Interfaces & Skeletons

**All:**
- Define component interfaces and signal encoding

**Person 1 (Assembler):**
- Plan assembler, study ISA encoding

**Person 2 (Memory & Registers):**
- Code Memory and RegFile entities (skeleton only)

**Person 3 (ALU, Control, Hazard):**
- Code ALU and Control Unit entities (skeleton only)

**Person 4 (Pipeline & Integration):**
- Code pipeline register entities (skeleton)

---

### 15.2 Days 2-3 (Tuesday-Wednesday): Core Implementation

**Person 1 (Assembler):**
- Implement assembler; generate first test .mem files

**Person 2 (Memory & Registers):**
- Implement and test Memory and RegFile

**Person 3 (ALU, Control, Hazard):**
- Implement and test ALU and Control Unit

**Person 4 (Pipeline & Integration):**
- Implement fetch stage, start basic pipeline integration

---

### 15.3 Days 4-5 (Thursday-Friday): Pipeline & Hazards

**Person 1 (Assembler):**
- Add more instructions to assembler; generate .mem files

**Person 2 (Memory & Registers):**
- Optimize, add forwarding signals if needed

**Person 3 (ALU, Control, Hazard):**
- Implement hazard detection and forwarding units

**Person 4 (Pipeline & Integration):**
- Complete pipeline register integration; test full pipeline

---

### 15.4 Day 6 (Saturday, if needed): Branches

**All:**
- Integrate branch handling; test with branch programs
- Debug pipeline issues

**Person 1 (Assembler):**
- Add branch instructions to assembler

---

### 15.5 Day 7 (Sunday, if needed): Final Integration

**All:**
- Final integration and comprehensive testing
- Create .do files for all test programs
- Generate clean waveforms for demo
- Document any Phase 1 changes and design decisions

---

### 15.6 SUBMIT (End of Week 14)

- All VHDL files
- All test .mem files
- All test .do files
- Report: Design changes from Phase 1
- Report: Hazards handled and solutions
- Report: Instruction implementation status
- Waveforms (PNG or PDF) showing successful execution

---

## END OF GUIDE