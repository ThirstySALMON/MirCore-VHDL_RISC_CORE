library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IFID_tb is
end IFID_tb;

architecture behavior of IFID_tb is

    component IFID
        port (
            clk             : in  std_logic;
            flush           : in  std_logic;
            write_en        : in  std_logic;
            predicted_T     : in  std_logic;
            inst            : in  std_logic_vector(31 downto 0);
            input_port      : in  std_logic_vector(31 downto 0);
            pc              : in  std_logic_vector(9 downto 0);
            predicted_T_out : out std_logic;
            inst_out        : out std_logic_vector(31 downto 0);
            input_port_out  : out std_logic_vector(31 downto 0);
            pc_out          : out std_logic_vector(9 downto 0)
        );
    end component;

    signal clk             : std_logic := '0';
    signal flush           : std_logic := '0';
    signal write_en        : std_logic := '0';
    signal predicted_T     : std_logic := '0';
    signal inst            : std_logic_vector(31 downto 0) := (others => '0');
    signal input_port      : std_logic_vector(31 downto 0) := (others => '0');
    signal pc              : std_logic_vector(9 downto 0)  := (others => '0');
    signal predicted_T_out : std_logic;
    signal inst_out        : std_logic_vector(31 downto 0);
    signal input_port_out  : std_logic_vector(31 downto 0);
    signal pc_out          : std_logic_vector(9 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    -- --------------------------------------------------------
    -- Check helpers
    -- --------------------------------------------------------
    procedure check32(
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

    procedure check10(
        signal_name : in string;
        actual      : in std_logic_vector(9 downto 0);
        expected    : in std_logic_vector(9 downto 0)
    ) is
    begin
        if actual = expected then
            report "[PASS] " & signal_name &
                   " = " & integer'image(to_integer(unsigned(actual)));
        else
            report "[FAIL] " & signal_name &
                   " | expected " & integer'image(to_integer(unsigned(expected))) &
                   " | got "      & integer'image(to_integer(unsigned(actual)))
            severity error;
        end if;
    end procedure;

    procedure check1(
        signal_name : in string;
        actual      : in std_logic;
        expected    : in std_logic
    ) is
    begin
        if actual = expected then
            report "[PASS] " & signal_name &
                   " = " & std_logic'image(actual);
        else
            report "[FAIL] " & signal_name &
                   " | expected " & std_logic'image(expected) &
                   " | got "      & std_logic'image(actual)
            severity error;
        end if;
    end procedure;

begin

    uut: IFID
        port map (
            clk             => clk,
            flush           => flush,
            write_en        => write_en,
            predicted_T     => predicted_T,
            inst            => inst,
            input_port      => input_port,
            pc              => pc,
            predicted_T_out => predicted_T_out,
            inst_out        => inst_out,
            input_port_out  => input_port_out,
            pc_out          => pc_out
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc : process
    begin

        -- -------------------------------------------------------
        -- TEST 1: Initial state ? all outputs should be 0
        -- -------------------------------------------------------
        report "=== TEST 1: Initial state = 0 ===";
        wait for 1 ns;
        check32("inst_out   initial", inst_out,       x"00000000");
        check32("input_port initial", input_port_out, x"00000000");
        check10("pc_out     initial", pc_out,         "0000000000");
        check1 ("pred_T     initial", predicted_T_out, '0');

        -- -------------------------------------------------------
        -- TEST 2: write_en = 0 ? register must not latch
        -- -------------------------------------------------------
        report "=== TEST 2: write_en=0, register must not change ===";
        write_en    <= '0';
        inst        <= x"DEADBEEF";
        input_port  <= x"12345678";
        pc          <= "0000000010";
        predicted_T <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        check32("inst_out   (wr=0)", inst_out,       x"00000000");
        check32("input_port (wr=0)", input_port_out, x"00000000");
        check10("pc_out     (wr=0)", pc_out,         "0000000000");
        check1 ("pred_T     (wr=0)", predicted_T_out, '0');

        -- -------------------------------------------------------
        -- TEST 3: write_en = 1 ? register latches all inputs
        -- -------------------------------------------------------
        report "=== TEST 3: write_en=1, latch all inputs ===";
        write_en    <= '1';
        inst        <= x"DEADBEEF";
        input_port  <= x"12345678";
        pc          <= "0000000010";   -- addr 2
        predicted_T <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';
        check32("inst_out   (wr=1)", inst_out,        x"DEADBEEF");
        check32("input_port (wr=1)", input_port_out,  x"12345678");
        check10("pc_out     (wr=1)", pc_out,          "0000000010");
        check1 ("pred_T     (wr=1)", predicted_T_out, '1');

        -- -------------------------------------------------------
        -- TEST 4: write_en = 0 after latch ? outputs must hold
        -- -------------------------------------------------------
        report "=== TEST 4: Outputs hold when write_en=0 ===";
        write_en   <= '0';
        inst       <= x"FFFFFFFF";    -- new inputs that must NOT appear
        input_port <= x"AAAAAAAA";
        pc         <= "1111111111";
        wait until rising_edge(clk);
        wait for 1 ns;
        check32("inst_out   held", inst_out,        x"DEADBEEF");
        check32("input_port held", input_port_out,  x"12345678");
        check10("pc_out     held", pc_out,          "0000000010");
        check1 ("pred_T     held", predicted_T_out, '1');

        -- -------------------------------------------------------
        -- TEST 5: Flush clears all outputs to 0 (NOP bubble)
        -- -------------------------------------------------------
        report "=== TEST 5: Flush inserts NOP bubble ===";
        flush    <= '1';
        write_en <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        flush <= '0';
        check32("inst_out   flushed", inst_out,        x"00000000");
        check32("input_port flushed", input_port_out,  x"00000000");
        check10("pc_out     flushed", pc_out,          "0000000000");
        check1 ("pred_T     flushed", predicted_T_out, '0');

        -- -------------------------------------------------------
        -- TEST 6: Flush takes priority over write_en
        -- Both flush=1 and write_en=1 at same time -> flush wins
        -- -------------------------------------------------------
        report "=== TEST 6: Flush priority over write_en ===";
        -- First load something valid
        write_en    <= '1';
        inst        <= x"CAFEBABE";
        input_port  <= x"AABBCCDD";
        pc          <= "0000000101";
        predicted_T <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;

        -- Now assert both flush and write_en simultaneously
        flush       <= '1';
        write_en    <= '1';
        inst        <= x"FFFFFFFF";
        input_port  <= x"FFFFFFFF";
        pc          <= "1111111111";
        predicted_T <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        flush    <= '0';
        write_en <= '0';
        -- Flush should win ? outputs must be 0
        check32("inst_out   flush>wr", inst_out,        x"00000000");
        check32("input_port flush>wr", input_port_out,  x"00000000");
        check10("pc_out     flush>wr", pc_out,          "0000000000");
        check1 ("pred_T     flush>wr", predicted_T_out, '0');

        -- -------------------------------------------------------
        -- TEST 7: Write after flush ? register works normally again
        -- -------------------------------------------------------
        report "=== TEST 7: Normal write after flush ===";
        write_en    <= '1';
        inst        <= x"11223344";
        input_port  <= x"55667788";
        pc          <= "0000001000";   -- addr 8
        predicted_T <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';
        check32("inst_out   post-flush", inst_out,        x"11223344");
        check32("input_port post-flush", input_port_out,  x"55667788");
        check10("pc_out     post-flush", pc_out,          "0000001000");
        check1 ("pred_T     post-flush", predicted_T_out, '0');

        -- -------------------------------------------------------
        -- TEST 8: Multiple consecutive writes
        -- Each rising edge latches the current inputs
        -- -------------------------------------------------------
        report "=== TEST 8: Consecutive writes ===";
        write_en <= '1';

        inst <= x"AAAAAAAA"; pc <= "0000000001";
        wait until rising_edge(clk); wait for 1 ns;
        check32("inst cycle1", inst_out, x"AAAAAAAA");
        check10("pc   cycle1", pc_out,  "0000000001");

        inst <= x"BBBBBBBB"; pc <= "0000000010";
        wait until rising_edge(clk); wait for 1 ns;
        check32("inst cycle2", inst_out, x"BBBBBBBB");
        check10("pc   cycle2", pc_out,  "0000000010");

        inst <= x"CCCCCCCC"; pc <= "0000000011";
        wait until rising_edge(clk); wait for 1 ns;
        check32("inst cycle3", inst_out, x"CCCCCCCC");
        check10("pc   cycle3", pc_out,  "0000000011");

        write_en <= '0';

        report "=== ALL TESTS COMPLETE ===";
        wait;
    end process;

end behavior;