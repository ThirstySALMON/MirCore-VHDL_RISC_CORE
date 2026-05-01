--------------------------------------------------------------------------------
-- ALU Testbench (UNSIGNED VERSION)
--------------------------------------------------------------------------------

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
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY alu_tb IS
END alu_tb;

ARCHITECTURE behavioral OF alu_tb IS

    SIGNAL operand1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL operand2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_op : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL alu_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_flags : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL z_flag : STD_LOGIC;
    SIGNAL n_flag : STD_LOGIC;
    SIGNAL c_flag : STD_LOGIC;

    SIGNAL test_count : INTEGER := 0;
    SIGNAL pass_count : INTEGER := 0;
    SIGNAL fail_count : INTEGER := 0;

BEGIN

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : ENTITY work.ALU
        PORT MAP(
            operand1 => operand1,
            operand2 => operand2,
            alu_op => alu_op,
            alu_result => alu_result,
            alu_flags => alu_flags
        );

    z_flag <= alu_flags(0);
    n_flag <= alu_flags(1);
    c_flag <= alu_flags(2);

    --------------------------------------------------------------------------
    -- TEST PROCESS
    --------------------------------------------------------------------------
    PROCESS

        VARIABLE L : line;

        PROCEDURE test_alu (
            op1_val : STD_LOGIC_VECTOR(31 DOWNTO 0);
            op2_val : STD_LOGIC_VECTOR(31 DOWNTO 0);
            op : STD_LOGIC_VECTOR(2 DOWNTO 0);
            expected_res : STD_LOGIC_VECTOR(31 DOWNTO 0);
            expected_z : STD_LOGIC;
            expected_n : STD_LOGIC;
            expected_c : STD_LOGIC;
            test_name : STRING
        ) IS
        BEGIN

            test_count <= test_count + 1;

            operand1 <= op1_val;
            operand2 <= op2_val;
            alu_op <= op;

            WAIT FOR 10 ns;

            IF (alu_result = expected_res AND
                z_flag = expected_z AND
                n_flag = expected_n AND
                c_flag = expected_c) THEN

                write(L, STRING'("[PASS] "));
                write(L, test_name);
                write(L, STRING'(" -> 0x"));
                hwrite(L, alu_result);
                writeline(output, L);

                pass_count <= pass_count + 1;

            ELSE

                write(L, STRING'("[FAIL] "));
                write(L, test_name);
                writeline(output, L);

                write(L, STRING'(" Expected: 0x"));
                hwrite(L, expected_res);
                writeline(output, L);

                write(L, STRING'(" Got:      0x"));
                hwrite(L, alu_result);
                writeline(output, L);

                fail_count <= fail_count + 1;

            END IF;

        END PROCEDURE;

    BEGIN

        ----------------------------------------------------------------------
        -- 000 NOP
        ----------------------------------------------------------------------
        test_alu(x"12345678", x"00000000", "000",
        x"00000000", '1', '0', '0', "NOP");

        ----------------------------------------------------------------------
        -- 001 NOT (bitwise)
        ----------------------------------------------------------------------
        test_alu(x"00000000", x"00000000", "001",
        x"FFFFFFFF", '0', '1', '0', "NOT 0");

        test_alu(x"FFFFFFFF", x"00000000", "001",
        x"00000000", '1', '0', '0', "NOT F");

        ----------------------------------------------------------------------
        -- 010 INC (unsigned)
        ----------------------------------------------------------------------
        test_alu(x"00000005", x"00000000", "010",
        x"00000006", '0', '0', '0', "INC");

        test_alu(x"FFFFFFFF", x"00000000", "010",
        x"00000000", '1', '0', '0', "INC overflow");

        ----------------------------------------------------------------------
        -- 011 MOV
        ----------------------------------------------------------------------
        test_alu(x"12345678", x"00000000", "011",
        x"12345678", '0', '0', '0', "MOV");

        ----------------------------------------------------------------------
        -- 100 ADD (signed carry)
        ----------------------------------------------------------------------
        test_alu(x"00000005", x"00000003", "100",
        x"00000008", '0', '0', '0', "ADD");

        test_alu(x"FFFFFFFF", x"00000001", "100",
        x"00000000", '1', '0', '0', "ADD carry");

        ----------------------------------------------------------------------
        -- 101 SUB (signed borrow)
        ----------------------------------------------------------------------
        test_alu(x"0000000A", x"00000003", "101",
        x"00000007", '0', '0', '0', "SUB");

        test_alu(x"00000000", x"00000001", "101",
        x"FFFFFFFF", '0', '1', '0', "SUB borrow");

        ----------------------------------------------------------------------
        -- 110 AND
        ----------------------------------------------------------------------
        test_alu(x"FFFF0000", x"0FFF0000", "110",
        x"0FFF0000", '0', '0', '0', "AND");

        test_alu(x"FFFFFFFF", x"00000000", "110",
        x"00000000", '1', '0', '0', "AND zero");

        ----------------------------------------------------------------------
        -- 111 PASS
        ----------------------------------------------------------------------
        test_alu(x"DEADBEEF", x"00000000", "111",
        x"DEADBEEF", '0', '1', '0', "PASS");

        ----------------------------------------------------------------------
        -- SUMMARY
        ----------------------------------------------------------------------
        WAIT FOR 10 ns;

        write(L, STRING'("============== SUMMARY =============="));
        writeline(output, L);

        write(L, STRING'("Total: "));
        write(L, test_count);
        writeline(output, L);

        write(L, STRING'("Passed: "));
        write(L, pass_count);
        writeline(output, L);

        write(L, STRING'("Failed: "));
        write(L, fail_count);
        writeline(output, L);

        WAIT;
    END PROCESS;

END behavioral;