--------------------------------------------------------------------------------
-- top_level_tb
--   Drives clk + reset and lets the core run free. All internal signals are
--   visible in the simulator via "add wave -r /top_level_tb/uut/*" (see the
--   .do file). No assertions; this TB is for waveform inspection.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_tb is
end top_level_tb;

architecture behavior of top_level_tb is

    component top_level is
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            interupt    : in  std_logic;
            input_port  : in  std_logic_vector(31 downto 0);
            output_port : out std_logic_vector(31 downto 0);
            core_enable : out std_logic
        );
    end component;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal interupt    : std_logic := '0';
    signal input_port  : std_logic_vector(31 downto 0) := (others => '0');
    signal output_port : std_logic_vector(31 downto 0);
    signal core_enable : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    uut : top_level
        port map (
            clk         => clk,
            rst         => rst,
            interupt    => interupt,
            input_port  => input_port,
            output_port => output_port,
            core_enable => core_enable
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc : process
    begin
        -- Pulse reset, then run free for many cycles so the pipeline fills.
        rst <= '1';
        wait until rising_edge(clk);
        rst <= '0';

        for i in 0 to 31 loop
            wait until rising_edge(clk);
        end loop;

        wait;
    end process;

end behavior;
