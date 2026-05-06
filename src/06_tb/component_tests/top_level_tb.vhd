library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_tb is
end top_level_tb;

architecture behavior of top_level_tb is

    -- Mirror top_level's wiring so the internal fetch->IFID instruction bus
    -- (inst_out_fetch) is observable from the testbench. The DUTs below are
    -- the exact same components top_level instantiates, wired the same way.

    component memory is
        port (
            clk          : in  std_logic;
            mem_write_en : in  std_logic;
            mem_addr     : in  std_logic_vector(9 downto 0);
            mem_data_in  : in  std_logic_vector(31 downto 0);
            mem_data_out : out std_logic_vector(31 downto 0)
        );
    end component;

    component fetch_stage is
        port (
            clk                      : in  std_logic;
            rst                      : in  std_logic;
            predicted_taken          : out std_logic;
            pc_current               : out std_logic_vector(9 downto 0);
            input_port_passthrough   : out std_logic_vector(31 downto 0);
            inst_to_ifid             : out std_logic_vector(31 downto 0);
            inst_mem_addr            : out std_logic_vector(9 downto 0);
            branch_prediction_result : in  std_logic_vector(1 downto 0);
            pc_write_en              : in  std_logic;
            pc_src_sel               : in  std_logic_vector(1 downto 0);
            corrected_addr_sel       : in  std_logic;
            branch_target_addr       : in  std_logic_vector(9 downto 0);
            branch_fallthrough_addr  : in  std_logic_vector(9 downto 0);
            instruction_word         : in  std_logic_vector(31 downto 0);
            mem_read_addr            : in  std_logic_vector(31 downto 0);
            input_port               : in  std_logic_vector(31 downto 0)
        );
    end component;

    -- Top-level inputs
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal input_port  : std_logic_vector(31 downto 0) := (others => '0');

    -- Internal buses (mirror of top_level)
    signal memory_data_out    : std_logic_vector(31 downto 0);
    signal memory_addr        : std_logic_vector(9 downto 0);
    signal predict            : std_logic;
    signal pc_crr             : std_logic_vector(9 downto 0);
    signal input_out_fetch    : std_logic_vector(31 downto 0);
    signal inst_out_fetch     : std_logic_vector(31 downto 0);
    signal mem_addr_out_fetch : std_logic_vector(9 downto 0);

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

    -- Memory: async read at memory_addr
    memory_addr <= mem_addr_out_fetch;
    u_memory : memory
        port map (
            clk          => clk,
            mem_write_en => '0',
            mem_addr     => memory_addr,
            mem_data_in  => (others => '0'),
            mem_data_out => memory_data_out
        );

    -- Fetch stage: same wiring as top_level
    u_fetch_stage : fetch_stage
        port map (
            clk                      => clk,
            rst                      => rst,
            predicted_taken          => predict,
            pc_current               => pc_crr,
            input_port_passthrough   => input_out_fetch,
            inst_to_ifid             => inst_out_fetch,
            inst_mem_addr            => mem_addr_out_fetch,
            branch_prediction_result => (others => '0'),
            pc_write_en              => '1',
            pc_src_sel               => (others => '0'),
            corrected_addr_sel       => '0',
            branch_target_addr       => (others => '0'),
            branch_fallthrough_addr  => (others => '0'),
            instruction_word         => memory_data_out,
            mem_read_addr            => (others => '0'),
            input_port               => input_port
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

        -- Reset pulse. The fetch stage's reset path loads
        -- pc_reg <= instruction_word(9 downto 0), which on the first cycle is
        -- M[0](9:0) = 0x004 = 4. So after reset is released, the PC starts at 4.
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';

        -- Settle one delta so async memory read reflects the new PC=4.
        wait for 1 ns;

        -- After reset deasserted, PC = 4. Walk through addresses 4..13 and
        -- confirm inst_out_fetch matches program.mem on each cycle.
        for i in 4 to 13 loop
            check_inst(i, inst_out_fetch, EXPECTED_PROG(i));
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;

        report "=== ALL TESTS COMPLETE ===";
        wait;
    end process;

end behavior;
