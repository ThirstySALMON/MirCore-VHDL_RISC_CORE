LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY N_bit_register_TB IS
END N_bit_register_TB;

ARCHITECTURE testbench OF N_bit_register_TB IS

-- Component declaration
COMPONENT N_bit_register
GENERIC (
    N : INTEGER := 32
);
PORT (
    clk   : IN STD_LOGIC;
    rst   : IN STD_LOGIC;
    en    : IN STD_LOGIC;
    flush : IN STD_LOGIC;
    d     : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
    q     : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
);
END COMPONENT;

-- Signals
SIGNAL clk   : STD_LOGIC := '0';
SIGNAL rst   : STD_LOGIC := '0';
SIGNAL en    : STD_LOGIC := '0';
SIGNAL flush : STD_LOGIC := '0';
SIGNAL d     : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
SIGNAL q     : STD_LOGIC_VECTOR(31 DOWNTO 0);

-- Clock period constant
CONSTANT CLK_PERIOD : TIME := 10 ns;

BEGIN

-- Instantiate the N_bit_register
UUT : N_bit_register
GENERIC MAP (
    N => 32
)
PORT MAP (
    clk   => clk,
    rst   => rst,
    en    => en,
    flush => flush,
    d     => d,
    q     => q
);

-- Clock generation process
CLK_PROC : PROCESS
BEGIN
    clk <= '0';
    WAIT FOR CLK_PERIOD / 2;
    clk <= '1';
    WAIT FOR CLK_PERIOD / 2;
END PROCESS;

-- Main testbench process
TEST_PROC : PROCESS
BEGIN
    -- Test 1: Async Reset
    REPORT "Test 1: Async Reset";
    rst <= '1';
    en <= '0';
    flush <= '0';
    d <= X"DEADBEEF";
    WAIT FOR CLK_PERIOD;
    ASSERT q = X"00000000" REPORT "Reset failed" SEVERITY ERROR;
    REPORT "✓ Register cleared on reset";
    WAIT FOR CLK_PERIOD;
    
    -- Test 2: Normal Load (Enable without Reset)
    REPORT "Test 2: Normal Load with Enable";
    rst <= '0';
    en <= '1';
    flush <= '0';
    d <= X"12345678";
    WAIT FOR CLK_PERIOD;
    ASSERT q = X"12345678" REPORT "Data not loaded" SEVERITY ERROR;
    REPORT "✓ Data loaded successfully";
    WAIT FOR CLK_PERIOD;
    
    -- Test 3: Load Different Data
    REPORT "Test 3: Load Different Data";
    d <= X"ABCDEF00";
    WAIT FOR CLK_PERIOD;
    ASSERT q = X"ABCDEF00" REPORT "Data not updated" SEVERITY ERROR;
    REPORT "✓ Data updated successfully";
    WAIT FOR CLK_PERIOD;
    
    -- Test 4: Hold Data (Enable = 0)
    REPORT "Test 4: Hold Data when Enable = 0";
    en <= '0';
    d <= X"11111111";
    WAIT FOR CLK_PERIOD;
    ASSERT q = X"ABCDEF00" REPORT "Data should not change when en=0" SEVERITY ERROR;
    REPORT "✓ Data held correctly";
    WAIT FOR CLK_PERIOD;
    
    -- Test 5: Flush Signal
    REPORT "Test 5: Flush Signal";
    en <= '1';
    flush <= '1';
    d <= X"22222222";
    WAIT FOR CLK_PERIOD;
    ASSERT q = X"00000000" REPORT "Flush did not clear register" SEVERITY ERROR;
    REPORT "✓ Register flushed successfully";
    WAIT FOR CLK_PERIOD;
    
    -- Test 6: Flush has priority over Enable
    REPORT "Test 6: Flush has Priority over Enable";
    flush <= '1';
    en <= '1';
    d <= X"33333333";
    WAIT FOR CLK_PERIOD;
    ASSERT q = X"00000000" REPORT "Flush should take priority over enable" SEVERITY ERROR;
    REPORT "✓ Flush correctly prioritized";
    WAIT FOR CLK_PERIOD;
    
    -- Test 7: Normal operation after flush
    REPORT "Test 7: Normal Operation After Flush";
    flush <= '0';
    en <= '1';
    d <= X"FEDCBA98";
    WAIT FOR CLK_PERIOD;
    ASSERT q = X"FEDCBA98" REPORT "Normal load failed after flush" SEVERITY ERROR;
    REPORT "✓ Normal operation resumed";
    WAIT FOR CLK_PERIOD;
    
    -- Test 8: Reset takes priority over everything
    REPORT "Test 8: Async Reset Priority";
    rst <= '1';
    flush <= '0';
    en <= '1';
    d <= X"AAAAAAAA";
    WAIT FOR CLK_PERIOD;
    ASSERT q = X"00000000" REPORT "Reset should take priority" SEVERITY ERROR;
    REPORT "✓ Async reset correctly prioritized";
    WAIT FOR CLK_PERIOD;
    
    -- Cleanup
    REPORT "All tests passed!";
    WAIT;
    
END PROCESS;

END testbench;