library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file_tb is
end register_file_tb;

architecture behavior of register_file_tb is

    -- Component Declaration
    component register_file
        port (
            clk            : in  std_logic;
            rst            : in  std_logic;
            reg_write_en   : in  std_logic;
            reg_write_addr : in  std_logic_vector(2 downto 0);
            reg_write_data : in  std_logic_vector(31 downto 0);
            reg_read_addr1 : in  std_logic_vector(2 downto 0);
            reg_read_addr2 : in  std_logic_vector(2 downto 0);
            reg_read_data1 : out std_logic_vector(31 downto 0);
            reg_read_data2 : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Inputs
    signal clk            : std_logic := '0';
    signal rst            : std_logic := '0';
    signal reg_write_en   : std_logic := '0';
    signal reg_write_addr : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_write_data : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_read_addr1 : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_read_addr2 : std_logic_vector(2 downto 0) := (others => '0');

    -- Outputs
    signal reg_read_data1 : std_logic_vector(31 downto 0);
    signal reg_read_data2 : std_logic_vector(31 downto 0);

    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

    -- Helper procedure for checking results
    procedure check(
        signal_name : in string;
        actual       : in std_logic_vector(31 downto 0);
        expected     : in std_logic_vector(31 downto 0)
    ) is
    begin
        if actual = expected then
            report "[PASS] " & signal_name & " = 0x" &
                   integer'image(to_integer(unsigned(actual)));
        else
            report "[FAIL] " & signal_name &
                   " expected 0x" & integer'image(to_integer(unsigned(expected))) &
                   " but got 0x" & integer'image(to_integer(unsigned(actual)))
            severity error;
        end if;
    end procedure;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: register_file
        port map (
            clk            => clk,
            rst            => rst,
            reg_write_en   => reg_write_en,
            reg_write_addr => reg_write_addr,
            reg_write_data => reg_write_data,
            reg_read_addr1 => reg_read_addr1,
            reg_read_addr2 => reg_read_addr2,
            reg_read_data1 => reg_read_data1,
            reg_read_data2 => reg_read_data2
        );

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin

        -- -------------------------------------------------------
        -- TEST 1: Reset
        -- All registers should be cleared to 0
        -- -------------------------------------------------------
        report "=== TEST 1: Reset ===";
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;

        reg_read_addr1 <= "000";  -- R0
        reg_read_addr2 <= "111";  -- R7
        wait for 1 ns;            -- let signals settle (combinational read)
        check("R0 after reset", reg_read_data1, x"00000000");
        check("R7 after reset", reg_read_data2, x"00000000");

        -- -------------------------------------------------------
        -- TEST 2: Write then Read — R0 = 0xDEADBEEF
        -- -------------------------------------------------------
        report "=== TEST 2: Write R0 = 0xDEADBEEF, then read ===";
        reg_write_en   <= '1';
        reg_write_addr <= "000";              -- R0
        reg_write_data <= x"DEADBEEF";
        reg_read_addr1 <= "000";
        wait for CLK_PERIOD;                  -- rising edge latches the write
        reg_write_en <= '0';
        wait for 1 ns;
        check("R0 after write", reg_read_data1, x"DEADBEEF");

        -- -------------------------------------------------------
        -- TEST 3: Write R3 = 0x12345678, Read via port2
        -- -------------------------------------------------------
        report "=== TEST 3: Write R3 = 0x12345678, read via port2 ===";
        reg_write_en   <= '1';
        reg_write_addr <= "011";              -- R3
        reg_write_data <= x"12345678";
        reg_read_addr2 <= "011";
        wait for CLK_PERIOD;
        reg_write_en <= '0';
        wait for 1 ns;
        check("R3 after write", reg_read_data2, x"12345678");

        -- -------------------------------------------------------
        -- TEST 4: Write-then-Read Forwarding (same cycle)
        -- Writing to R5 while reading R5 should return new value
        -- -------------------------------------------------------
        report "=== TEST 4: Write-forwarding on read port 1 ===";
        reg_write_en   <= '1';
        reg_write_addr <= "101";              -- R5
        reg_write_data <= x"AABBCCDD";
        reg_read_addr1 <= "101";              -- read R5 same cycle
        wait for 1 ns;                        -- combinational forward, no clock needed
        check("R5 forwarded on port1", reg_read_data1, x"AABBCCDD");
        wait for CLK_PERIOD;
        reg_write_en <= '0';

        -- -------------------------------------------------------
        -- TEST 5: Write-then-Read Forwarding on port 2
        -- -------------------------------------------------------
        report "=== TEST 5: Write-forwarding on read port 2 ===";
        reg_write_en   <= '1';
        reg_write_addr <= "110";              -- R6
        reg_write_data <= x"CAFEBABE";
        reg_read_addr2 <= "110";
        wait for 1 ns;
        check("R6 forwarded on port2", reg_read_data2, x"CAFEBABE");
        wait for CLK_PERIOD;
        reg_write_en <= '0';

        -- -------------------------------------------------------
        -- TEST 6: No forwarding when addresses differ
        -- Writing R7, reading R2 — should still see old R2 value
        -- -------------------------------------------------------
        report "=== TEST 6: No spurious forwarding ===";
        reg_write_en   <= '1';
        reg_write_addr <= "111";              -- R7
        reg_write_data <= x"FFFFFFFF";
        reg_read_addr1 <= "010";              -- R2 (never written => 0)
        wait for 1 ns;
        check("R2 not affected by R7 write", reg_read_data1, x"00000000");
        wait for CLK_PERIOD;
        reg_write_en <= '0';

        -- -------------------------------------------------------
        -- TEST 7: Write to all registers R0–R7
        -- -------------------------------------------------------
        report "=== TEST 7: Write all registers ===";
        for i in 0 to 7 loop
            reg_write_en   <= '1';
            reg_write_addr <= std_logic_vector(to_unsigned(i, 3));
            reg_write_data <= std_logic_vector(to_unsigned(i * 16#11#, 32));
            wait for CLK_PERIOD;
        end loop;
        reg_write_en <= '0';
        wait for 1 ns;

        -- Read back a few
        reg_read_addr1 <= "010";   -- R2, expected 0x22
        reg_read_addr2 <= "110";   -- R6, expected 0x66
        wait for 1 ns;
        check("R2 = 0x22", reg_read_data1, x"00000022");
        check("R6 = 0x66", reg_read_data2, x"00000066");

        -- -------------------------------------------------------
        -- TEST 8: Reset clears previously written values
        -- -------------------------------------------------------
        report "=== TEST 8: Reset clears registers ===";
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for 1 ns;

        reg_read_addr1 <= "010";   -- R2
        reg_read_addr2 <= "110";   -- R6
        wait for 1 ns;
        check("R2 cleared by reset", reg_read_data1, x"00000000");
        check("R6 cleared by reset", reg_read_data2, x"00000000");

        -- -------------------------------------------------------
        -- TEST 9: Write disabled — register must not change
        -- -------------------------------------------------------
        report "=== TEST 9: Write disabled ===";
        reg_write_en   <= '0';
        reg_write_addr <= "001";   -- R1
        reg_write_data <= x"DEADBEEF";
        wait for CLK_PERIOD;
        reg_read_addr1 <= "001";
        wait for 1 ns;
        check("R1 unchanged (write disabled)", reg_read_data1, x"00000000");

        report "=== ALL TESTS COMPLETE ===";
        wait;
    end process;

end behavior;
