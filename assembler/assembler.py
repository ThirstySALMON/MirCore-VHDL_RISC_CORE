#!/usr/bin/env python3
"""
Team 10 Custom Processor Assembler
==================================

What this file does
-------------------
This Python program reads an assembly text file (.asm) and generates a memory
file named program.mem by default.

The output program.mem is plain text:
    - one 32-bit memory word per line
    - each word is written as 8 hexadecimal digits
    - no address prefixes are written

Example program.mem:
    00000004
    00000000
    00000000
    00000000
    79000005
    08000000

Meaning:
    line 0 -> memory address 0
    line 1 -> memory address 1
    line 2 -> memory address 2
    line 3 -> memory address 3
    line 4 -> memory address 4
    ...

Recommended memory layout used by this assembler
------------------------------------------------
Because the project says reset loads PC from M[0], and interrupt vectors also
come from memory, this assembler reserves the first 4 memory words:

    M[0] = reset/start address
    M[1] = hardware interrupt ISR address
    M[2] = software INT 0 ISR address
    M[3] = software INT 1 ISR address

Real code starts at address 4 by default.

How to run
----------
    python assembler.py program.asm

This creates:
    program.mem

Optional:
    python assembler.py program.asm -o my_program.mem
    python assembler.py program.asm --bin
    python assembler.py program.asm --fill-to 4096

Notes for Youssef / Team 10
---------------------------
- The assembler encodes ONE assembly instruction into ONE 32-bit memory word.
- Immediate values are 16-bit.
- Negative immediate numbers are converted using two's complement.
- Positive address immediates / labels are treated normally as unsigned values.
- Labels are resolved automatically.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union


# =============================================================================
# 1) ISA CONSTANTS
# =============================================================================
#
# Your processor instruction word is 32 bits.
# The top 5 bits are always the opcode:
#
#     bits [31:27] = opcode
#
# R-Type format:
#     opcode[31:27] Rdst[26:24] Rsrc1[23:21] Rsrc2[20:18] unused[17:0]
#
# I-Type format:
#     opcode[31:27] Rdst[26:24] Rsrc1[23:21] Rsrc2[20:18] unused[17:16] imm[15:0]
#
# J-Type format:
#     opcode[31:27] unused[26:16] imm[15:0]
#
# S-Type/special format used here:
#     opcode[31:27] Rdst[26:24] Rsrc1[23:21] unused[20:0]
#
# The opcodes below come from your Team 10 ISA sheet.

OPCODES: Dict[str, int] = {
    "NOP":  0b00000,
    "HLT":  0b00001,
    "SETC": 0b00010,
    "NOT":  0b00011,
    "INC":  0b00100,
    "OUT":  0b00101,
    "IN":   0b00110,
    "MOV":  0b00111,
    "SWAP": 0b01000,
    "ADD":  0b01001,
    "SUB":  0b01010,
    "AND":  0b01011,
    "IADD": 0b01100,
    "PUSH": 0b01101,
    "POP":  0b01110,
    "LDM":  0b01111,
    "LDD":  0b10000,
    "STD":  0b10001,
    "JZ":   0b10010,
    "JN":   0b10011,
    "JC":   0b10100,
    "JMP":  0b10101,
    "CALL": 0b10110,
    "RET":  0b10111,
    "INT":  0b11000,
    "RTI":  0b11001,
}

# The memory is 4 KB of 32-bit words according to the project.
# This means valid word addresses are usually 0..4095.
DEFAULT_MEMORY_WORDS = 4096

# By recommendation, addresses 0..3 are vectors, and actual code starts at 4.
DEFAULT_CODE_START = 4

# Vector names accepted in .vector directives.
# These all map to fixed memory addresses.
VECTOR_ADDR: Dict[str, int] = {
    "RESET": 0,
    "START": 0,     # alias for RESET
    "HW": 1,
    "HW_INT": 1,
    "HARDWARE": 1,
    "INT0": 2,
    "SW_INT0": 2,
    "INT1": 3,
    "SW_INT1": 3,
}


# =============================================================================
# 2) INTERNAL DATA STRUCTURES
# =============================================================================
#
# We do two passes:
#
# Pass 1:
#     - remove comments
#     - find labels and their addresses
#     - remember where each instruction/directive will go
#
# Pass 2:
#     - encode every remembered instruction into a 32-bit integer
#     - write the final program.mem file


@dataclass
class SourceItem:
    """One thing that occupies one memory word.

    It can be an instruction like:
        ADD R1, R2, R3

    Or a raw data word directive like:
        .word 0x12345678
    """

    address: int
    text: str
    line_no: int
    is_word_directive: bool = False


# =============================================================================
# 3) SMALL HELPER FUNCTIONS
# =============================================================================


def fail(message: str, line_no: Optional[int] = None) -> None:
    """Print a nice error message and stop the assembler.

    Why not just let Python crash?
    Because assembler errors should tell you which assembly line is wrong.
    """

    if line_no is not None:
        raise SystemExit(f"Assembler error on line {line_no}: {message}")
    raise SystemExit(f"Assembler error: {message}")



def strip_comment(line: str) -> str:
    """Remove comments from one source line.

    Supported comment styles:
        ; comment
        # comment

    Example:
        LDM R1, 5   ; load 5

    becomes:
        LDM R1, 5
    """

    line = line.split(";", 1)[0]  # what does [0]
    line = line.split("#", 1)[0]
    return line.strip()



def split_operands(text: str) -> List[str]:
    """Split an instruction line into tokens.

    This function accepts commas or spaces between operands.

    Example:
        "ADD R1, R2, R3"

    becomes:
        ["ADD", "R1", "R2", "R3"]

    For memory syntax:
        "LDD R1, 4(R2)"

    becomes:
        ["LDD", "R1", "4(R2)"]
    """

    # Replace commas with spaces, then split on whitespace.
    # This lets both of these work:
    #   ADD R1, R2, R3
    #   ADD R1 R2 R3
    return text.replace(",", " ").split()



def parse_register(token: str, line_no: Optional[int] = None) -> int:
    """Convert a register name like R0..R7 into a 3-bit number.

    Your ISA has eight general purpose registers:
        R0, R1, R2, R3, R4, R5, R6, R7

    These fit in 3 bits:
        R0 = 000
        R1 = 001
        ...
        R7 = 111
    """

    token = token.strip().upper()

    if not re.fullmatch(r"R[0-7]", token):
        fail(f"expected register R0..R7, got '{token}'", line_no)

    return int(token[1])



def parse_number(token: str, labels: Dict[str, int], line_no: Optional[int] = None) -> int:
    """Parse a number or label into a Python integer.

    Supported formats:
        10          decimal
        -5          signed decimal
        0x10        hexadecimal
        0b1010      binary
        LABEL       label address

    Important:
        This function does NOT decide whether the value is 16-bit or 32-bit.
        It only converts the text into an integer.
    """

    token = token.strip()

    # If token is a label, return the label address.
    # Labels are case-sensitive? To keep life easier, this assembler stores them
    # in uppercase, so label lookup is also uppercase.
    upper = token.upper()
    if upper in labels:
        return labels[upper]

    try:
        # int(token, 0) lets Python understand decimal, hex 0x..., binary 0b...
        return int(token, 0)
    except ValueError:
        fail(f"expected number or label, got '{token}'", line_no)

    # This is unreachable, but keeps type checkers happy.
    return 0



def to_u16(value: int, line_no: Optional[int] = None) -> int:
    """Convert a value into a 16-bit field.

    Why this supports both signed and unsigned:

    - If you write a signed decimal like -1, this returns 0xFFFF.
      That is two's complement, which is what sign-extension hardware expects.

    - If you write an unsigned value like 65535 or 0xFFFF, this also returns
      0xFFFF.

    Valid accepted range:
        signed:   -32768..-1
        unsigned: 0..65535

    Examples:
        5      -> 0x0005
        -1     -> 0xFFFF
        -2     -> 0xFFFE
        0x1234 -> 0x1234
    """

    if value < -32768 or value > 0xFFFF:
        fail(f"16-bit immediate/address out of range: {value}", line_no)

    # Masking keeps the lowest 16 bits.
    # For negative values, Python uses infinite sign bits internally, so:
    #   -1 & 0xFFFF = 0xFFFF
    return value & 0xFFFF



def to_u32(value: int, line_no: Optional[int] = None) -> int:
    """Convert a value into a 32-bit memory word.

    Used for:
        .word values
        vector table values in M[0..3]

    Accepts signed 32-bit or unsigned 32-bit values.
    """

    if value < -2147483648 or value > 0xFFFFFFFF:
        fail(f"32-bit word out of range: {value}", line_no)

    return value & 0xFFFFFFFF



def parse_offset_base(token: str, labels: Dict[str, int], line_no: Optional[int] = None) -> Tuple[int, int]:
    """Parse memory addressing syntax: offset(Rx)

    Examples:
        0(R1)       -> offset=0, base=R1
        4(R2)       -> offset=4, base=R2
        -1(R3)      -> offset=-1, base=R3, encoded as 0xFFFF
        0x10(R4)    -> offset=0x10, base=R4
        DATA(R5)    -> offset=label DATA, base=R5

    Returns:
        (offset_integer, base_register_number)
    """

    match = re.fullmatch(r"(.+)\((R[0-7])\)", token.strip(), re.IGNORECASE)

    if not match:
        fail(f"expected memory operand like offset(Rx), got '{token}'", line_no)

    offset_text = match.group(1).strip()
    base_reg_text = match.group(2).strip()

    offset_value = parse_number(offset_text, labels, line_no)
    base_reg = parse_register(base_reg_text, line_no)

    return offset_value, base_reg


# =============================================================================
# 4) BIT ENCODING FUNCTIONS
# =============================================================================
#
# These functions are the core of the assembler.
# They place opcode/register/immediate fields into the exact bit positions of
# your 32-bit instruction format.


def encode_r_type(opcode: int, rdst: int = 0, rsrc1: int = 0, rsrc2: int = 0) -> int:
    """Encode R-Type format.

    Bit positions:
        opcode -> bits [31:27]
        rdst   -> bits [26:24]
        rsrc1  -> bits [23:21]
        rsrc2  -> bits [20:18]
        unused -> bits [17:0] = zeros
    """

    return (
        ((opcode & 0b11111) << 27)
        | ((rdst & 0b111) << 24)
        | ((rsrc1 & 0b111) << 21)
        | ((rsrc2 & 0b111) << 18)
    )



def encode_i_type(opcode: int, rdst: int = 0, rsrc1: int = 0, rsrc2: int = 0, imm: int = 0) -> int:
    """Encode I-Type format.

    Bit positions:
        opcode -> bits [31:27]
        rdst   -> bits [26:24]
        rsrc1  -> bits [23:21]
        rsrc2  -> bits [20:18]
        unused -> bits [17:16] = zeros
        imm    -> bits [15:0]
    """

    return (
        ((opcode & 0b11111) << 27)
        | ((rdst & 0b111) << 24)
        | ((rsrc1 & 0b111) << 21)
        | ((rsrc2 & 0b111) << 18)
        | (imm & 0xFFFF)
    )



def encode_j_type(opcode: int, imm: int = 0) -> int:
    """Encode J-Type format.

    Bit positions:
        opcode -> bits [31:27]
        unused -> bits [26:16] = zeros
        imm    -> bits [15:0]
    """

    return ((opcode & 0b11111) << 27) | (imm & 0xFFFF)



def encode_s_type(opcode: int, rdst: int = 0, rsrc1: int = 0) -> int:
    """Encode S-Type / special format.

    Bit positions:
        opcode -> bits [31:27]
        rdst   -> bits [26:24]
        rsrc1  -> bits [23:21]
        unused -> bits [20:0] = zeros

    Many one-register instructions can be represented using this layout.
    """

    return (
        ((opcode & 0b11111) << 27)
        | ((rdst & 0b111) << 24)
        | ((rsrc1 & 0b111) << 21)
    )


# =============================================================================
# 5) INSTRUCTION ENCODER
# =============================================================================
#
# This function understands every instruction syntax and chooses the right
# encoding format.


def require_count(tokens: List[str], expected_count: int, line_no: int) -> None:
    """Check the number of instruction tokens.

    Example:
        ADD R1, R2, R3 -> 4 tokens: [ADD, R1, R2, R3]
    """

    if len(tokens) != expected_count:
        mnemonic = tokens[0] if tokens else "<empty>"
        got = max(len(tokens) - 1, 0)
        expected = expected_count - 1
        fail(f"{mnemonic} expects {expected} operand(s), got {got}", line_no)



def encode_instruction(text: str, labels: Dict[str, int], line_no: int) -> int:
    """Encode one assembly instruction into a 32-bit integer.

    This is the main translation function.
    """

    tokens = split_operands(text)

    if not tokens:
        fail("empty instruction", line_no)

    mnemonic = tokens[0].upper()

    if mnemonic not in OPCODES:
        fail(f"unknown instruction '{mnemonic}'", line_no)

    opcode = OPCODES[mnemonic]

    # -------------------------------------------------------------------------
    # No-operand instructions
    # -------------------------------------------------------------------------
    # Syntax:
    #   NOP
    #   HLT
    #   SETC
    #   RET
    #   RTI
    #
    # They only need the opcode field. Everything else is zero.

    if mnemonic in {"NOP", "HLT", "SETC", "RET", "RTI"}:
        require_count(tokens, 1, line_no)
        return encode_j_type(opcode, 0)

    # -------------------------------------------------------------------------
    # One-register instructions
    # -------------------------------------------------------------------------
    # Syntax:
    #   NOT Rdst
    #   INC Rdst
    #   OUT Rsrc
    #   IN Rdst
    #   PUSH Rsrc
    #   POP Rdst
    #
    # For your design, we place the single register in the Rdst field [26:24].
    # This matches the common single-operand style in the project table.

    if mnemonic in {"NOT", "INC", "OUT", "IN", "PUSH", "POP"}:
        require_count(tokens, 2, line_no)
        r = parse_register(tokens[1], line_no)
        return encode_s_type(opcode, rdst=r)

    # -------------------------------------------------------------------------
    # Two-register instructions
    # -------------------------------------------------------------------------
    # Syntax:
    #   MOV Rdst, Rsrc
    #   SWAP Rdst, Rsrc
    #
    # Encoding:
    #   Rdst  -> bits [26:24]
    #   Rsrc  -> Rsrc1 field bits [23:21]
    #
    # Important:
    #   SWAP is NOT expanded by the assembler. Your hardware/HDU handles the
    #   swap macro-operation internally.

    if mnemonic in {"MOV", "SWAP"}:
        require_count(tokens, 3, line_no)
        rdst = parse_register(tokens[1], line_no)
        rsrc = parse_register(tokens[2], line_no)
        return encode_r_type(opcode, rdst=rdst, rsrc1=rsrc)

    # -------------------------------------------------------------------------
    # Three-register ALU instructions
    # -------------------------------------------------------------------------
    # Syntax:
    #   ADD Rdst, Rsrc1, Rsrc2
    #   SUB Rdst, Rsrc1, Rsrc2
    #   AND Rdst, Rsrc1, Rsrc2

    if mnemonic in {"ADD", "SUB", "AND"}:
        require_count(tokens, 4, line_no)
        rdst = parse_register(tokens[1], line_no)
        rsrc1 = parse_register(tokens[2], line_no)
        rsrc2 = parse_register(tokens[3], line_no)
        return encode_r_type(opcode, rdst=rdst, rsrc1=rsrc1, rsrc2=rsrc2)

    # -------------------------------------------------------------------------
    # IADD immediate instruction
    # -------------------------------------------------------------------------
    # Syntax:
    #   IADD Rdst, Rsrc, Imm
    #
    # Encoding:
    #   Rdst -> bits [26:24]
    #   Rsrc -> Rsrc1 bits [23:21]
    #   Imm  -> bits [15:0]
    #
    # Negative Imm values are encoded as 16-bit two's complement.

    if mnemonic == "IADD":
        require_count(tokens, 4, line_no)
        rdst = parse_register(tokens[1], line_no)
        rsrc = parse_register(tokens[2], line_no)
        imm = to_u16(parse_number(tokens[3], labels, line_no), line_no)
        return encode_i_type(opcode, rdst=rdst, rsrc1=rsrc, imm=imm)

    # -------------------------------------------------------------------------
    # Load immediate
    # -------------------------------------------------------------------------
    # Syntax:
    #   LDM Rdst, Imm
    #
    # The immediate is stored in bits [15:0].

    if mnemonic == "LDM":
        require_count(tokens, 3, line_no)
        rdst = parse_register(tokens[1], line_no)
        imm = to_u16(parse_number(tokens[2], labels, line_no), line_no)
        return encode_i_type(opcode, rdst=rdst, imm=imm)

    # -------------------------------------------------------------------------
    # Load from memory
    # -------------------------------------------------------------------------
    # Syntax:
    #   LDD Rdst, offset(Rsrc)
    #
    # Meaning:
    #   R[Rdst] <- M[R[Rsrc] + offset]
    #
    # Encoding choice:
    #   Rdst -> Rdst field
    #   base Rsrc -> Rsrc1 field
    #   offset -> imm field

    if mnemonic == "LDD":
        require_count(tokens, 3, line_no)
        rdst = parse_register(tokens[1], line_no)
        offset, base = parse_offset_base(tokens[2], labels, line_no)
        imm = to_u16(offset, line_no)
        return encode_i_type(opcode, rdst=rdst, rsrc1=base, imm=imm)

    # -------------------------------------------------------------------------
    # Store to memory
    # -------------------------------------------------------------------------
    # Syntax:
    #   STD Rsrc1, offset(Rsrc2)
    #
    # Meaning:
    #   M[R[Rsrc2] + offset] <- R[Rsrc1]
    #
    # Encoding choice:
    #   data register Rsrc1 -> Rsrc1 field
    #   base register Rsrc2 -> Rsrc2 field
    #   Rdst field is unused and stays 0
    #   offset -> imm field

    if mnemonic == "STD":
        require_count(tokens, 3, line_no)
        data_reg = parse_register(tokens[1], line_no)
        offset, base_reg = parse_offset_base(tokens[2], labels, line_no)
        imm = to_u16(offset, line_no)
        return encode_i_type(opcode, rsrc1=data_reg, rsrc2=base_reg, imm=imm)

    # -------------------------------------------------------------------------
    # Jump / branch / call instructions
    # -------------------------------------------------------------------------
    # Syntax:
    #   JZ label_or_address
    #   JN label_or_address
    #   JC label_or_address
    #   JMP label_or_address
    #   CALL label_or_address
    #
    # Labels become positive memory addresses, so they act like unsigned values.
    # Direct negative numbers are still allowed and will become two's complement,
    # but normally you should use labels for addresses.

    if mnemonic in {"JZ", "JN", "JC", "JMP", "CALL"}:
        require_count(tokens, 2, line_no)
        target = to_u16(parse_number(tokens[1], labels, line_no), line_no)
        return encode_j_type(opcode, target)

    # -------------------------------------------------------------------------
    # Software interrupt instruction
    # -------------------------------------------------------------------------
    # Syntax:
    #   INT 0
    #   INT 1
    #
    # The project says index is either 0 or 1, and PC loads from M[index + 2].
    # Your schematic also shows Inst[0] selecting M[2] or M[3].
    # So we encode the index in the lowest bit of the instruction.

    if mnemonic == "INT":
        require_count(tokens, 2, line_no)
        index = parse_number(tokens[1], labels, line_no)

        if index not in (0, 1):
            fail("INT index must be 0 or 1", line_no)

        return encode_j_type(opcode, index)

    # If we reach this point, we forgot to implement an instruction above.
    fail(f"instruction '{mnemonic}' exists in opcode table but is not implemented", line_no)
    return 0


# =============================================================================
# 6) FIRST PASS: FIND LABELS AND MEMORY LOCATIONS
# =============================================================================


def first_pass(source_lines: List[str], code_start: int) -> Tuple[Dict[str, int], List[SourceItem], Dict[int, Union[int, str]]]:
    """First pass over the assembly file.

    Outputs:
        labels:
            label name -> memory address

        items:
            list of instructions/.word directives with assigned addresses

        vectors:
            vector memory address -> target number or target label

    The vectors dictionary might contain labels at first. They are resolved in
    the second pass after we know all labels.
    """

    labels: Dict[str, int] = {}
    items: List[SourceItem] = []
    vectors: Dict[int, Union[int, str]] = {}

    # This is the address of the next instruction or .word directive.
    current_addr = code_start

    for line_no, original_line in enumerate(source_lines, start=1):
        line = strip_comment(original_line)

        # Skip empty/comment-only lines.
        if not line:
            continue

        # Support labels.
        # Example:
        #   LOOP:
        #   LOOP: ADD R1, R2, R3
        #   LOOP: NEXT: NOP
        #
        # We repeatedly consume "LABEL:" from the start of the line.
        while True:
            label_match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$", line)
            if not label_match:
                break

            label_name = label_match.group(1).upper()
            rest_of_line = label_match.group(2).strip()

            if label_name in labels:
                fail(f"duplicate label '{label_name}'", line_no)

            labels[label_name] = current_addr
            line = rest_of_line

            # If the line was only a label, stop processing this source line.
            if not line:
                break

        if not line:
            continue

        tokens = split_operands(line)
        first_token = tokens[0].upper()

        # ---------------------------------------------------------------------
        # .ORG directive
        # ---------------------------------------------------------------------
        # Changes the memory address where the next instruction/.word is placed.
        # Useful for putting ISR code at a specific address.
        #
        # Example:
        #   .org 100
        #   ISR:
        #   RTI

        if first_token == ".ORG":
            if len(tokens) != 2:
                fail(".org expects exactly one address", line_no)

            new_addr = parse_number(tokens[1], labels, line_no)

            if new_addr < 0 or new_addr >= DEFAULT_MEMORY_WORDS:
                fail(f".org address must be between 0 and {DEFAULT_MEMORY_WORDS - 1}", line_no)

            current_addr = new_addr
            continue

        # ---------------------------------------------------------------------
        # .VECTOR directive
        # ---------------------------------------------------------------------
        # Sets one of the first four memory words.
        #
        # Syntax:
        #   .vector reset START
        #   .vector hw_int HW_ISR
        #   .vector int0 ISR0
        #   .vector int1 ISR1
        #
        # The target can be a label or a number.

        if first_token == ".VECTOR":
            if len(tokens) != 3:
                fail(".vector expects: .vector <reset|hw_int|int0|int1> <target>", line_no)

            vector_name = tokens[1].upper()
            target_text = tokens[2]

            if vector_name not in VECTOR_ADDR:
                allowed = ", ".join(sorted(VECTOR_ADDR.keys()))
                fail(f"unknown vector '{vector_name}'. Allowed: {allowed}", line_no)

            vector_memory_address = VECTOR_ADDR[vector_name]

            # Store label text for now if it is not a number.
            try:
                target: Union[int, str] = int(target_text, 0)
            except ValueError:
                target = target_text.upper()

            vectors[vector_memory_address] = target
            continue

        # ---------------------------------------------------------------------
        # .WORD directive
        # ---------------------------------------------------------------------
        # Places a raw 32-bit word into memory.
        # Useful for testing data memory or manually writing constants.
        #
        # Example:
        #   .word 0x12345678
        #   .word -1

        if first_token == ".WORD":
            if len(tokens) != 2:
                fail(".word expects exactly one value", line_no)

            items.append(SourceItem(current_addr, line, line_no, is_word_directive=True))
            current_addr += 1
            continue

        # ---------------------------------------------------------------------
        # Normal instruction
        # ---------------------------------------------------------------------
        # Every instruction is currently one memory word in Team 10's design.

        items.append(SourceItem(current_addr, line, line_no, is_word_directive=False))
        current_addr += 1

    return labels, items, vectors


# =============================================================================
# 7) SECOND PASS: ENCODE EVERYTHING
# =============================================================================


def resolve_vector_target(target: Union[int, str], labels: Dict[str, int], line_no: Optional[int] = None) -> int:
    """Resolve a vector target into a 32-bit memory word.

    A vector target can be:
        - a number, like 4 or 0x100
        - a label, like START
    """

    if isinstance(target, int):
        return to_u32(target, line_no)

    label_name = target.upper()
    if label_name not in labels:
        fail(f"unknown vector target label '{target}'", line_no)

    return to_u32(labels[label_name], line_no)



def second_pass(labels: Dict[str, int], items: List[SourceItem], vectors: Dict[int, Union[int, str]], code_start: int) -> Dict[int, int]:
    """Encode all instructions and build a memory dictionary.

    Returns:
        memory[address] = 32-bit word
    """

    memory: Dict[int, int] = {}

    # -------------------------------------------------------------------------
    # Default vector table
    # -------------------------------------------------------------------------
    # If the user does not write any .vector directive:
    #   M[0] = START label address if START exists, otherwise code_start (4)
    #   M[1] = 0
    #   M[2] = 0
    #   M[3] = 0

    default_reset_target = labels.get("START", code_start)

    memory[0] = to_u32(default_reset_target)
    memory[1] = 0
    memory[2] = 0
    memory[3] = 0

    # Apply user-specified vectors over the defaults.
    for vector_memory_address, target in vectors.items():
        memory[vector_memory_address] = resolve_vector_target(target, labels)

    # -------------------------------------------------------------------------
    # Encode each instruction / .word directive.
    # -------------------------------------------------------------------------

    for item in items:
        if item.address < 0 or item.address >= DEFAULT_MEMORY_WORDS:
            fail(f"memory address out of range: {item.address}", item.line_no)

        if item.address in memory and item.address < DEFAULT_CODE_START:
            # The first 4 addresses are vectors by recommendation.
            # We allow overwriting only via .vector, not by accidentally placing
            # normal code there.
            fail(
                f"address {item.address} is reserved for the vector table. "
                f"Use .vector instead of placing code/.word there.",
                item.line_no,
            )

        if item.is_word_directive:
            tokens = split_operands(item.text)
            value = parse_number(tokens[1], labels, item.line_no)
            memory[item.address] = to_u32(value, item.line_no)
        else:
            memory[item.address] = encode_instruction(item.text, labels, item.line_no)

    return memory


# =============================================================================
# 8) FILE WRITING
# =============================================================================


def write_hex_memory(memory: Dict[int, int], output_path: Path, fill_to: Optional[int] = None) -> None:
    """Write program.mem as plain hex text.

    No addresses are written.
    The line number itself represents the memory address.

    Example:
        line 0 = M[0]
        line 1 = M[1]
    """

    if not memory:
        fail("nothing to write")

    max_used_addr = max(memory.keys())

    if fill_to is not None:
        if fill_to <= 0:
            fail("--fill-to must be positive")
        if fill_to > DEFAULT_MEMORY_WORDS:
            fail(f"--fill-to cannot exceed {DEFAULT_MEMORY_WORDS}")
        final_length = fill_to
    else:
        # +1 because address 8 means we need lines 0..8 inclusive.
        final_length = max_used_addr + 1

    lines: List[str] = []

    for address in range(final_length):
        word = memory.get(address, 0)
        lines.append(f"{word & 0xFFFFFFFF:08X}")

    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")



def write_binary_debug(memory: Dict[int, int], output_path: Path, fill_to: Optional[int] = None) -> None:
    """Write a binary debug file.

    This is NOT needed by the processor usually.
    It is just useful for checking bits by eye.
    """

    max_used_addr = max(memory.keys())
    final_length = fill_to if fill_to is not None else max_used_addr + 1

    lines: List[str] = []
    for address in range(final_length):
        word = memory.get(address, 0)
        lines.append(f"{word & 0xFFFFFFFF:032b}")

    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


# =============================================================================
# 9) MAIN ASSEMBLE FUNCTION
# =============================================================================


def assemble_file(input_path: Path, output_path: Path, bin_output_path: Optional[Path], fill_to: Optional[int], code_start: int) -> None:
    """Assemble one .asm file into program.mem."""

    if not input_path.exists():
        fail(f"input file does not exist: {input_path}")

    if code_start < 4:
        fail("code_start must be at least 4 because addresses 0..3 are reserved vectors")

    source_lines = input_path.read_text(encoding="utf-8").splitlines()

    labels, items, vectors = first_pass(source_lines, code_start=code_start)
    memory = second_pass(labels, items, vectors, code_start=code_start)

    write_hex_memory(memory, output_path, fill_to=fill_to)

    if bin_output_path is not None:
        write_binary_debug(memory, bin_output_path, fill_to=fill_to)

    print(f"Assembled successfully: {input_path}")
    print(f"Wrote hex memory file: {output_path}")

    if bin_output_path is not None:
        print(f"Wrote binary debug file: {bin_output_path}")

    print(f"Memory words written: {fill_to if fill_to is not None else max(memory.keys()) + 1}")


# =============================================================================
# 10) COMMAND LINE INTERFACE
# =============================================================================


def build_arg_parser() -> argparse.ArgumentParser:
    """Create the command-line parser."""

    parser = argparse.ArgumentParser(
        description="Team 10 assembler: converts .asm into plain hex program.mem"
    )

    parser.add_argument(
        "input",
        help="input assembly file, example: test.asm",
    )

    parser.add_argument(
        "-o",
        "--output",
        default="program.mem",
        help="output memory file name. Default: program.mem in the current/root folder",
    )

    parser.add_argument(
        "--bin",
        action="store_true",
        help="also generate program.bin with 32-bit binary text lines for debugging",
    )

    parser.add_argument(
        "--bin-output",
        default="program.bin",
        help="binary debug output file name when --bin is used. Default: program.bin",
    )

    parser.add_argument(
        "--fill-to",
        type=int,
        default=None,
        help="optionally force output to contain N memory words, e.g. --fill-to 4096",
    )

    parser.add_argument(
        "--code-start",
        type=int,
        default=DEFAULT_CODE_START,
        help="address where normal code starts. Default: 4",
    )

    return parser



def main(argv: Optional[List[str]] = None) -> int:
    """Program entry point."""

    parser = build_arg_parser()
    args = parser.parse_args(argv)

    input_path = Path(args.input)
    output_path = Path(args.output)
    bin_output_path = Path(args.bin_output) if args.bin else None

    assemble_file(
        input_path=input_path,
        output_path=output_path,
        bin_output_path=bin_output_path,
        fill_to=args.fill_to,
        code_start=args.code_start,
    )

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nAssembler cancelled.", file=sys.stderr)
        raise SystemExit(1)
