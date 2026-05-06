library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_tb is
end top_level_tb;

architecture behavior of top_level_tb is

    component top_level is
        port (
            clk                : in  std_logic;
            rst                : in  std_logic;
            interupt           : in  std_logic;
            input_port         : in  std_logic_vector(31 downto 0);
            output_port        : out std_logic_vector(31 downto 0);
            core_enable        : out std_logic;
            dbg_inst_out_fetch : out std_logic_vector(31 downto 0);
            dbg_pc_current     : out std_logic_vector(9 downto 0)
        );
    end component;

    signal clk                : std_logic := '0';
    signal rst                : std_logic := '0';
    signal interupt           : std_logic := '0';
    signal input_port         : std_logic_vector(31 downto 0) := (others => '0');
    signal output_port        : std_logic_vector(31 downto 0);
    signal core_enable        : std_logic;
    signal dbg_inst_out_fetch : std_logic_vector(31 downto 0);
    signal dbg_pc_current     : std_logic_vector(9 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    -- Expected program contents (must match program.mem at the project root)
    type prog_t is array (0 to 13) of std_logic_vector(31 downto 0);
    constant EXPECTED_PROG : prog_t := (
        0  => x"00000004",
        1  => x"0000000D",
        2  => x"0000000B",
        3  => x"0000000C",
        4  => x"79000005",
        5  => x"7A00000A",
        6  => x"4B280000",
        7  => x"2B000000",
        8  => x"7C00FFFF",
        9  => x"7D00FFFF",
        10 => x"08000000",
        11 => x"C8000000",
        12 => x"C8000000",
        13 => x"C8000000"
    );

    procedure check_inst(
        addr     : in integer;
        actual   : in std_logic_vector(31 downto 0);
        expected : in std_logic_vector(31 downto 0)
    ) is
    begin
        if actual = expected then
            report "[PASS] addr=" & integer'image(addr) &
                   " inst_out_fetch = 0x" &
                   integer'image(to_integer(unsigned(actual)));
        else
            report "[FAIL] addr=" & integer'image(addr) &
                   " | expected 0x" & integer'image(to_integer(unsigned(expected))) &
                   " | got 0x"      & integer'image(to_integer(unsigned(actual)))
            severity error;
        end if;
    end procedure;

begin

    uut : top_level
        port map (
            clk                => clk,
            rst                => rst,
            interupt           => interupt,
            input_port         => input_port,
            output_port        => output_port,
            core_enable        => core_enable,
            dbg_inst_out_fetch => dbg_inst_out_fetch,
            dbg_pc_current     => dbg_pc_current
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc : process
    begin
        report "=== TOP-LEVEL FETCH PATH TEST ===";
        report "Verifying program.mem contents propagate to inst_out_fetch.";

        -- Reset pulse. fetch_stage's reset path loads pc_reg <= instruction_word(9:0),
        -- which on the first cycle is M[0](9:0) = 0x004 = 4.
        -- After reset is released, the PC starts at 4.
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';

        -- Settle one delta so async memory read reflects the new PC=4.
        wait for 1 ns;

        -- Walk through addresses 4..13 and confirm inst_out_fetch matches program.mem.
        for i in 4 to 13 loop
            check_inst(i, dbg_inst_out_fetch, EXPECTED_PROG(i));
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;

        report "=== ALL TESTS COMPLETE ===";
        wait;
    end process;

end behavior;
