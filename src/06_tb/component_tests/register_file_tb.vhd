library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file_tb is
end register_file_tb;

architecture behavior of register_file_tb is

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

    signal clk            : std_logic := '0';
    signal rst            : std_logic := '0';
    signal reg_write_en   : std_logic := '0';
    signal reg_write_addr : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_write_data : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_read_addr1 : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_read_addr2 : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_read_data1 : std_logic_vector(31 downto 0);
    signal reg_read_data2 : std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    procedure check(
        signal_name : in string;
        actual      : in std_logic_vector(31 downto 0);
        expected    : in std_logic_vector(31 downto 0)
    ) is
    begin
        if actual = expected then
            report "[PASS] " & signal_name &
                   " = 0x" & integer'image(to_integer(unsigned(actual)));
        else
            report "[FAIL] " & signal_name &
                   " | expected 0x" & integer'image(to_integer(unsigned(expected))) &
                   " | got 0x"      & integer'image(to_integer(unsigned(actual)))
            severity error;
        end if;
    end procedure;

begin

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

    -- Clock: rises at 5ns, 15ns, 25ns ...
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc: process
    begin

        -- -------------------------------------------------------
        -- TEST 1: Reset — all registers must read 0
        -- -------------------------------------------------------
        report "=== TEST 1: Reset ===";
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;              -- settle after edge
        rst <= '0';

        reg_read_addr1 <= "000";
        reg_read_addr2 <= "111";
        wait for 1 ns;
        check("R0 after reset", reg_read_data1, x"00000000");
        check("R7 after reset", reg_read_data2, x"00000000");

        -- -------------------------------------------------------
        -- TEST 2: Write R0 = 0xDEADBEEF, read back
        -- Key fix: set inputs → wait for rising_edge → check
        -- -------------------------------------------------------
        report "=== TEST 2: Write R0 = 0xDEADBEEF ===";
        reg_write_en   <= '1';
        reg_write_addr <= "000";
        reg_write_data <= x"DEADBEEF";
        reg_read_addr1 <= "000";
        wait until rising_edge(clk); -- latch happens HERE
        wait for 1 ns;               -- let output settle
        reg_write_en <= '0';
        check("R0 after write", reg_read_data1, x"DEADBEEF");

        -- -------------------------------------------------------
        -- TEST 3: Write R3 = 0x12345678, read via port 2
        -- -------------------------------------------------------
        report "=== TEST 3: Write R3 = 0x12345678 ===";
        reg_write_en   <= '1';
        reg_write_addr <= "011";
        reg_write_data <= x"12345678";
        reg_read_addr2 <= "011";
        wait until rising_edge(clk);
        wait for 1 ns;
        reg_write_en <= '0';
        check("R3 after write", reg_read_data2, x"12345678");

        -- -------------------------------------------------------
        -- TEST 4: Write-forwarding on port 1
        -- Combinational bypass: new value visible BEFORE clock edge
        -- -------------------------------------------------------
        report "=== TEST 4: Forwarding port 1 ===";
        reg_write_en   <= '1';
        reg_write_addr <= "101";
        reg_write_data <= x"AABBCCDD";
        reg_read_addr1 <= "101";
        wait for 1 ns;               -- no clock needed, purely combinational
        check("R5 forwarded port1", reg_read_data1, x"AABBCCDD");
        wait until rising_edge(clk);
        wait for 1 ns;
        reg_write_en <= '0';

        -- -------------------------------------------------------
        -- TEST 5: Write-forwarding on port 2
        -- -------------------------------------------------------
        report "=== TEST 5: Forwarding port 2 ===";
        reg_write_en   <= '1';
        reg_write_addr <= "110";
        reg_write_data <= x"CAFEBABE";
        reg_read_addr2 <= "110";
        wait for 1 ns;
        check("R6 forwarded port2", reg_read_data2, x"CAFEBABE");
        wait until rising_edge(clk);
        wait for 1 ns;
        reg_write_en <= '0';

        -- -------------------------------------------------------
        -- TEST 6: No spurious forwarding
        -- Writing R7 must NOT affect read of R2
        -- -------------------------------------------------------
        report "=== TEST 6: No spurious forwarding ===";
        reg_write_en   <= '1';
        reg_write_addr <= "111";
        reg_write_data <= x"FFFFFFFF";
        reg_read_addr1 <= "010";     -- R2 never written → still 0
        wait for 1 ns;
        check("R2 unaffected by R7 write", reg_read_data1, x"00000000");
        wait until rising_edge(clk);
        wait for 1 ns;
        reg_write_en <= '0';

        -- -------------------------------------------------------
        -- TEST 7: Write all registers R0–R7, read back two
        -- -------------------------------------------------------
        report "=== TEST 7: Write all registers ===";
        for i in 0 to 7 loop
            reg_write_en   <= '1';
            reg_write_addr <= std_logic_vector(to_unsigned(i, 3));
            reg_write_data <= std_logic_vector(to_unsigned(i * 16#11#, 32));
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        reg_write_en <= '0';

        reg_read_addr1 <= "010";     -- R2 → 0x00000022
        reg_read_addr2 <= "110";     -- R6 → 0x00000066
        wait for 1 ns;
        check("R2 = 0x22", reg_read_data1, x"00000022");
        check("R6 = 0x66", reg_read_data2, x"00000066");

        -- -------------------------------------------------------
        -- TEST 8: Reset clears previously written registers
        -- -------------------------------------------------------
        report "=== TEST 8: Reset clears registers ===";
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;
        rst <= '0';

        reg_read_addr1 <= "010";
        reg_read_addr2 <= "110";
        wait for 1 ns;
        check("R2 cleared", reg_read_data1, x"00000000");
        check("R6 cleared", reg_read_data2, x"00000000");

        -- -------------------------------------------------------
        -- TEST 9: Write disabled — register must not change
        -- -------------------------------------------------------
        report "=== TEST 9: Write disabled ===";
        reg_write_en   <= '0';
        reg_write_addr <= "001";
        reg_write_data <= x"DEADBEEF";
        wait until rising_edge(clk);
        wait for 1 ns;
        reg_read_addr1 <= "001";
        wait for 1 ns;
        check("R1 unchanged (wr disabled)", reg_read_data1, x"00000000");

        -- -------------------------------------------------------
        -- TEST 10: Simultaneous read of two different registers
        -- -------------------------------------------------------
        report "=== TEST 10: Simultaneous dual read ===";
        reg_write_en   <= '1';
        reg_write_addr <= "001";
        reg_write_data <= x"AAAAAAAA";
        wait until rising_edge(clk); wait for 1 ns;

        reg_write_addr <= "100";
        reg_write_data <= x"BBBBBBBB";
        wait until rising_edge(clk); wait for 1 ns;
        reg_write_en   <= '0';

        reg_read_addr1 <= "001";     -- R1
        reg_read_addr2 <= "100";     -- R4
        wait for 1 ns;
        check("R1 simultaneous read", reg_read_data1, x"AAAAAAAA");
        check("R4 simultaneous read", reg_read_data2, x"BBBBBBBB");

        report "=== ALL TESTS COMPLETE ===";
        wait;
    end process;

end behavior;