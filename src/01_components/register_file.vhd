library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        clk : in std_logic;
        rst : in std_logic;
        reg_write_en : in std_logic;
        reg_write_addr : in std_logic_vector(2 downto 0);
        reg_write_data : in std_logic_vector(31 downto 0);
        reg_read_addr1 : in std_logic_vector(2 downto 0);
        reg_read_addr2 : in std_logic_vector(2 downto 0);
        reg_read_data1 : out std_logic_vector(31 downto 0);
        reg_read_data2 : out std_logic_vector(31 downto 0)
    );
end register_file;

architecture rtl of register_file is


    type reg_array is array (0 to 7) of std_logic_vector(31 downto 0);

    signal registers : reg_array := (others => (others => '0'));
    signal write_addr_int : integer range 0 to 7;
    signal read_addr1_int : integer range 0 to 7;
    signal read_addr2_int : integer range 0 to 7;

    begin 

    write_addr_int <= to_integer(unsigned(reg_write_addr));
    read_addr1_int <= to_integer(unsigned(reg_read_addr1));
    read_addr2_int <= to_integer(unsigned(reg_read_addr2));
    process(clk, rst)
    begin

        if rst = '1' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if reg_write_en = '1' then
                registers(write_addr_int) <= reg_write_data;
            end if;
        end if;
    end process;

    reg_read_data1 <= reg_write_data when(reg_write_en = '1' and read_addr1_int = write_addr_int) else
                        registers(read_addr1_int);


    reg_read_data2 <= reg_write_data when(reg_write_en = '1' and read_addr2_int = write_addr_int) else
                        registers(read_addr2_int);


    end rtl;


