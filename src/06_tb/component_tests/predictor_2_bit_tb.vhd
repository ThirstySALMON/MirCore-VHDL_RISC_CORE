--------------------------------------------------------------------------------
-- TESTBENCH FOR 2-BIT BRANCH PREDICTION UNIT
--------------------------------------------------------------------------------
-- Tests all states and transitions using the transition table:
--
-- STATE TRANSITION TABLE:
--   11 (Strong Predict Taken):
--     Taken (10) --> 11 (stay)
--     Not Taken (01) --> 10
--
--   10 (Weak Predict Taken):
--     Taken (10) --> 11
--     Not Taken (01) --> 00
--
--   01 (Weak Predict Not Taken):
--     Taken (10) --> 11
--     Not Taken (01) --> 00
--
--   00 (Strong Predict Not Taken):
--     Taken (10) --> 01
--     Not Taken (01) --> 00 (stay)
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY predictor_2_bit_tb IS
END ENTITY predictor_2_bit_tb;

ARCHITECTURE testbench OF predictor_2_bit_tb IS

    -- DUT signals
    SIGNAL clk : STD_LOGIC;
    SIGNAL rst : STD_LOGIC;
    SIGNAL prev_prediction : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL is_conditional_branch : STD_LOGIC;
    SIGNAL predicted_taken : STD_LOGIC;

    -- Test tracking
    SIGNAL test_count : INTEGER := 0;
    SIGNAL pass_count : INTEGER := 0;
    SIGNAL fail_count : INTEGER := 0;

    -- Clock period constant
    CONSTANT CLK_PERIOD : TIME := 100 ns;

