library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EX1EX2 is
    port (
        clk      : in std_logic;
        flush    : in std_logic;
        write_en : in std_logic;

        -- Data signals Inputs
        predicted_T  : in std_logic;
        pc           : in std_logic_vector(9 downto 0);
        HW_INT_ret   : in std_logic_vector(9 downto 0);
        ccr          : in std_logic_vector(2 downto 0);     -- Z, N, C flags
        alu_res      : in std_logic_vector(31 downto 0);    -- ALU result from EX1
        rsrc1        : in std_logic_vector(31 downto 0);
        rsrc2        : in std_logic_vector(31 downto 0);
        imm          : in std_logic_vector(15 downto 0);
        reg_dst_addr : in std_logic_vector(2 downto 0);
        input_port   : in std_logic_vector(31 downto 0);

        -- Control signals Inputs
        alu_op       : in std_logic_vector(2 downto 0);
        ccr_sel      : in std_logic_vector(2 downto 0);
        modify_ccr   : in std_logic_vector(2 downto 0);
        branch_op    : in std_logic_vector(3 downto 0);
        newSP_sel    : in std_logic;
        SP_WE        : in std_logic;
        add_sel      : in std_logic;
        mem_addr_sel : in std_logic_vector(2 downto 0);
        mem_data_sel : in std_logic_vector(1 downto 0);
        mem_WE       : in std_logic;
        mem_R        : in std_logic;
        reg_data     : in std_logic_vector(2 downto 0);
        reg_WE       : in std_logic;
        ret          : in std_logic;
        INT_state    : in std_logic_vector(1 downto 0);
        is_load      : in std_logic;
        swap_state   : in std_logic_vector(1 downto 0);
        out_enable   : in std_logic;
        HLT          : in std_logic;

        -- Data signals Outputs
        predicted_T_out  : out std_logic;
        pc_out           : out std_logic_vector(9 downto 0);
        HW_INT_ret_out   : out std_logic_vector(9 downto 0);
        ccr_out          : out std_logic_vector(2 downto 0);
        alu_res_out      : out std_logic_vector(31 downto 0);
        rsrc1_out        : out std_logic_vector(31 downto 0);
        rsrc2_out        : out std_logic_vector(31 downto 0);
        imm_out          : out std_logic_vector(15 downto 0);
        reg_dst_addr_out : out std_logic_vector(2 downto 0);
        input_port_out   : out std_logic_vector(31 downto 0);
     

        -- Control signals Outputs
        alu_op_out       : out std_logic_vector(2 downto 0);
        ccr_sel_out      : out std_logic_vector(2 downto 0);
        modify_ccr_out   : out std_logic_vector(2 downto 0);
        branch_op_out    : out std_logic_vector(3 downto 0);
        newSP_sel_out    : out std_logic;
        SP_WE_out        : out std_logic;
        add_sel_out      : out std_logic;
        mem_addr_sel_out : out std_logic_vector(2 downto 0);
        mem_data_sel_out : out std_logic_vector(1 downto 0);
        mem_WE_out       : out std_logic;
        mem_R_out        : out std_logic;
        reg_data_out     : out std_logic_vector(2 downto 0);
        reg_WE_out       : out std_logic;
        ret_out          : out std_logic;
        INT_state_out    : out std_logic_vector(1 downto 0);
        is_load_out      : out std_logic;
        swap_state_out   : out std_logic_vector(1 downto 0);
        out_enable_out   : out std_logic;
        HLT_out          : out std_logic
    );
end entity;

