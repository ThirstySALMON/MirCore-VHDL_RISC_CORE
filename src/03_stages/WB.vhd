library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity wb_stage is
    port (
        -- Inputs from MEM/WB register
        HLT             : in std_logic;
        out_enable      : in std_logic;
        is_load         : in std_logic;
        SW_INTDone      : in std_logic_vector(1 downto 0);
        ret             : in std_logic;
        reg_WE          : in std_logic;
        reg_data        : in std_logic_vector(2 downto 0);
        alu_op          : in std_logic_vector(2 downto 0);

        alu_res         : in std_logic_vector(31 downto 0);
        rsrc1           : in std_logic_vector(31 downto 0);
        mem_data_out    : in std_logic_vector(31 downto 0);
        imm             : in std_logic_vector(15 downto 0);
        reg_dst_addr    : in std_logic_vector(2 downto 0);
        input_port      : in std_logic_vector(31 downto 0);

        -- Output to clock control
        HLT_out         : out std_logic;

        -- Output to output port register
        out_enable_out  : out std_logic;
        output_port_data: out std_logic_vector(31 downto 0);

        -- Outputs to hazard unit
        SW_INTDone_out  : out std_logic_vector(1 downto 0);
        ret_out         : out std_logic;

        -- Outputs to forwarding unit
        is_load_out      : out std_logic;
        reg_WE_out       : out std_logic;
        reg_data_out     : out std_logic_vector(2 downto 0);
        alu_op_out       : out std_logic_vector(2 downto 0);
        reg_dst_addr_out : out std_logic_vector(2 downto 0);

        -- Outputs to decode / register file / forwarding muxes
        alu_res_out      : out std_logic_vector(31 downto 0);
        rsrc1_out        : out std_logic_vector(31 downto 0);
        mem_data_out_out : out std_logic_vector(31 downto 0);
        imm_out          : out std_logic_vector(15 downto 0);
        input_port_out   : out std_logic_vector(31 downto 0)
    );
end entity wb_stage;