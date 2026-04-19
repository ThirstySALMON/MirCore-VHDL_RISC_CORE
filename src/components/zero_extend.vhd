-- Zero Extend Module
-- Extends a 16-bit value to 32-bit by padding with zeros

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY zero_extend IS
    PORT (
        -- Input: 16-bit immediate value
        imm_16bit : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        -- Output: 32-bit zero-extended value
        imm_32bit : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END zero_extend;

ARCHITECTURE ze_rtl OF zero_extend IS
BEGIN
    imm_32bit(31 DOWNTO 16) <= (OTHERS => '0');
    imm_32bit(15 DOWNTO 0) <= imm_16bit;
END ze_rtl;