architecture rtl of EX1EX2 is

    -- Data signals
    signal predicted_T_str  : std_logic := '0';
    signal pc_str           : std_logic_vector(9 downto 0)  := (others => '0');
    signal HW_INT_ret_str   : std_logic_vector(9 downto 0)  := (others => '0');
    signal ccr_str          : std_logic_vector(2 downto 0)  := (others => '0');
    signal alu_res_str      : std_logic_vector(31 downto 0) := (others => '0');
    signal rsrc1_str        : std_logic_vector(31 downto 0) := (others => '0');
    signal rsrc2_str        : std_logic_vector(31 downto 0) := (others => '0');
    signal imm_str          : std_logic_vector(15 downto 0) := (others => '0');
    signal reg_dst_addr_str : std_logic_vector(2 downto 0)  := (others => '0');
    signal input_port_str   : std_logic_vector(31 downto 0) := (others => '0');

    -- Control signals
    signal alu_op_str       : std_logic_vector(2 downto 0) := (others => '0');
    signal ccr_sel_str      : std_logic_vector(2 downto 0) := (others => '0');
    signal modify_ccr_str   : std_logic_vector(2 downto 0) := (others => '0');
    signal branch_op_str    : std_logic_vector(3 downto 0) := (others => '0');
    signal newSP_sel_str    : std_logic := '0';
    signal SP_WE_str        : std_logic := '0';
    signal add_sel_str      : std_logic := '0';
    signal mem_addr_sel_str : std_logic_vector(2 downto 0) := (others => '0');
    signal mem_data_sel_str : std_logic_vector(1 downto 0) := (others => '0');
    signal mem_WE_str       : std_logic := '0';
    signal mem_R_str        : std_logic := '0';
    signal reg_data_str     : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_WE_str       : std_logic := '0';
    signal ret_str          : std_logic := '0';
    signal INT_state_str    : std_logic_vector(1 downto 0) := (others => '0');
    signal is_load_str      : std_logic := '0';
    signal swap_state_str   : std_logic_vector(1 downto 0) := (others => '0');
    signal out_enable_str   : std_logic := '0';
    signal hlt_str   : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if flush = '1' then
                -- Clear all data signals
                predicted_T_str  <= '0';
                pc_str           <= (others => '0');
                HW_INT_ret_str   <= (others => '0');
                ccr_str          <= (others => '0');
                alu_res_str      <= (others => '0');
                rsrc1_str        <= (others => '0');
                rsrc2_str        <= (others => '0');
                imm_str          <= (others => '0');
                reg_dst_addr_str <= (others => '0');
                input_port_str   <= (others => '0');

                -- Clear all control signals (NOP bubble)
                alu_op_str       <= (others => '0');
                ccr_sel_str      <= (others => '0');
                modify_ccr_str   <= (others => '0');
                branch_op_str    <= (others => '0');
                newSP_sel_str    <= '0';
                SP_WE_str        <= '0';
                add_sel_str      <= '0';
                mem_addr_sel_str <= (others => '0');
                mem_data_sel_str <= (others => '0');
                mem_WE_str       <= '0';
                mem_R_str        <= '0';
                reg_data_str     <= (others => '0');
                reg_WE_str       <= '0';
                ret_str          <= '0';
                INT_state_str    <= (others => '0');
                is_load_str      <= '0';
                swap_state_str   <= (others => '0');
                out_enable_str   <= '0';
                hlt_str          <= '0';

            elsif write_en = '1' then
                -- Latch all data signals
                predicted_T_str  <= predicted_T;
                pc_str           <= pc;
                HW_INT_ret_str   <= HW_INT_ret;
                ccr_str          <= ccr;
                alu_res_str      <= alu_res;
                rsrc1_str        <= rsrc1;
                rsrc2_str        <= rsrc2;
                imm_str          <= imm;
                reg_dst_addr_str <= reg_dst_addr;
                input_port_str   <= input_port;

                -- Latch all control signals
                alu_op_str       <= alu_op;
                ccr_sel_str      <= ccr_sel;
                modify_ccr_str   <= modify_ccr;
                branch_op_str    <= branch_op;
                newSP_sel_str    <= newSP_sel;
                SP_WE_str        <= SP_WE;
                add_sel_str      <= add_sel;
                mem_addr_sel_str <= mem_addr_sel;
                mem_data_sel_str <= mem_data_sel;
                mem_WE_str       <= mem_WE;
                mem_R_str        <= mem_R;
                reg_data_str     <= reg_data;
                reg_WE_str       <= reg_WE;
                ret_str          <= ret;
                INT_state_str    <= INT_state;
                is_load_str      <= is_load;
                swap_state_str   <= swap_state;
                out_enable_str   <= out_enable;
                hlt_str          <= HLT;
            end if;
        end if;
    end process;

    -- Drive outputs
    predicted_T_out  <= predicted_T_str;
    pc_out           <= pc_str;
    HW_INT_ret_out   <= HW_INT_ret_str;
    ccr_out          <= ccr_str;
    alu_res_out      <= alu_res_str;
    rsrc1_out        <= rsrc1_str;
    rsrc2_out        <= rsrc2_str;
    imm_out          <= imm_str;
    reg_dst_addr_out <= reg_dst_addr_str;
    input_port_out   <= input_port_str;

    alu_op_out       <= alu_op_str;
    ccr_sel_out      <= ccr_sel_str;
    modify_ccr_out   <= modify_ccr_str;
    branch_op_out    <= branch_op_str;
    newSP_sel_out    <= newSP_sel_str;
    SP_WE_out        <= SP_WE_str;
    add_sel_out      <= add_sel_str;
    mem_addr_sel_out <= mem_addr_sel_str;
    mem_data_sel_out <= mem_data_sel_str;
    mem_WE_out       <= mem_WE_str;
    mem_R_out        <= mem_R_str;
    reg_data_out     <= reg_data_str;
    reg_WE_out       <= reg_WE_str;
    ret_out          <= ret_str;
    INT_state_out    <= INT_state_str;
    is_load_out      <= is_load_str;
    swap_state_out   <= swap_state_str;
    out_enable_out   <= out_enable_str;
    HLT_out          <= hlt_str;

end rtl;
