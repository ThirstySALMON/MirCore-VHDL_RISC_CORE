--------------------------------------------------------------------------------
-- Entity: ALU (Arithmetic Logic Unit)
-- Description:
--   Performs arithmetic and logical operations on two 32-bit operands.
--   This is a COMBINATORIAL module (no clock dependency).

--   Supported Operations (3-bit control signal):
--     000 = NOP       (no operation, output all zeros)
--     001 = NOT       (bitwise NOT of operand1)
--     010 = INC       (increment operand1 by 1)
--     011 = MOV       (move operand1 through, ignore operand2)
--     100 = ADD       (add operand1 + operand2)
--     101 = SUB       (subtract operand1 - operand2)
--     110 = AND       (bitwise AND of operand1 and operand2)
--     111 = PASS      (pass operand1 through)
--
--   Flags (Condition Code Register - CCR):
--     Bit 0 = Z (Zero flag)     : 1 if result == 0, else 0
--     Bit 1 = N (Negative flag) : 1 if result[31]==1 (MSB is 1), else 0
--     Bit 2 = C (Carry flag)    : 33rd bit from unsigned arithmetic
--                                 (overflow/carry bit from ADD, SUB, INC)
--
-- CARRY FLAG DEFINITION (Per TA):
--   The carry flag is the 33rd bit of arithmetic operations in UNSIGNED arithmetic.
--   - For ADD: C = result(32) when treating operands as unsigned
--   - For SUB: C = borrow bit (same as 33rd bit of A - B in unsigned)
--   - For INC: C = result(32) when treating operand as unsigned
--   - For other ops: C = 0
--
-- NOTE: Operands are treated as SIGNED for interpretation, but carry is
--       computed using UNSIGNED arithmetic (the 33rd bit).
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY alu IS
    PORT (
        operand1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_op : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        alu_result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_flags : OUT STD_LOGIC_VECTOR(2 DOWNTO 0) -- [2]=C, [1]=N, [0]=Z
    );
END alu;

ARCHITECTURE behavioral OF alu IS
BEGIN

    PROCESS (operand1, operand2, alu_op)
        VARIABLE result : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE carry : STD_LOGIC;
        VARIABLE zero : STD_LOGIC;
        VARIABLE negative : STD_LOGIC;

        -- For arithmetic operations: treat as signed
        VARIABLE a : signed(31 DOWNTO 0);
        VARIABLE b : signed(31 DOWNTO 0);
        VARIABLE r : signed(31 DOWNTO 0);
        VARIABLE result_33bit : unsigned(32 DOWNTO 0);

    BEGIN

        a := signed(operand1);
        b := signed(operand2);

        -- Default values (prevent latches)
        carry := '0';
        zero := '0';
        negative := '0';
        result := (OTHERS => '0');
        -- ====================================================================
        -- OPERATION SELECTION
        -- ====================================================================
        CASE alu_op IS

            WHEN "000" => -- NOP: Zero output
                result := (OTHERS => '0');
                carry := '0';

            WHEN "001" => -- NOT: Bitwise NOT
                result := NOT operand1;
                carry := '0';

            WHEN "010" => -- INC
                result_33bit := unsigned('0' & operand1) + 1;
                result := STD_LOGIC_VECTOR(result_33bit(31 DOWNTO 0));
                carry := result_33bit(32);

            WHEN "011" => -- MOV: Pass operand1
                result := operand1;
                carry := '0';

            WHEN "100" => -- ADD
                result_33bit := unsigned('0' & operand1) + unsigned('0' & operand2);
                result := STD_LOGIC_VECTOR(result_33bit(31 DOWNTO 0));
                carry := result_33bit(32);

            WHEN "101" => -- SUB
                result_33bit := unsigned('0' & operand1) - unsigned('0' & operand2);
                result := STD_LOGIC_VECTOR(result_33bit(31 DOWNTO 0));
                carry := result_33bit(32);

            WHEN "110" => -- AND: Bitwise AND
                result := operand1 AND operand2;
                carry := '0';

            WHEN "111" => -- PASS: Pass operand1 (same as MOV)
                result := operand1;
                carry := '0';

            WHEN OTHERS =>
                result := (OTHERS => '0');
                carry := '0';

        END CASE;

        -- ====================================================================
        -- FLAG GENERATION (simple and clean)
        -- ====================================================================

        -- Zero flag: check if result is all zeros
        IF result = x"00000000" THEN
            zero := '1';
        ELSE
            zero := '0';
        END IF;

        -- Negative flag: check sign bit (MSB)
        negative := result(31);

        -- Carry flag: already computed above in each case statement

        -- ====================================================================
        -- OUTPUT ASSIGNMENT
        -- ====================================================================
        alu_result <= result;
        alu_flags <= carry & negative & zero;

    END PROCESS;

END behavioral;