# Team 10 Assembler

This assembler converts a Team 10 assembly text file into a plain text `program.mem` file for the processor RAM simulation.

The project requires an assembler that converts an assembly program text file into a machine-code memory file. This implementation follows Team 10's 32-bit instruction format and opcode table.

---

## File structure

```text
assembler/
│
├── assembler.py          # Main assembler code
├── README.md             # How to use the assembler
├── test.asm              # Example assembly program
└── program.mem           # Generated output, created in this same/root folder
```

There is **no output folder**. The generated `program.mem` appears directly in the root folder where you run the assembler.

---

## How to run

Open a terminal in the assembler folder, then run:

```bash
python assembler.py test.asm
```

This generates:

```text
program.mem
```

To choose another output name:

```bash
python assembler.py test.asm -o my_program.mem
```

To also generate a binary debug file:

```bash
python assembler.py test.asm --bin
```

That creates:

```text
program.mem
program.bin
```

To force the memory file to contain the full 4096 words:

```bash
python assembler.py test.asm --fill-to 4096
```

---

## Output format

`program.mem` is plain text.

Each line is one 32-bit memory word written as 8 hex digits.

Example:

```text
00000004
00000000
00000000
00000000
79000005
08000000
```

Meaning:

| Line | Memory address | Meaning |
|---:|---:|---|
| 0 | `M[0]` | Reset/start PC |
| 1 | `M[1]` | Hardware interrupt ISR address |
| 2 | `M[2]` | Software INT 0 ISR address |
| 3 | `M[3]` | Software INT 1 ISR address |
| 4 | `M[4]` | First real instruction by default |

---

## Default memory layout

The assembler reserves the first four memory words:

```text
M[0] = reset/start address
M[1] = hardware interrupt ISR address
M[2] = software INT 0 ISR address
M[3] = software INT 1 ISR address
```

Normal code starts at address `4` by default.

If you write a label named `START`, then `M[0]` automatically points to it.

Example:

```asm
START:
    LDM R1, 5
    HLT
```

The assembler will put:

```text
M[0] = 4
```

because `START` is at address `4`.

---

## Vector directives

You can manually set vectors using `.vector`.

```asm
.vector reset START
.vector hw_int HW_ISR
.vector int0 ISR0
.vector int1 ISR1

START:
    INT 0
    HLT

ISR0:
    RTI

ISR1:
    RTI

HW_ISR:
    RTI
```

Accepted vector names:

```text
reset, start
hw, hw_int, hardware
int0, sw_int0
int1, sw_int1
```

---

## Supported comments

You can write comments using `;` or `#`.

```asm
LDM R1, 5      ; this is a comment
ADD R2, R1, R1 # this is also a comment
```

---

## Supported number formats

The assembler supports decimal, negative decimal, hexadecimal, and binary.

```asm
LDM R1, 10       ; decimal
LDM R1, -1       ; signed decimal -> encoded as FFFF
LDM R1, 0xFFFF   ; unsigned hex -> encoded as FFFF
LDM R1, 0b1010   ; binary -> encoded as 000A
```

### Signed and unsigned behavior

Immediate fields are 16-bit.

The assembler accepts:

```text
-32768 to -1       signed values
0 to 65535         unsigned values
```

Examples:

| Assembly value | Encoded 16-bit value |
|---:|---:|
| `5` | `0005` |
| `-1` | `FFFF` |
| `-2` | `FFFE` |
| `0xFFFF` | `FFFF` |

Use negative values for sign-extended immediates/offsets.

Use labels or positive values for addresses.

---

## Labels

Labels are supported.

```asm
START:
    LDM R1, 3

LOOP:
    IADD R1, R1, -1
    JZ DONE
    JMP LOOP

DONE:
    HLT
```

The assembler automatically converts `LOOP` and `DONE` into memory addresses.

---

## Directives

### `.vector`

Sets one of the vector table entries.

```asm
.vector reset START
.vector int0 ISR0
```

### `.org`

Changes where the next instruction or word is placed.

```asm
.org 100
DATA:
    .word 0x12345678
```

### `.word`

Writes a raw 32-bit memory word.

```asm
.word 0x12345678
.word -1
```

---

## Supported instructions

```text
NOP
HLT
SETC
NOT Rdst
INC Rdst
OUT Rsrc
IN Rdst
MOV Rdst, Rsrc
SWAP Rdst, Rsrc
ADD Rdst, Rsrc1, Rsrc2
SUB Rdst, Rsrc1, Rsrc2
AND Rdst, Rsrc1, Rsrc2
IADD Rdst, Rsrc, Imm
PUSH Rsrc
POP Rdst
LDM Rdst, Imm
LDD Rdst, offset(Rsrc)
STD Rsrc1, offset(Rsrc2)
JZ Imm_or_label
JN Imm_or_label
JC Imm_or_label
JMP Imm_or_label
CALL Imm_or_label
RET
INT 0
INT 1
RTI
```

---

## Important encoding notes

### One instruction = one memory word

This assembler assumes Team 10's Phase 1 format where the 16-bit immediate/offset is already inside the 32-bit instruction.

So every instruction occupies one memory location.

### `SWAP`

`SWAP` is encoded as one instruction.

The assembler does **not** expand it into two instructions because the hardware/HDU handles the internal swap macro-operation.

### `INT`

`INT 0` and `INT 1` are encoded as one instruction.

The index is stored in the lowest bit of the instruction, so:

```asm
INT 0
INT 1
```

select between:

```text
M[2]
M[3]
```

---

## Example

Input `test.asm`:

```asm
.vector reset START

START:
    LDM R1, 5
    LDM R2, 10
    ADD R3, R1, R2
    OUT R3
    HLT
```

Run:

```bash
python assembler.py test.asm
```

Output `program.mem`:

```text
00000004
00000000
00000000
00000000
79000005
7A00000A
4B280000
2B000000
08000000
```
