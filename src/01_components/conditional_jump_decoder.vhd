-- ================================================================
-- Description :
--   This module performs partial decoding of the instruction to
--   detect conditional jump instructions and extract their immediate
--   value.
--
--   It is used in the instruction fetch/decode stage to assist the
--   branch prediction unit.
--
--   Functionality:
--     1. Extracts the 16-bit immediate field from the instruction.
--     2. Detects whether the instruction is a conditional branch.
--
--   Supported Conditional Branch Instructions:
--     - JZ  (opcode = 10010)
--     - JN  (opcode = 10011)
--     - JC  (opcode = 10100)
--
--
--   Inputs:
--     instr  : 32-bit instruction word
--
--   Outputs:
--     imm16                 : Lower 16 bits of instruction (immediate)
--     is_conditional_branch : '1' if instruction is JZ, JN, or JC
--
-- ================================================================


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY conditional_jump_decoder IS
    PORT (
        instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        imm16 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        is_conditional_branch : OUT STD_LOGIC
    );
END conditional_jump_decoder;

ARCHITECTURE Behavioral OF conditional_jump_decoder IS

    SIGNAL opcode : STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN

    
    opcode <= instr(31 DOWNTO 27);
    imm16 <= instr(15 DOWNTO 0);

    -- Conditional branch detection (JZ, JN, JC)
    is_conditional_branch <= '1' WHEN
        (opcode = "10010") OR -- JZ
        (opcode = "10011") OR -- JN
        (opcode = "10100") -- JC
        ELSE
        '0';

END Behavioral;