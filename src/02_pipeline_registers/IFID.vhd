library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IFID is
    port (
        clk   : in std_logic;
        flush : in std_logic;
        write_en : in std_logic;
        predicted_T : in std_logic;
        inst : in std_logic_vector(31 downto 0);
        input_port : in std_logic_vector(31 downto 0);
        pc : in std_logic_vector(9 downto 0);
        predicted_T_out : out std_logic;
        inst_out        : out std_logic_vector(31 downto 0);
        input_port_out  : out std_logic_vector(31 downto 0);
        pc_out : out std_logic_vector(9 downto 0)

        
    );
end entity;


architecture rtl of IFID is 

    signal predicted_T_str : std_logic := '0';
    signal inst_str : std_logic_vector(31 downto 0) := (others => '0');
    signal input_port_str : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_str : std_logic_vector(9 downto 0) := (others => '0');


begin

    process(clk)
    begin 

        if rising_edge(clk) then
            if flush = '1' then
                predicted_T_str <= '0';
                inst_str <= (others => '0');
                input_port_str <= (others => '0');
                pc_str <= (others => '0');
            elsif
                write_en = '1' then 
                predicted_T_str <= predicted_T;
                inst_str <= inst;
                input_port_str <= input_port;
                pc_str <= pc;
                end if; 
        end if;
    

    end process;

    predicted_T_out <= predicted_T_str;
    inst_out        <= inst_str;
    input_port_out  <= input_port_str;
    pc_out          <= pc_str;

end rtl;