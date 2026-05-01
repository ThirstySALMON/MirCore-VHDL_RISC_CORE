LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY program_counter IS
PORT (
    clk   : IN STD_LOGIC;                          -- Clock signal
    rst   : IN STD_LOGIC;                          -- Reset signal (active high)
    en    : IN STD_LOGIC;                          -- Enable signal (active high)
    flush : IN STD_LOGIC;                          -- Flush signal (active high, clears register on next clock)
    d     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);     -- Data input
    q     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)     -- Data output
);
END program_counter;

ARCHITECTURE rtl OF program_counter IS

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

BEGIN

-- Instantiate N_bit_register for the program counter
PC_REG : N_bit_register
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

END rtl;