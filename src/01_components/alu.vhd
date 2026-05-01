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
--     Bit 2 = C (Carry flag)    : 1 if overflow/underflow in ADD/SUB, else 0

--------------------------------------------------------------------------------
-- ALU ASSUMPTION (IMPORTANT)
--------------------------------------------------------------------------------
-- This ALU uses SIGNED (two's complement) arithmetic for all operations.
--
-- C flag = SIGNED OVERFLOW flag (not unsigned carry bit)
--
-- C = '1' when result cannot fit in 32-bit signed range:
--   - ADD: same sign inputs, different sign result
--   - SUB: invalid sign change after subtraction
--   - INC: treated as ADD with 1, overflow applies
--
-- C = '0' otherwise
--
-- NOTE:
-- This is NOT an unsigned ALU, so C does NOT represent a real carry-out.
--------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ALU IS
    PORT (
        operand1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- input A
        operand2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- input B
        alu_op : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- operation select

        alu_result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- result
        alu_flags : OUT STD_LOGIC_VECTOR(2 DOWNTO 0) -- [2]=C, [1]=N, [0]=Z
    );
END ALU;

ARCHITECTURE behavioral OF ALU IS
    SIGNAL result_temp : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL flags_temp : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN

    -- combinational ALU (no clock)
    PROCESS (operand1, operand2, alu_op)
        VARIABLE a, b, r : signed(31 DOWNTO 0); -- signed operands/result
        VARIABLE z, n, c : STD_LOGIC; -- flags
    BEGIN
        -- convert inputs to signed
        a := signed(operand1);
        b := signed(operand2);

        -- select operation
        CASE alu_op IS

            WHEN "000" => -- NOP: output zero
                r := (OTHERS => '0');

            WHEN "001" => -- NOT: bitwise invert A
                r := NOT a;
                c := '0';

            WHEN "010" => -- INC: A + 1
                r := a + 1;
                -- signed overflow: + → - (was positive -> became -ve bec u overflew)
                IF (a(31) = '0' AND r(31) = '1') THEN
                    c := '1';
                ELSE
                    c := '0';
                END IF;

            WHEN "011" => -- MOV: pass A
                r := a;
                c := '0';

            WHEN "100" => -- ADD: A + B
                r := a + b;
                -- signed overflow: same sign inputs, different sign result
                IF (a(31) = b(31)) AND (r(31) /= a(31)) THEN
                    c := '1';
                ELSE
                    c := '0';
                END IF;

            WHEN "101" => -- SUB: A - B
                r := a - b;
                -- signed overflow: different sign inputs, wrong sign result
                IF (a(31) /= b(31)) AND (r(31) /= a(31)) THEN
                    c := '1';
                ELSE
                    c := '0';
                END IF;

            WHEN "110" => -- AND: bitwise AND
                r := a AND b;
                c := '0';

            WHEN "111" => -- PASS: same as MOV
                r := a;
                c := '0';

            WHEN OTHERS =>
                r := (OTHERS => '0');
                c := '0';

        END CASE;

        -- flag generation
        IF r = 0 THEN
            z := '1';
        ELSE
            z := '0';
        END IF;
        n := r(31); -- sign bit
        -- c = signed overflow (not unsigned carry) -> computed above

        -- outputs
        result_temp <= STD_LOGIC_VECTOR(r);
        flags_temp <= c & n & z;

    END PROCESS;

    alu_result <= result_temp;
    alu_flags <= flags_temp;

END behavioral;