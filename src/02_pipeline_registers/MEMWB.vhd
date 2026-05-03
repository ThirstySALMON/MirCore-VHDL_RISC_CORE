library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MEMWB is
    port (
        clk      : in std_logic;
        flush    : in std_logic;
        write_en : in std_logic;

        -- Data signals Inputs
        alu_res      : in std_logic_vector(31 downto 0);
        rsrc1        : in std_logic_vector(31 downto 0);
        mem_data_out : in std_logic_vector(31 downto 0);    -- data read from memory
        imm          : in std_logic_vector(15 downto 0);
        reg_dst_addr : in std_logic_vector(2 downto 0);
        input_port   : in std_logic_vector(31 downto 0);

        -- Control signals Inputs
        alu_op       : in std_logic_vector(2 downto 0);
        reg_data     : in std_logic_vector(2 downto 0);
        reg_WE       : in std_logic;
        ret          : in std_logic;
        SW_INTDone   : in std_logic_vector(1 downto 0);    -- same as INT_state
        is_load      : in std_logic;
        out_enable   : in std_logic;
        HLT          : in std_logic;

        -- Data signals Outputs
        alu_res_out      : out std_logic_vector(31 downto 0);
        rsrc1_out        : out std_logic_vector(31 downto 0);
        mem_data_out_out : out std_logic_vector(31 downto 0);
        imm_out          : out std_logic_vector(15 downto 0);
        reg_dst_addr_out : out std_logic_vector(2 downto 0);
        input_port_out   : out std_logic_vector(31 downto 0);

        -- Control signals Outputs
        alu_op_out       : out std_logic_vector(2 downto 0);
        reg_data_out     : out std_logic_vector(2 downto 0);
        reg_WE_out       : out std_logic;
        ret_out          : out std_logic;
        SW_INTDone_out   : out std_logic_vector(1 downto 0);
        is_load_out      : out std_logic;
        out_enable_out   : out std_logic;
        HLT_out          : out std_logic
    );
end entity;

architecture rtl of MEMWB is

    -- Data signals
    signal alu_res_str      : std_logic_vector(31 downto 0) := (others => '0');
    signal rsrc1_str        : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_data_out_str : std_logic_vector(31 downto 0) := (others => '0');
    signal imm_str          : std_logic_vector(15 downto 0) := (others => '0');
    signal reg_dst_addr_str : std_logic_vector(2 downto 0)  := (others => '0');
    signal input_port_str   : std_logic_vector(31 downto 0) := (others => '0');

    -- Control signals
    signal alu_op_str       : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_data_str     : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_WE_str       : std_logic := '0';
    signal ret_str          : std_logic := '0';
    signal SW_INTDone_str   : std_logic_vector(1 downto 0) := (others => '0');
    signal is_load_str      : std_logic := '0';
    signal out_enable_str   : std_logic := '0';
    signal HLT_str          : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if flush = '1' then
                -- Clear all data signals
                alu_res_str      <= (others => '0');
                rsrc1_str        <= (others => '0');
                mem_data_out_str <= (others => '0');
                imm_str          <= (others => '0');
                reg_dst_addr_str <= (others => '0');
                input_port_str   <= (others => '0');

                -- Clear all control signals (NOP bubble)
                alu_op_str       <= (others => '0');
                reg_data_str     <= (others => '0');
                reg_WE_str       <= '0';
                ret_str          <= '0';
                SW_INTDone_str   <= (others => '0');
                is_load_str      <= '0';
                out_enable_str   <= '0';
                HLT_str          <= '0';

            elsif write_en = '1' then
                -- Latch all data signals
                alu_res_str      <= alu_res;
                rsrc1_str        <= rsrc1;
                mem_data_out_str <= mem_data_out;
                imm_str          <= imm;
                reg_dst_addr_str <= reg_dst_addr;
                input_port_str   <= input_port;

                -- Latch all control signals
                alu_op_str       <= alu_op;
                reg_data_str     <= reg_data;
                reg_WE_str       <= reg_WE;
                ret_str          <= ret;
                SW_INTDone_str   <= SW_INTDone;
                is_load_str      <= is_load;
                out_enable_str   <= out_enable;
                HLT_str          <= HLT;
            end if;
        end if;
    end process;

    -- Drive outputs
    alu_res_out      <= alu_res_str;
    rsrc1_out        <= rsrc1_str;
    mem_data_out_out <= mem_data_out_str;
    imm_out          <= imm_str;
    reg_dst_addr_out <= reg_dst_addr_str;
    input_port_out   <= input_port_str;

    alu_op_out       <= alu_op_str;
    reg_data_out     <= reg_data_str;
    reg_WE_out       <= reg_WE_str;
    ret_out          <= ret_str;
    SW_INTDone_out   <= SW_INTDone_str;
    is_load_out      <= is_load_str;
    out_enable_out   <= out_enable_str;
    HLT_out          <= HLT_str;

end rtl;