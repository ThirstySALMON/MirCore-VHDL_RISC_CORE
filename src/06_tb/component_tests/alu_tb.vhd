--------------------------------------------------------------------------------
-- ALU Testbench (COMPREHENSIVE WITH UNSIGNED CARRY)
-- 
-- Tests all 8 ALU operations with:
-- - Basic cases
-- - Edge cases (overflow, underflow, zero, negative)
-- - Signed interpretation with unsigned carry detection
-- - All flag combinations (Z, N, C)
--
-- Carry Flag Interpretation:
--   - For ADD: C = 1 if unsigned result > 2^32-1 (overflow)
--   - For SUB: C = 1 if unsigned A < B (borrow/underflow)
--   - For INC: C = 1 if unsigned A + 1 > 2^32-1 (overflow)
--   - For other ops: C = 0 (no carry)
--
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

    SIGNAL z_flag : STD_LOGIC; -- Bit 0: Zero flag
    SIGNAL n_flag : STD_LOGIC; -- Bit 1: Negative flag
    SIGNAL c_flag : STD_LOGIC; -- Bit 2: Carry flag

    SIGNAL test_count : INTEGER := 0;
    SIGNAL pass_count : INTEGER := 0;
    SIGNAL fail_count : INTEGER := 0;

BEGIN

    --------------------------------------------------------------------------
    -- Device Under Test (DUT)
    --------------------------------------------------------------------------
    DUT : ENTITY work.ALU
        PORT MAP(
            operand1 => operand1,
            operand2 => operand2,
            alu_op => alu_op,
            alu_result => alu_result,
            alu_flags => alu_flags
        );

    -- Extract individual flags for easier reading
    z_flag <= alu_flags(0);
    n_flag <= alu_flags(1);
    c_flag <= alu_flags(2);

    --------------------------------------------------------------------------
    -- TEST PROCESS
    --------------------------------------------------------------------------
    PROCESS

        VARIABLE L : line;

        -- Test procedure: set inputs, wait, check outputs
        PROCEDURE test_alu (
            op1_val : STD_LOGIC_VECTOR(31 DOWNTO 0);
            op2_val : STD_LOGIC_VECTOR(31 DOWNTO 0);
            op : STD_LOGIC_VECTOR(2 DOWNTO 0);
            exp_res : STD_LOGIC_VECTOR(31 DOWNTO 0);
            exp_z : STD_LOGIC;
            exp_n : STD_LOGIC;
            exp_c : STD_LOGIC;
            test_name : STRING
        ) IS
        BEGIN

            test_count <= test_count + 1;

            -- Apply inputs
            operand1 <= op1_val;
            operand2 <= op2_val;
            alu_op <= op;

            -- Wait for combinatorial logic to settle
            WAIT FOR 10 ns;

            -- Check if outputs match expected
            IF (alu_result = exp_res AND
                z_flag = exp_z AND
                n_flag = exp_n AND
                c_flag = exp_c) THEN

                -- TEST PASSED
                write(L, STRING'("[PASS] "));
                write(L, test_name);
                write(L, STRING'(" -> Result: 0x"));
                hwrite(L, alu_result);
                write(L, STRING'(" Flags[Z,N,C]="));
                write(L, z_flag);
                write(L, n_flag);
                write(L, c_flag);
                writeline(output, L);

                pass_count <= pass_count + 1;

            ELSE

                -- TEST FAILED
                write(L, STRING'("[FAIL] "));
                write(L, test_name);
                writeline(output, L);

                write(L, STRING'("  Expected: 0x"));
                hwrite(L, exp_res);
                write(L, STRING'(" Flags[Z,N,C]="));
                write(L, exp_z);
                write(L, exp_n);
                write(L, exp_c);
                writeline(output, L);

                write(L, STRING'("  Got:      0x"));
                hwrite(L, alu_result);
                write(L, STRING'(" Flags[Z,N,C]="));
                write(L, z_flag);
                write(L, n_flag);
                write(L, c_flag);
                writeline(output, L);

                fail_count <= fail_count + 1;

            END IF;

        END PROCEDURE;

    BEGIN

        -- TEST SET 1: NOP OPERATION (000)
        write(output, STRING'(""));
        write(output, STRING'("======== TEST SET 1: NOP (000) ========"));
        writeline(output, L);

        -- NOP should always output zero with Z=1
        test_alu(x"12345678", x"ABCDEF00", "000",
        x"00000000", '1', '0', '0',
        "NOP: basic (should zero out)");

        test_alu(x"FFFFFFFF", x"FFFFFFFF", "000",
        x"00000000", '1', '0', '0',
        "NOP: with all ones inputs");

        test_alu(x"7FFFFFFF", x"80000000", "000",
        x"00000000", '1', '0', '0',
        "NOP: ignores all operands");

        -- TEST SET 2: NOT OPERATION (001)
        write(output, STRING'(""));
        write(output, STRING'("======== TEST SET 2: NOT (001) ========"));
        writeline(output, L);

        -- NOT(0x00000000) = 0xFFFFFFFF (all bits inverted)
        test_alu(x"00000000", x"00000000", "001",
        x"FFFFFFFF", '0', '1', '0',
        "NOT(0): all bits set -> negative");

        -- NOT(0xFFFFFFFF) = 0x00000000 (invert all 1s gives 0)
        test_alu(x"FFFFFFFF", x"FFFFFFFF", "001",
        x"00000000", '1', '0', '0',
        "NOT(all 1s): gives zero");

        -- NOT(0xAAAAAAAA) = 0x55555555
        test_alu(x"AAAAAAAA", x"55555555", "001",
        x"55555555", '0', '0', '0',
        "NOT(alternating pattern 1)");

        -- NOT(0x55555555) = 0xAAAAAAAA
        test_alu(x"55555555", x"AAAAAAAA", "001",
        x"AAAAAAAA", '0', '1', '0',
        "NOT(alternating pattern 2)");

        -- NOT(0x00000001) = 0xFFFFFFFE
        test_alu(x"00000001", x"12345678", "001",
        x"FFFFFFFE", '0', '1', '0',
        "NOT(1): flips all bits");

        -- NOT(0x7FFFFFFF) = 0x80000000 (flips sign bit)
        test_alu(x"7FFFFFFF", x"00000000", "001",
        x"80000000", '0', '1', '0',
        "NOT(max positive): becomes negative");

        -- TEST SET 3: INC OPERATION (010)
        write(output, STRING'(""));
        write(output, STRING'("======== TEST SET 3: INC (010) ========"));
        writeline(output, L);

        -- INC(5) = 6 (basic increment)
        test_alu(x"00000005", x"FFFFFFFF", "010",
        x"00000006", '0', '0', '0',
        "INC(5) = 6: basic");

        -- INC(0) = 1
        test_alu(x"00000000", x"00000000", "010",
        x"00000001", '0', '0', '0',
        "INC(0) = 1: zero increment");

        -- INC(0x7FFFFFFF) = 0x80000000 (crosses into negative)
        test_alu(x"7FFFFFFF", x"00000000", "010",
        x"80000000", '0', '1', '0',
        "INC(max positive) = min negative: crosses sign");

        -- INC(0xFFFFFFFF) = 0x00000000 with CARRY (unsigned overflow)
        test_alu(x"FFFFFFFF", x"00000000", "010",
        x"00000000", '1', '0', '1',
        "INC(0xFFFFFFFF) overflows: C=1");

        -- INC(0xFFFFFFFE) = 0xFFFFFFFF
        test_alu(x"FFFFFFFE", x"00000000", "010",
        x"FFFFFFFF", '0', '1', '0',
        "INC(-2) = -1: stays negative");

        -- INC(0x80000000) = 0x80000001 (stays negative)
        test_alu(x"80000000", x"00000000", "010",
        x"80000001", '0', '1', '0',
        "INC(min negative) stays negative");
        -- TEST SET 4: MOV OPERATION (011)

        write(output, STRING'(""));
        write(output, STRING'("======== TEST SET 4: MOV (011) ========"));
        writeline(output, L);

        -- MOV copies operand1 (operand2 ignored)
        test_alu(x"12345678", x"ABCDEF00", "011",
        x"12345678", '0', '0', '0',
        "MOV: normal value");

        test_alu(x"00000000", x"FFFFFFFF", "011",
        x"00000000", '1', '0', '0',
        "MOV(0): operand2 ignored");

        test_alu(x"80000000", x"00000000", "011",
        x"80000000", '0', '1', '0',
        "MOV(min negative): sign preserved");

        test_alu(x"7FFFFFFF", x"7FFFFFFF", "011",
        x"7FFFFFFF", '0', '0', '0',
        "MOV(max positive): positive");

        test_alu(x"FFFFFFFF", x"00000000", "011",
        x"FFFFFFFF", '0', '1', '0',
        "MOV(-1): negative");

        -- TEST SET 5: ADD OPERATION (100)
        write(output, STRING'(""));
        write(output, STRING'("======== TEST SET 5: ADD (100) ========"));
        writeline(output, L);

        -- ADD(5, 3) = 8 (basic)
        test_alu(x"00000005", x"00000003", "100",
        x"00000008", '0', '0', '0',
        "ADD(5 + 3 = 8): basic");

        -- ADD(0, 0) = 0
        test_alu(x"00000000", x"00000000", "100",
        x"00000000", '1', '0', '0',
        "ADD(0 + 0 = 0): zero");

        -- ADD(0xFFFFFFFF, 1) = 0x00000000 with CARRY (unsigned overflow)
        test_alu(x"FFFFFFFF", x"00000001", "100",
        x"00000000", '1', '0', '1',
        "ADD(-1 + 1): unsigned overflow, C=1");

        -- ADD(0xFFFFFFFF, 0xFFFFFFFF) = 0xFFFFFFFE with CARRY
        test_alu(x"FFFFFFFF", x"FFFFFFFF", "100",
        x"FFFFFFFE", '0', '1', '1',
        "ADD(-1 + -1): negative, C=1");

        -- ADD(0x7FFFFFFF, 0x7FFFFFFF) = 0xFFFFFFFE (unsigned: 2^31-1 + 2^31-1 = 2^32-2, no overflow)
        test_alu(x"7FFFFFFF", x"7FFFFFFF", "100",
        x"FFFFFFFE", '0', '1', '0',
        "ADD(max + max): no unsigned overflow, C=0");

        -- ADD(0x80000000, 0x80000000) = 0x00000000 with CARRY
        test_alu(x"80000000", x"80000000", "100",
        x"00000000", '1', '0', '1',
        "ADD(min + min): wraps to 0, C=1");

        -- ADD(0x7FFFFFFF, 0x80000000) = 0xFFFFFFFF (no carry, just wraps)
        test_alu(x"7FFFFFFF", x"80000000", "100",
        x"FFFFFFFF", '0', '1', '0',
        "ADD(max pos + min neg): gives -1");

        -- ADD(0x40000000, 0x40000000) = 0x80000000 (unsigned: no overflow)
        test_alu(x"40000000", x"40000000", "100",
        x"80000000", '0', '1', '0',
        "ADD(large + large): no unsigned overflow, C=0");

        -- ADD(0x00000001, 0xFFFFFFFF) = 0x00000000 with CARRY
        test_alu(x"00000001", x"FFFFFFFF", "100",
        x"00000000", '1', '0', '1',
        "ADD(1 + -1 = 0): C=1 (unsigned overflow)");
        -- TEST SET 6: SUB OPERATION (101)
        write(output, STRING'(""));
        write(output, STRING'("======== TEST SET 6: SUB (101) ========"));
        writeline(output, L);

        -- SUB(10, 3) = 7 (basic)
        test_alu(x"0000000A", x"00000003", "101",
        x"00000007", '0', '0', '0',
        "SUB(10 - 3 = 7): basic");

        -- SUB(5, 5) = 0
        test_alu(x"00000005", x"00000005", "101",
        x"00000000", '1', '0', '0',
        "SUB(5 - 5 = 0): equal");

        -- SUB(0, 1) = -1 with CARRY (unsigned underflow/borrow)
        test_alu(x"00000000", x"00000001", "101",
        x"FFFFFFFF", '0', '1', '1',
        "SUB(0 - 1 = -1): borrow, C=1");

        -- SUB(1, 2) = -1 with CARRY (borrow)
        test_alu(x"00000001", x"00000002", "101",
        x"FFFFFFFF", '0', '1', '1',
        "SUB(1 - 2 = -1): borrow, C=1");

        -- SUB(0x80000000, 0x00000001) = 0x7FFFFFFF (unsigned: 2147483648 - 1 = 2147483647, no borrow)
        test_alu(x"80000000", x"00000001", "101",
        x"7FFFFFFF", '0', '0', '0',
        "SUB(min - 1): no borrow in unsigned, C=0");

        -- SUB(0x7FFFFFFF, 0x80000000) = 0xFFFFFFFF (unsigned: 2147483647 - 2147483648 = borrow)
        test_alu(x"7FFFFFFF", x"80000000", "101",
        x"FFFFFFFF", '0', '1', '1',
        "SUB(max - min): unsigned borrow, C=1");

        -- SUB(0xFFFFFFFF, 0xFFFFFFFF) = 0
        test_alu(x"FFFFFFFF", x"FFFFFFFF", "101",
        x"00000000", '1', '0', '0',
        "SUB(-1 - (-1) = 0)");

        -- SUB(0x00000000, 0x80000000) = 0x80000000 with CARRY
        test_alu(x"00000000", x"80000000", "101",
        x"80000000", '0', '1', '1',
        "SUB(0 - min): gives min, borrow");

        -- SUB(0x80000000, 0x80000000) = 0
        test_alu(x"80000000", x"80000000", "101",
        x"00000000", '1', '0', '0',
        "SUB(min - min = 0)");

        -- SUB(0x7FFFFFFF, 0x00000001) = 0x7FFFFFFE
        test_alu(x"7FFFFFFF", x"00000001", "101",
        x"7FFFFFFE", '0', '0', '0',
        "SUB(max - 1): stays positive");
        -- TEST SET 7: AND OPERATION (110)
        write(output, STRING'(""));
        write(output, STRING'("======== TEST SET 7: AND (110) ========"));
        writeline(output, L);

        -- AND(0xFFFF0000, 0x0FFF0000) = 0x0FFF0000
        test_alu(x"FFFF0000", x"0FFF0000", "110",
        x"0FFF0000", '0', '0', '0',
        "AND(mask): keeps common bits");

        -- AND(0xFFFFFFFF, 0x00000000) = 0x00000000 (AND with 0 is always 0)
        test_alu(x"FFFFFFFF", x"00000000", "110",
        x"00000000", '1', '0', '0',
        "AND(all 1s & all 0s = 0)");

        -- AND(0xAAAAAAAA, 0x55555555) = 0x00000000 (complementary patterns)
        test_alu(x"AAAAAAAA", x"55555555", "110",
        x"00000000", '1', '0', '0',
        "AND(alternating patterns = 0)");

        -- AND(0xF0F0F0F0, 0xF0F0F0F0) = 0xF0F0F0F0 (same)
        test_alu(x"F0F0F0F0", x"F0F0F0F0", "110",
        x"F0F0F0F0", '0', '1', '0',
        "AND(same value): result negative");

        -- AND(0x12345678, 0x87654321) = 0x02244220
        test_alu(x"12345678", x"87654321", "110",
        x"02244220", '0', '0', '0',
        "AND(random values)");

        -- AND(0xFFFFFFFF, 0xFFFFFFFF) = 0xFFFFFFFF
        test_alu(x"FFFFFFFF", x"FFFFFFFF", "110",
        x"FFFFFFFF", '0', '1', '0',
        "AND(all 1s & all 1s): stays -1");

        -- AND(0x80000000, 0xFFFFFFFF) = 0x80000000
        test_alu(x"80000000", x"FFFFFFFF", "110",
        x"80000000", '0', '1', '0',
        "AND(keeps sign bit)");
        -- TEST SET 8: PASS OPERATION (111)

        write(output, STRING'(""));
        write(output, STRING'("======== TEST SET 8: PASS (111) ========"));
        writeline(output, L);

        -- PASS copies operand1 (operand2 ignored)
        test_alu(x"DEADBEEF", x"CAFEBABE", "111",
        x"DEADBEEF", '0', '1', '0',
        "PASS(random): operand2 ignored");

        test_alu(x"00000000", x"FFFFFFFF", "111",
        x"00000000", '1', '0', '0',
        "PASS(0): zero");

        test_alu(x"7FFFFFFF", x"00000000", "111",
        x"7FFFFFFF", '0', '0', '0',
        "PASS(max positive): positive");

        test_alu(x"80000000", x"00000000", "111",
        x"80000000", '0', '1', '0',
        "PASS(min negative): negative");

        test_alu(x"FFFFFFFF", x"00000000", "111",
        x"FFFFFFFF", '0', '1', '0',
        "PASS(-1): negative");
        -- FINAL SUMMARY

        WAIT FOR 10 ns;

        writeline(output, L);
        write(L, STRING'("========================================"));
        writeline(output, L);
        write(L, STRING'("TEST SUMMARY"));
        writeline(output, L);
        write(L, STRING'("========================================"));
        writeline(output, L);

        write(L, STRING'("Total Tests:  "));
        write(L, test_count);
        writeline(output, L);

        write(L, STRING'("Passed:       "));
        write(L, pass_count);
        writeline(output, L);

        write(L, STRING'("Failed:       "));
        write(L, fail_count);
        writeline(output, L);

        write(L, STRING'("========================================"));
        writeline(output, L);

        IF fail_count = 0 THEN
            write(L, STRING'("[SUCCESS] ALL TESTS PASSED!"));
        ELSE
            write(L, STRING'("[FAILURE] SOME TESTS FAILED!"));
        END IF;
        writeline(output, L);

        write(L, STRING'("========================================"));
        writeline(output, L);

        WAIT;

    END PROCESS;

END behavioral;