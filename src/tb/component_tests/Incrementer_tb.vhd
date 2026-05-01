LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY incrementer_TB IS
END incrementer_TB;

ARCHITECTURE testbench OF incrementer_TB IS

COMPONENT incrementer
GENERIC (
    N : INTEGER := 32
);
PORT (
    a      : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
    result : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
);
END COMPONENT;

SIGNAL a      : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL result : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

-- Instantiate the incrementer
UUT : incrementer
GENERIC MAP (
    N => 32
)
PORT MAP (
    a      => a,
    result => result
);

TEST_PROC : PROCESS
BEGIN

    -- Test 1: Increment 0 to 1
    REPORT "Test 1: Increment 0 to 1";
    a <= X"00000000";
    WAIT FOR 1 ns;
    ASSERT result = X"00000001" REPORT "Failed: 0 + 1 should be 1" SEVERITY ERROR;
    REPORT " 0 + 1 = 1";
    
    -- Test 2: Increment 1 to 2
    REPORT "Test 2: Increment 1 to 2";
    a <= X"00000001";
    WAIT FOR 1 ns;
    ASSERT result = X"00000002" REPORT "Failed: 1 + 1 should be 2" SEVERITY ERROR;
    REPORT " 1 + 1 = 2";
    
    -- Test 3: Increment 255 to 256
    REPORT "Test 3: Increment 255 to 256";
    a <= X"000000FF";
    WAIT FOR 1 ns;
    ASSERT result = X"00000100" REPORT "Failed: 255 + 1 should be 256" SEVERITY ERROR;
    REPORT " 255 + 1 = 256";
    
    -- Test 4: Increment large number
    REPORT "Test 4: Increment Large Number";
    a <= X"12345678";
    WAIT FOR 1 ns;
    ASSERT result = X"12345679" REPORT "Failed: Large number increment" SEVERITY ERROR;
    REPORT "0x12345678 + 1 = 0x12345679";
    
    -- Test 5: Wrap around (max 32-bit value to 0)
    REPORT "Test 5: Wrap Around (0xFFFFFFFF + 1)";
    a <= X"FFFFFFFF";
    WAIT FOR 1 ns;
    ASSERT result = X"00000000" REPORT "Failed: Overflow wrap around" SEVERITY ERROR;
    REPORT "0xFFFFFFFF + 1 = 0x00000000 (overflow)";
    
    -- Test 6: PC increment (typical fetch scenario)
    REPORT "Test 6: PC Increment Scenario";
    a <= X"00000010";
    WAIT FOR 1 ns;
    ASSERT result = X"00000011" REPORT "Failed: PC increment" SEVERITY ERROR;
    REPORT " PC: 0x10 + 1 = 0x11";
    
    REPORT "All tests passed!";
    WAIT;

END PROCESS;

END testbench;