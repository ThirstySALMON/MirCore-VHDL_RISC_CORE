-- Test Bench for N-bit Register Module

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;



ENTITY N_register_tb IS
END N_register_tb;


ARCHITECTURE behavioral OF N_register_tb IS

    COMPONENT N_bit_register IS
        GENERIC (
            N : INTEGER := 32
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            d   : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
            q   : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
        );
    END COMPONENT;

    CONSTANT WIDTH      : INTEGER := 8;
    CONSTANT CLK_PERIOD : TIME    := 10 ns;

    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL d   : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL q   : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);

BEGIN

    uut : N_bit_register
        GENERIC MAP (N => WIDTH)
        PORT MAP (
            clk => clk,
            rst => rst,
            d   => d,
            q   => q
        );

    -- Clock generation
    clk_process : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR CLK_PERIOD / 2;
        clk <= '1';
        WAIT FOR CLK_PERIOD / 2;
    END PROCESS;

    stim_process : PROCESS
    BEGIN
        -- Test 1: Asynchronous reset clears the register
        rst <= '1';
        d   <= x"AA";
        WAIT FOR CLK_PERIOD;
        ASSERT q = x"00"
            REPORT "Test 1 FAILED: Expected 0x00 after reset, got "
            SEVERITY error;
        REPORT "Test 1 PASSED: Reset clears register to 0x00";

        -- Test 2: Load data on rising edge
        rst <= '0';
        d   <= x"5A";
        WAIT FOR CLK_PERIOD;
        ASSERT q = x"5A"
            REPORT "Test 2 FAILED: Expected 0x5A, got " 
            SEVERITY error;
        REPORT "Test 2 PASSED: Loaded 0x5A on rising edge";

        -- Test 3: Load a different value
        d <= x"F0";
        WAIT FOR CLK_PERIOD;
        ASSERT q = x"F0"
            REPORT "Test 3 FAILED: Expected 0xF0, got "
            SEVERITY error;
        REPORT "Test 3 PASSED: Loaded 0xF0 on rising edge";

        -- Test 4: Output holds when input is stable
        WAIT FOR CLK_PERIOD;
        ASSERT q = x"F0"
            REPORT "Test 4 FAILED: Expected 0xF0 to hold, got " 
            SEVERITY error;
        REPORT "Test 4 PASSED: Output holds 0xF0 across cycle";

        -- Test 5: Reset overrides input asynchronously
        d   <= x"FF";
        rst <= '1';
        WAIT FOR CLK_PERIOD / 4;
        ASSERT q = x"00"
            REPORT "Test 5 FAILED: Expected 0x00 on async reset, got " 
            SEVERITY error;
        REPORT "Test 5 PASSED: Async reset overrides input";

        WAIT;
    END PROCESS;

END behavioral;