BEGIN

    -- ========================================================================
    -- INSTANTIATE DEVICE UNDER TEST (DUT)
    -- ========================================================================
    dut : ENTITY work.predictor_2_bit
        PORT MAP(
            clk => clk,
            rst => rst,
            prev_prediction => prev_prediction,
            is_conditional_branch => is_conditional_branch,
            predicted_taken => predicted_taken
        );

    -- ========================================================================
    -- CLOCK GENERATION
    -- ========================================================================
    clock_gen : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR CLK_PERIOD / 2;
        clk <= '1';
        WAIT FOR CLK_PERIOD / 2;
    END PROCESS;
    -- ========================================================================
    -- TEST PROCESS - SEQUENTIAL STATE TRAVERSAL
    -- ========================================================================
    PROCESS
        VARIABLE line_out : line;
        VARIABLE expected : STD_LOGIC;
    BEGIN

        -- Print header
        write(line_out, STRING'("================================================================================"));
        writeline(output, line_out);
        write(line_out, STRING'("2-BIT BRANCH PREDICTOR TESTBENCH - SEQUENTIAL TRAVERSAL"));
        writeline(output, line_out);
        write(line_out, STRING'("================================================================================"));
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 1: RESET INITIALIZATION
        -- ====================================================================
        write(line_out, STRING'("[TEST 1] RESET - Initialize to 00 (Strong Predict Not Taken)"));
        writeline(output, line_out);
        rst <= '1';
        prev_prediction <= "00";
        is_conditional_branch <= '1';
        WAIT UNTIL rising_edge(clk);
        WAIT UNTIL rising_edge(clk); -- Wait for first clock edge

        test_count <= test_count + 1;
        expected := '0';
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Reset successful, state = 00, predicted_taken = 0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Reset failed, expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        rst <= '0';

        -- ====================================================================
        -- TEST 2: STATE 00 --> 01 --> 00 --> 01 --> 11
        -- ====================================================================
        -- Starting in state 00 (Strong Predict Not Taken)

        write(line_out, STRING'("[TEST 2] 00 + Taken (10) --> 01"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 00, sending feedback: 10 (branch was taken)"));
        writeline(output, line_out);
        prev_prediction <= "10";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '0'; -- State 01, still predict not taken
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Now in state 01, predicted_taken = 0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 3: 01 + Not Taken (01) --> 00
        -- ====================================================================
        write(line_out, STRING'("[TEST 3] 01 + NOT Taken (01) --> 00"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 01, sending feedback: 01 (branch NOT taken)"));
        writeline(output, line_out);
        prev_prediction <= "01";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '0'; -- State 00, predict not taken
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Back in state 00, predicted_taken = 0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 4: 00 + Not Taken (01) --> stay 00
        -- ====================================================================
        write(line_out, STRING'("[TEST 4] 00 + NOT Taken (01) --> stay 00"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 00, sending feedback: 01 (branch NOT taken)"));
        writeline(output, line_out);
        prev_prediction <= "01";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '0'; -- Still in state 00
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Stayed in state 00, predicted_taken = 0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 5: 00 + Taken (10) --> 01 (again)
        -- ====================================================================
        write(line_out, STRING'("[TEST 5] 00 + Taken (10) --> 01"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 00, sending feedback: 10 (branch WAS taken)"));
        writeline(output, line_out);
        prev_prediction <= "10";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '0'; -- State 01, predict not taken
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Now in state 01, predicted_taken = 0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 6: 01 + Taken (10) --> 11
        -- ====================================================================
        write(line_out, STRING'("[TEST 6] 01 + Taken (10) --> 11"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 01, sending feedback: 10 (branch WAS taken)"));
        writeline(output, line_out);
        prev_prediction <= "10";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '1'; -- State 11, predict taken
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Now in state 11, predicted_taken = 1"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 1, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 7: 11 + Taken (10) --> stay 11
        -- ====================================================================
        write(line_out, STRING'("[TEST 7] 11 + Taken (10) --> stay 11"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 11, sending feedback: 10 (branch WAS taken)"));
        writeline(output, line_out);
        prev_prediction <= "10";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '1'; -- Still in state 11
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Stayed in state 11, predicted_taken = 1"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 1, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 8: 11 + Not Taken (01) --> 10
        -- ====================================================================
        write(line_out, STRING'("[TEST 8] 11 + NOT Taken (01) --> 10"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 11, sending feedback: 01 (branch NOT taken)"));
        writeline(output, line_out);
        prev_prediction <= "01";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '1'; -- State 10, still predict taken
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Now in state 10, predicted_taken = 1"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 1, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 9: 10 + Taken (10) --> 11
        -- ====================================================================
        write(line_out, STRING'("[TEST 9] 10 + Taken (10) --> 11"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 10, sending feedback: 10 (branch WAS taken)"));
        writeline(output, line_out);
        prev_prediction <= "10";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '1'; -- State 11, predict taken
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Now in state 11, predicted_taken = 1"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 1, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 10: 11 + Not Taken (01) --> 10 (again)
        -- ====================================================================
        write(line_out, STRING'("[TEST 10] 11 + NOT Taken (01) --> 10"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 11, sending feedback: 01 (branch NOT taken)"));
        writeline(output, line_out);
        prev_prediction <= "01";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '1'; -- State 10, predict taken
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Now in state 10, predicted_taken = 1"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 1, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 11: 10 + Not Taken (01) --> 00
        -- ====================================================================
        write(line_out, STRING'("[TEST 11] 10 + NOT Taken (01) --> 00"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 10, sending feedback: 01 (branch NOT taken)"));
        writeline(output, line_out);
        prev_prediction <= "01";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '0'; -- State 00, predict not taken
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Now in state 00, predicted_taken = 0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 12: IGNORE FEEDBACK (00) - no state change
        -- ====================================================================
        write(line_out, STRING'("[TEST 12] 00 + Ignore (00) --> stay 00"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 00, sending feedback: 00 (ignore, no update)"));
        writeline(output, line_out);
        prev_prediction <= "00";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '0'; -- Still in state 00
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Stayed in state 00, predicted_taken = 0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 13: IGNORE FEEDBACK (11) - no state change
        -- ====================================================================
        write(line_out, STRING'("[TEST 13] 00 + Ignore (11) --> stay 00"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 00, sending feedback: 11 (ignore, no update)"));
        writeline(output, line_out);
        prev_prediction <= "11";
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '0'; -- Still in state 00
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Stayed in state 00, predicted_taken = 0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 14: is_conditional_branch = 0 (should output 0)
        -- ====================================================================
        -- First go back to state 11 using valid transitions
        write(line_out, STRING'("[SETUP] Going back to state 11 for conditional branch test"));
        writeline(output, line_out);
        prev_prediction <= "10"; -- 00 + taken --> 01
        WAIT UNTIL rising_edge(clk);
        prev_prediction <= "10"; -- 01 + taken --> 11
        WAIT UNTIL rising_edge(clk);
        writeline(output, line_out);

        write(line_out, STRING'("[TEST 14] State 11 + is_conditional_branch = 0 --> output 0"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 11, but is_conditional_branch=0"));
        writeline(output, line_out);
        is_conditional_branch <= '0';
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '0'; -- Output 0 because not a conditional branch
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Output 0 when is_conditional_branch=0"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 0, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST 15: is_conditional_branch = 1 (should output based on state)
        -- ====================================================================
        write(line_out, STRING'("[TEST 15] State 11 + is_conditional_branch = 1 --> output 1"));
        writeline(output, line_out);
        write(line_out, STRING'("  Current state: 11, is_conditional_branch=1"));
        writeline(output, line_out);
        is_conditional_branch <= '1';
        WAIT UNTIL rising_edge(clk);
        test_count <= test_count + 1;
        expected := '1'; -- Output 1 because in state 11 and is conditional
        IF predicted_taken = expected THEN
            write(line_out, STRING'("  PASS: Output 1 when state=11 and is_conditional_branch=1"));
            pass_count <= pass_count + 1;
        ELSE
            write(line_out, STRING'("  FAIL: Expected 1, got "));
            write(line_out, predicted_taken);
            fail_count <= fail_count + 1;
        END IF;
        writeline(output, line_out);
        writeline(output, line_out);

        -- ====================================================================
        -- TEST SUMMARY
        -- ====================================================================
        write(line_out, STRING'("================================================================================"));
        writeline(output, line_out);
        write(line_out, STRING'("TEST SUMMARY"));
        writeline(output, line_out);
        write(line_out, STRING'("================================================================================"));
        writeline(output, line_out);
        write(line_out, STRING'("Total Tests: "));
        write(line_out, test_count);
        writeline(output, line_out);
        write(line_out, STRING'("Passed:      "));
        write(line_out, pass_count);
        writeline(output, line_out);
        write(line_out, STRING'("Failed:      "));
        write(line_out, fail_count);
        writeline(output, line_out);
        write(line_out, STRING'("================================================================================"));
        writeline(output, line_out);

        IF fail_count = 0 THEN
            write(line_out, STRING'("ALL TESTS PASSED!"));
        ELSE
            write(line_out, STRING'("SOME TESTS FAILED!"));
        END IF;
        writeline(output, line_out);
        write(line_out, STRING'("================================================================================"));
        writeline(output, line_out);

        WAIT;
    END PROCESS;

END ARCHITECTURE testbench;