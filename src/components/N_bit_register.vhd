LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- N-bit Register Module
-- Kept it as bare bones as possible to be used in various contexts
-- (e.g., pipeline registers, general-purpose registers)

ENTITY N_bit_register IS
    GENERIC (
        N : INTEGER := 32  -- Default width of the register
    );
    PORT (
        clk : IN STD_LOGIC;  -- Clock signal
        rst : IN STD_LOGIC;  -- Reset signal (active high) (Async reset probably wont need to be used in a pipeline register, but just in case)
        en  : IN STD_LOGIC;  -- Enable signal (active high)
        flush : IN STD_LOGIC; -- Flush signal (active high, clears register on next clock)
        d   : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);  -- Data input
        q   : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)   -- Data output
    );
END N_bit_register;


ARCHITECTURE reg_rtl OF N_bit_register IS
    SIGNAL reg_data : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
BEGIN

    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_data <= (OTHERS => '0');  -- Reset register to 0
        ELSIF rising_edge(clk) THEN
            IF flush = '1' THEN
                reg_data <= (OTHERS => '0');  -- Clear register on flush
            ELSIF en = '1' THEN
            reg_data <= d;  -- Load data on rising edge of clock
            END IF;
        END IF;
    END PROCESS;

    q <= reg_data;  -- Output the current value of the register
END reg_rtl;