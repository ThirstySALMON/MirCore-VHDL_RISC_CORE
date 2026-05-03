--------------------------------------------------------------------------------
-- Conditional Jump Decoder Testbench 
--
-- - Correct 32-bit instruction construction
-- - Tests conditional detection + immediate extraction
-- - Clean logging (PASS / FAIL)
-- - Covers edge cases and random inputs
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY conditional_jump_decoder_tb IS
END conditional_jump_decoder_tb;

ARCHITECTURE behavioral OF conditional_jump_decoder_tb IS

    SIGNAL instr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL imm16 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL is_conditional_branch : STD_LOGIC;

    SIGNAL test_count : INTEGER := 0;
    SIGNAL pass_count : INTEGER := 0;
    SIGNAL fail_count : INTEGER := 0;

    --------------------------------------------------------------------------
    -- Helper function to build J-type instruction (SAFE)
    --------------------------------------------------------------------------
    FUNCTION make_j_type(
        opcode : STD_LOGIC_VECTOR(4 DOWNTO 0);
        imm    : STD_LOGIC_VECTOR(15 DOWNTO 0)
    ) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        RETURN opcode & "00000000000" & imm; -- 5 + 11 + 16 = 32 bits
    END;

BEGIN

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : ENTITY work.conditional_jump_decoder
        PORT MAP(
            instr => instr,
            imm16 => imm16,
            is_conditional_branch => is_conditional_branch
        );

    --------------------------------------------------------------------------
    -- TEST PROCESS
    --------------------------------------------------------------------------
    PROCESS

        VARIABLE L : line;

        PROCEDURE test_decoder (
            instr_val : STD_LOGIC_VECTOR(31 DOWNTO 0);
            exp_imm   : STD_LOGIC_VECTOR(15 DOWNTO 0);
            exp_cond  : STD_LOGIC;
            test_name : STRING
        ) IS
        BEGIN

            test_count <= test_count + 1;

            instr <= instr_val;

            WAIT FOR 10 ns;

            IF (imm16 = exp_imm AND is_conditional_branch = exp_cond) THEN

                write(L, STRING'("[PASS] "));
                write(L, test_name);
                write(L, STRING'(" | IMM=0x"));
                hwrite(L, imm16);
                write(L, STRING'(" | COND="));
                write(L, is_conditional_branch);
                writeline(output, L);

                pass_count <= pass_count + 1;

            ELSE

                write(L, STRING'("[FAIL] "));
                write(L, test_name);
                writeline(output, L);

                write(L, STRING'("  Expected IMM=0x"));
                hwrite(L, exp_imm);
                write(L, STRING'(" COND="));
                write(L, exp_cond);
                writeline(output, L);

                write(L, STRING'("  Got      IMM=0x"));
                hwrite(L, imm16);
                write(L, STRING'(" COND="));
                write(L, is_conditional_branch);
                writeline(output, L);

                fail_count <= fail_count + 1;

            END IF;

        END PROCEDURE;

    BEGIN

        ----------------------------------------------------------------------
        -- TEST SET 1: CONDITIONAL JUMPS
        ----------------------------------------------------------------------
        write(L, STRING'("======== CONDITIONAL JUMPS ========"));
        writeline(output, L);

        test_decoder(make_j_type("10010", x"1234"), x"1234", '1', "JZ normal");
        test_decoder(make_j_type("10011", x"FFFF"), x"FFFF", '1', "JN max imm");
        test_decoder(make_j_type("10100", x"0000"), x"0000", '1', "JC zero imm");

        ----------------------------------------------------------------------
        -- TEST SET 2: NON-CONDITIONAL JUMPS
        ----------------------------------------------------------------------
        write(L, STRING'(""));
        write(L, STRING'("======== NON-CONDITIONAL JUMPS ========"));
        writeline(output, L);

        test_decoder(make_j_type("10101", x"AAAA"), x"AAAA", '0', "JMP");
        test_decoder(make_j_type("10110", x"5555"), x"5555", '0', "CALL");

        ----------------------------------------------------------------------
        -- TEST SET 3: NON-BRANCH INSTRUCTIONS
        ----------------------------------------------------------------------
        write(L, STRING'(""));
        write(L, STRING'("======== NON-BRANCH INSTRUCTIONS ========"));
        writeline(output, L);

        test_decoder("00000" & "000000000000000000000000000", x"0000", '0', "NOP");
        test_decoder("01001" & "000000000000000000000000000", x"0000", '0', "ADD");

        ----------------------------------------------------------------------
        -- TEST SET 4: EDGE CASES
        ----------------------------------------------------------------------
        write(L, STRING'(""));
        write(L, STRING'("======== EDGE CASES ========"));
        writeline(output, L);

        test_decoder(x"00000000", x"0000", '0', "All zeros");
        test_decoder(x"FFFFFFFF", x"FFFF", '0', "All ones");
        test_decoder(x"A5A5A5A5", x"A5A5", '1', "Random pattern");

        ----------------------------------------------------------------------
        -- SUMMARY
        ----------------------------------------------------------------------
        WAIT FOR 10 ns;

        writeline(output, L);
        write(L, STRING'("========================================"));
        writeline(output, L);
        write(L, STRING'("TEST SUMMARY"));
        writeline(output, L);
        write(L, STRING'("========================================"));
        writeline(output, L);

        write(L, STRING'("Total Tests: "));
        write(L, test_count);
        writeline(output, L);

        write(L, STRING'("Passed:      "));
        write(L, pass_count);
        writeline(output, L);

        write(L, STRING'("Failed:      "));
        write(L, fail_count);
        writeline(output, L);

        IF fail_count = 0 THEN
            write(L, STRING'("[SUCCESS] ALL TESTS PASSED"));
        ELSE
            write(L, STRING'("[FAILURE] SOME TESTS FAILED"));
        END IF;

        writeline(output, L);

        WAIT;

    END PROCESS;

END behavioral;