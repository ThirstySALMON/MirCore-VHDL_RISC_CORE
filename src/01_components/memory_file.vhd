library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity memory is
    port (
        clk          : in  std_logic;
        mem_write_en : in  std_logic;
        mem_addr     : in  std_logic_vector(9 downto 0);
        mem_data_in  : in  std_logic_vector(31 downto 0);
        mem_data_out : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of memory is

    type memory_t is array (0 to 1023) of std_logic_vector(31 downto 0);

    -- --------------------------------------------------------
    -- Loads hex instructions from file at elaboration time.
    -- One 32-bit hex word per line, e.g:
    --   00100000
    --   00200001
    -- --------------------------------------------------------
    impure function load_mem(filename : string) return memory_t is
        file     f    : text open read_mode is filename;
        variable l    : line;
        variable mem  : memory_t := (others => (others => '0'));
        variable word : std_logic_vector(31 downto 0);
        variable i    : integer := 0;
    begin
        while not endfile(f) loop
            readline(f, l);
            -- skip empty lines
            if l'length > 0 then
                hread(l, word);
                mem(i) := word;
                i := i + 1;
            end if;
        end loop;
        return mem;
    end function;

    signal addr_int : integer range 0 to 1023;
    signal mem      : memory_t := load_mem("program.mem");

begin

    addr_int <= to_integer(unsigned(mem_addr));

    -- Synchronous write
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_write_en = '1' then
                mem(addr_int) <= mem_data_in;
            end if;
        end if;
    end process;

    -- Asynchronous read
    mem_data_out <= mem(addr_int);

end rtl;