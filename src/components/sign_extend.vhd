-- Sign Extend Module
-- Extends a 16-bit signed value to 32-bit by padding with sign bit

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY sign_extend IS
    PORT (
        -- Input: 16-bit signed immediate value
        imm_16bit : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        -- Output: 32-bit sign-extended value
        imm_32bit : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END sign_extend;

ARCHITECTURE se_rtl OF sign_extend IS
BEGIN
    -- Check sign bit and pad with it
    imm_32bit(31 DOWNTO 16) <= (OTHERS => imm_16bit(15));
    imm_32bit(15 DOWNTO 0) <= imm_16bit;
END se_rtl;