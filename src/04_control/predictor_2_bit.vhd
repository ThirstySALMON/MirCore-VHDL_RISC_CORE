--------------------------------------------------------------------------------
-- 2-BIT BRANCH PREDICTION UNIT
--------------------------------------------------------------------------------
-- Note: that we update states on falling edge not rising (better)
-- STATE MACHINE DEFINITION:
-- The predictor uses a 2-bit saturating counter with four states:
--
--   11 (Strong Predict Taken)
--     Taken ──→ 11 (stay)
--     Not Taken ──→ 10
--
--   10 (Weak Predict Taken)
--     Taken ──→ 11
--     Not Taken ──→ 00
--
--   01 (Weak Predict Not Taken)
--     Taken ──→ 11
--     Not Taken ──→ 00
--
--   00 (Strong Predict Not Taken)
--     Taken ──→ 01
--     Not Taken ──→ 00 (stay)
--
-- STATE UPDATE (Synchronous - updates on clock edge):
--   - Updates on every rising clock edge based on prev_prediction
--   - Only transitions on valid feedback: prev_prediction = "01" or "10"
--   - Ignores "00" and "11" (no state change)
--   - Uses clock to ensure consistent state updates even with same prev_prediction value
--
-- OUTPUT PREDICTION (Combinational):
--   - predicted_taken = '1' if state is 11 or 10 (predict taken)
--   - predicted_taken = '0' if state is 01 or 00 (predict not taken)
--   - predicted_taken = '0' if is_conditional_branch = '0' (default safe)
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY predictor_2_bit IS
    PORT (
        clk : IN STD_LOGIC; -- Clock for state updates
        rst : IN STD_LOGIC; -- Asynchronous reset to 00
        prev_prediction : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- Feedback from hazard unit
        is_conditional_branch : IN STD_LOGIC; -- Current instruction is conditional branch
        predicted_taken : OUT STD_LOGIC -- Prediction output (combinational)
    );
END ENTITY predictor_2_bit;

ARCHITECTURE rtl OF predictor_2_bit IS

    -- State register: holds current prediction state
    SIGNAL state : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

    -- Update state on falling clock edge based on prev_prediction feedback
    -- This allows multiple consecutive same values to trigger repeated updates
    PROCESS (clk, rst)
        VARIABLE next_state : STD_LOGIC_VECTOR(1 DOWNTO 0);
    BEGIN
        IF rst = '1' THEN
            -- Asynchronous reset to Strong Predict Not Taken
            state <= "00";
        ELSIF falling_edge(clk) THEN
            -- Calculate next state based on current state and feedback
            next_state := state; -- Default: hold current state

            -- Only update on valid feedback
            IF prev_prediction = "01" OR prev_prediction = "10" THEN
                CASE state IS
                        -- Strong Predict Taken (11)
                    WHEN "11" =>
                        IF prev_prediction = "10" THEN
                            -- Predicted taken, was taken: stay in 11
                            next_state := "11";
                        ELSE -- prev_prediction = "01"
                            -- Predicted taken, was NOT taken: go to 10
                            next_state := "10";
                        END IF;

                        -- Weak Predict Taken (10)
                    WHEN "10" =>
                        IF prev_prediction = "10" THEN
                            -- Predicted taken, was taken: go to 11
                            next_state := "11";
                        ELSE -- prev_prediction = "01"
                            -- Predicted taken, was NOT taken: go to 00
                            next_state := "00";
                        END IF;

                        -- Weak Predict Not Taken (01)
                    WHEN "01" =>
                        IF prev_prediction = "10" THEN
                            -- Predicted not taken, was taken: go to 11
                            next_state := "11";
                        ELSE -- prev_prediction = "01"
                            -- Predicted not taken, was NOT taken: go to 00
                            next_state := "00";
                        END IF;

                        -- Strong Predict Not Taken (00)
                    WHEN "00" =>
                        IF prev_prediction = "10" THEN
                            -- Predicted not taken, was taken: go to 01
                            next_state := "01";
                        ELSE -- prev_prediction = "01"
                            -- Predicted not taken, was NOT taken: stay in 00
                            next_state := "00";
                        END IF;

                    WHEN OTHERS =>
                        next_state := "00";
                END CASE;
            END IF;

            -- Update state on falling clock edge
            state <= next_state;
        END IF;
    END PROCESS;

    -- Output prediction based on current state and instruction type
    predicted_taken <= '1' WHEN (is_conditional_branch = '1' AND (state = "11" OR state = "10"))
        ELSE
        '0';

END ARCHITECTURE rtl;