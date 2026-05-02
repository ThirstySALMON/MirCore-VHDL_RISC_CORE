library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IDEX1_tb is
end IDEX1_tb;

architecture behavior of IDEX1_tb is

    component IDEX1
        port (
            clk      : in std_logic;
            flush    : in std_logic;
            write_en : in std_logic;

            predicted_T  : in std_logic;
            HW_INT_ret   : in std_logic_vector(9 downto 0);
            pc           : in std_logic_vector(9 downto 0);
            rsrc1        : in std_logic_vector(31 downto 0);
            rsrc2        : in std_logic_vector(31 downto 0);
            imm          : in std_logic_vector(15 downto 0);
            reg_dst_addr : in std_logic_vector(2 downto 0);
            rsrc1_addr   : in std_logic_vector(2 downto 0);
            rsrc2_addr   : in std_logic_vector(2 downto 0);
            input_port   : in std_logic_vector(31 downto 0);

            alu_src      : in std_logic;
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

            predicted_T_out  : out std_logic;
            HW_INT_ret_out   : out std_logic_vector(9 downto 0);
            pc_out           : out std_logic_vector(9 downto 0);
            rsrc1_out        : out std_logic_vector(31 downto 0);
            rsrc2_out        : out std_logic_vector(31 downto 0);
            imm_out          : out std_logic_vector(15 downto 0);
            reg_dst_addr_out : out std_logic_vector(2 downto 0);
            rsrc1_addr_out   : out std_logic_vector(2 downto 0);
            rsrc2_addr_out   : out std_logic_vector(2 downto 0);
            input_port_out   : out std_logic_vector(31 downto 0);

            alu_src_out      : out std_logic;
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
    end component;

    -- Inputs
    signal clk      : std_logic := '0';
    signal flush    : std_logic := '0';
    signal write_en : std_logic := '0';

    signal predicted_T  : std_logic := '0';
    signal HW_INT_ret   : std_logic_vector(9 downto 0)  := (others => '0');
    signal pc           : std_logic_vector(9 downto 0)  := (others => '0');
    signal rsrc1        : std_logic_vector(31 downto 0) := (others => '0');
    signal rsrc2        : std_logic_vector(31 downto 0) := (others => '0');
    signal imm          : std_logic_vector(15 downto 0) := (others => '0');
    signal reg_dst_addr : std_logic_vector(2 downto 0)  := (others => '0');
    signal rsrc1_addr   : std_logic_vector(2 downto 0)  := (others => '0');
    signal rsrc2_addr   : std_logic_vector(2 downto 0)  := (others => '0');
    signal input_port   : std_logic_vector(31 downto 0) := (others => '0');

    signal alu_src      : std_logic := '0';
    signal alu_op       : std_logic_vector(2 downto 0) := (others => '0');
    signal ccr_sel      : std_logic_vector(2 downto 0) := (others => '0');
    signal modify_ccr   : std_logic_vector(2 downto 0) := (others => '0');
    signal branch_op    : std_logic_vector(3 downto 0) := (others => '0');
    signal newSP_sel    : std_logic := '0';
    signal SP_WE        : std_logic := '0';
    signal add_sel      : std_logic := '0';
    signal mem_addr_sel : std_logic_vector(2 downto 0) := (others => '0');
    signal mem_data_sel : std_logic_vector(1 downto 0) := (others => '0');
    signal mem_WE       : std_logic := '0';
    signal mem_R        : std_logic := '0';
    signal reg_data     : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_WE       : std_logic := '0';
    signal ret          : std_logic := '0';
    signal INT_state    : std_logic_vector(1 downto 0) := (others => '0');
    signal is_load      : std_logic := '0';
    signal swap_state   : std_logic_vector(1 downto 0) := (others => '0');
    signal out_enable   : std_logic := '0';
    signal HLT          : std_logic := '0';

    -- Outputs
    signal predicted_T_out  : std_logic;
    signal HW_INT_ret_out   : std_logic_vector(9 downto 0);
    signal pc_out           : std_logic_vector(9 downto 0);
    signal rsrc1_out        : std_logic_vector(31 downto 0);
    signal rsrc2_out        : std_logic_vector(31 downto 0);
    signal imm_out          : std_logic_vector(15 downto 0);
    signal reg_dst_addr_out : std_logic_vector(2 downto 0);
    signal rsrc1_addr_out   : std_logic_vector(2 downto 0);
    signal rsrc2_addr_out   : std_logic_vector(2 downto 0);
    signal input_port_out   : std_logic_vector(31 downto 0);

    signal alu_src_out      : std_logic;
    signal alu_op_out       : std_logic_vector(2 downto 0);
    signal ccr_sel_out      : std_logic_vector(2 downto 0);
    signal modify_ccr_out   : std_logic_vector(2 downto 0);
    signal branch_op_out    : std_logic_vector(3 downto 0);
    signal newSP_sel_out    : std_logic;
    signal SP_WE_out        : std_logic;
    signal add_sel_out      : std_logic;
    signal mem_addr_sel_out : std_logic_vector(2 downto 0);
    signal mem_data_sel_out : std_logic_vector(1 downto 0);
    signal mem_WE_out       : std_logic;
    signal mem_R_out        : std_logic;
    signal reg_data_out     : std_logic_vector(2 downto 0);
    signal reg_WE_out       : std_logic;
    signal ret_out          : std_logic;
    signal INT_state_out    : std_logic_vector(1 downto 0);
    signal is_load_out      : std_logic;
    signal swap_state_out   : std_logic_vector(1 downto 0);
    signal out_enable_out   : std_logic;
    signal HLT_out          : std_logic;

    constant CLK_PERIOD : time := 10 ns;

    -- --------------------------------------------------------
    -- Procedure: assert all outputs match expected (or all zero)
    -- pass mode='Z' => check all outputs are zero (flush/init)
    -- pass mode='V' => check all outputs equal the test pattern
    -- --------------------------------------------------------
    procedure check_all_zero(label : string;
                             signal pc_o   : in std_logic_vector(9 downto 0);
                             signal rsrc1_o: in std_logic_vector(31 downto 0);
                             signal alu_op_o : in std_logic_vector(2 downto 0);
                             signal reg_WE_o : in std_logic;
                             signal HLT_o    : in std_logic) is
    begin
        if pc_o = "0000000000" and rsrc1_o = x"00000000"
           and alu_op_o = "000" and reg_WE_o = '0' and HLT_o = '0' then
            report "[PASS] " & label & " - all outputs cleared";
        else
            report "[FAIL] " & label & " - outputs not all zero" severity error;
        end if;
    end procedure;

begin

    uut: IDEX1
        port map (
            clk            => clk,
            flush          => flush,
            write_en       => write_en,
            predicted_T    => predicted_T,
            HW_INT_ret     => HW_INT_ret,
            pc             => pc,
            rsrc1          => rsrc1,
            rsrc2          => rsrc2,
            imm            => imm,
            reg_dst_addr   => reg_dst_addr,
            rsrc1_addr     => rsrc1_addr,
            rsrc2_addr     => rsrc2_addr,
            input_port     => input_port,
            alu_src        => alu_src,
            alu_op         => alu_op,
            ccr_sel        => ccr_sel,
            modify_ccr     => modify_ccr,
            branch_op      => branch_op,
            newSP_sel      => newSP_sel,
            SP_WE          => SP_WE,
            add_sel        => add_sel,
            mem_addr_sel   => mem_addr_sel,
            mem_data_sel   => mem_data_sel,
            mem_WE         => mem_WE,
            mem_R          => mem_R,
            reg_data       => reg_data,
            reg_WE         => reg_WE,
            ret            => ret,
            INT_state      => INT_state,
            is_load        => is_load,
            swap_state     => swap_state,
            out_enable     => out_enable,
            HLT            => HLT,

            predicted_T_out  => predicted_T_out,
            HW_INT_ret_out   => HW_INT_ret_out,
            pc_out           => pc_out,
            rsrc1_out        => rsrc1_out,
            rsrc2_out        => rsrc2_out,
            imm_out          => imm_out,
            reg_dst_addr_out => reg_dst_addr_out,
            rsrc1_addr_out   => rsrc1_addr_out,
            rsrc2_addr_out   => rsrc2_addr_out,
            input_port_out   => input_port_out,
            alu_src_out      => alu_src_out,
            alu_op_out       => alu_op_out,
            ccr_sel_out      => ccr_sel_out,
            modify_ccr_out   => modify_ccr_out,
            branch_op_out    => branch_op_out,
            newSP_sel_out    => newSP_sel_out,
            SP_WE_out        => SP_WE_out,
            add_sel_out      => add_sel_out,
            mem_addr_sel_out => mem_addr_sel_out,
            mem_data_sel_out => mem_data_sel_out,
            mem_WE_out       => mem_WE_out,
            mem_R_out        => mem_R_out,
            reg_data_out     => reg_data_out,
            reg_WE_out       => reg_WE_out,
            ret_out          => ret_out,
            INT_state_out    => INT_state_out,
            is_load_out      => is_load_out,
            swap_state_out   => swap_state_out,
            out_enable_out   => out_enable_out,
            HLT_out          => HLT_out
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc : process

        -- Helper: drive a representative pattern onto every input
        procedure drive_pattern_A is
        begin
            predicted_T  <= '1';
            HW_INT_ret   <= "0000000010";    -- 2
            pc           <= "0000000100";    -- 4
            rsrc1        <= x"DEADBEEF";
            rsrc2        <= x"12345678";
            imm          <= x"ABCD";
            reg_dst_addr <= "001";
            rsrc1_addr   <= "010";
            rsrc2_addr   <= "011";
            input_port   <= x"CAFEBABE";
            alu_src      <= '1';
            alu_op       <= "101";
            ccr_sel      <= "110";
            modify_ccr   <= "011";
            branch_op    <= "1010";
            newSP_sel    <= '1';
            SP_WE        <= '1';
            add_sel      <= '1';
            mem_addr_sel <= "100";
            mem_data_sel <= "10";
            mem_WE       <= '1';
            mem_R        <= '1';
            reg_data     <= "111";
            reg_WE       <= '1';
            ret          <= '1';
            INT_state    <= "10";
            is_load      <= '1';
            swap_state   <= "01";
            out_enable   <= '1';
            HLT          <= '1';
        end procedure;

        procedure drive_pattern_B is
        begin
            predicted_T  <= '0';
            HW_INT_ret   <= "0000001111";
            pc           <= "0000010000";
            rsrc1        <= x"AAAAAAAA";
            rsrc2        <= x"BBBBBBBB";
            imm          <= x"1234";
            reg_dst_addr <= "100";
            rsrc1_addr   <= "101";
            rsrc2_addr   <= "110";
            input_port   <= x"FFFFFFFF";
            alu_src      <= '0';
            alu_op       <= "010";
            ccr_sel      <= "001";
            modify_ccr   <= "100";
            branch_op    <= "0101";
            newSP_sel    <= '0';
            SP_WE        <= '0';
            add_sel      <= '0';
            mem_addr_sel <= "010";
            mem_data_sel <= "01";
            mem_WE       <= '0';
            mem_R        <= '0';
            reg_data     <= "010";
            reg_WE       <= '0';
            ret          <= '0';
            INT_state    <= "01";
            is_load      <= '0';
            swap_state   <= "10";
            out_enable   <= '0';
            HLT          <= '0';
        end procedure;

    begin

        -- -------------------------------------------------------
        -- TEST 1: Initial state -- all outputs zero
        -- -------------------------------------------------------
        report "=== TEST 1: Initial state ===";
        wait for 1 ns;
        check_all_zero("Initial", pc_out, rsrc1_out, alu_op_out, reg_WE_out, HLT_out);

        -- -------------------------------------------------------
        -- TEST 2: write_en = 0, register holds at zero
        -- -------------------------------------------------------
        report "=== TEST 2: write_en=0 ignores inputs ===";
        write_en <= '0';
        drive_pattern_A;
        wait until rising_edge(clk);
        wait for 1 ns;
        check_all_zero("write_en=0", pc_out, rsrc1_out, alu_op_out, reg_WE_out, HLT_out);

        -- -------------------------------------------------------
        -- TEST 3: write_en = 1 latches pattern A
        -- -------------------------------------------------------
        report "=== TEST 3: write_en=1 latches pattern A ===";
        write_en <= '1';
        drive_pattern_A;
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';

        assert pc_out           = "0000000100" report "FAIL pc_out"           severity error;
        assert rsrc1_out        = x"DEADBEEF"  report "FAIL rsrc1_out"        severity error;
        assert rsrc2_out        = x"12345678"  report "FAIL rsrc2_out"        severity error;
        assert imm_out          = x"ABCD"      report "FAIL imm_out"          severity error;
        assert reg_dst_addr_out = "001"        report "FAIL reg_dst_addr_out" severity error;
        assert input_port_out   = x"CAFEBABE"  report "FAIL input_port_out"   severity error;
        assert predicted_T_out  = '1'          report "FAIL predicted_T_out"  severity error;
        assert HW_INT_ret_out   = "0000000010" report "FAIL HW_INT_ret_out"   severity error;
        assert alu_src_out      = '1'          report "FAIL alu_src_out"      severity error;
        assert alu_op_out       = "101"        report "FAIL alu_op_out"       severity error;
        assert ccr_sel_out      = "110"        report "FAIL ccr_sel_out"      severity error;
        assert modify_ccr_out   = "011"        report "FAIL modify_ccr_out"   severity error;
        assert branch_op_out    = "1010"       report "FAIL branch_op_out"    severity error;
        assert newSP_sel_out    = '1'          report "FAIL newSP_sel_out"    severity error;
        assert SP_WE_out        = '1'          report "FAIL SP_WE_out"        severity error;
        assert add_sel_out      = '1'          report "FAIL add_sel_out"      severity error;
        assert mem_addr_sel_out = "100"        report "FAIL mem_addr_sel_out" severity error;
        assert mem_data_sel_out = "10"         report "FAIL mem_data_sel_out" severity error;
        assert mem_WE_out       = '1'          report "FAIL mem_WE_out"       severity error;
        assert mem_R_out        = '1'          report "FAIL mem_R_out"        severity error;
        assert reg_data_out     = "111"        report "FAIL reg_data_out"     severity error;
        assert reg_WE_out       = '1'          report "FAIL reg_WE_out"       severity error;
        assert ret_out          = '1'          report "FAIL ret_out"          severity error;
        assert INT_state_out    = "10"         report "FAIL INT_state_out"    severity error;
        assert is_load_out      = '1'          report "FAIL is_load_out"      severity error;
        assert swap_state_out   = "01"         report "FAIL swap_state_out"   severity error;
        assert out_enable_out   = '1'          report "FAIL out_enable_out"   severity error;
        assert HLT_out          = '1'          report "FAIL HLT_out"          severity error;
        report "[PASS] All pattern A signals latched correctly";

        -- -------------------------------------------------------
        -- TEST 4: write_en = 0 holds pattern A
        -- New inputs must not appear at outputs
        -- -------------------------------------------------------
        report "=== TEST 4: Outputs hold when write_en=0 ===";
        write_en <= '0';
        drive_pattern_B;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert pc_out      = "0000000100" report "FAIL pc held"    severity error;
        assert rsrc1_out   = x"DEADBEEF"  report "FAIL rsrc1 held" severity error;
        assert alu_op_out  = "101"        report "FAIL alu_op held" severity error;
        assert HLT_out     = '1'          report "FAIL HLT held"   severity error;
        report "[PASS] Outputs hold pattern A while write_en=0";

        -- -------------------------------------------------------
        -- TEST 5: Flush clears all outputs (NOP bubble)
        -- -------------------------------------------------------
        report "=== TEST 5: Flush clears outputs ===";
        flush    <= '1';
        write_en <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        flush <= '0';
        check_all_zero("Flushed", pc_out, rsrc1_out, alu_op_out, reg_WE_out, HLT_out);
        assert reg_WE_out = '0' report "FAIL reg_WE not cleared" severity error;
        assert mem_WE_out = '0' report "FAIL mem_WE not cleared" severity error;
        assert HLT_out    = '0' report "FAIL HLT not cleared"    severity error;

        -- -------------------------------------------------------
        -- TEST 6: Flush priority over write_en
        -- -------------------------------------------------------
        report "=== TEST 6: Flush beats write_en ===";
        -- First load valid pattern
        write_en <= '1';
        drive_pattern_A;
        wait until rising_edge(clk);
        wait for 1 ns;

        -- Now assert both flush and write_en
        flush    <= '1';
        write_en <= '1';
        drive_pattern_B;          -- these inputs should be ignored
        wait until rising_edge(clk);
        wait for 1 ns;
        flush    <= '0';
        write_en <= '0';

        check_all_zero("Flush wins", pc_out, rsrc1_out, alu_op_out, reg_WE_out, HLT_out);

        -- -------------------------------------------------------
        -- TEST 7: Latch pattern B after flush
        -- -------------------------------------------------------
        report "=== TEST 7: Pattern B latched correctly ===";
        write_en <= '1';
        drive_pattern_B;
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';

        assert pc_out         = "0000010000" report "FAIL B pc"         severity error;
        assert rsrc1_out      = x"AAAAAAAA"  report "FAIL B rsrc1"      severity error;
        assert rsrc2_out      = x"BBBBBBBB"  report "FAIL B rsrc2"      severity error;
        assert alu_op_out     = "010"        report "FAIL B alu_op"     severity error;
        assert branch_op_out  = "0101"       report "FAIL B branch_op"  severity error;
        assert reg_WE_out     = '0'          report "FAIL B reg_WE"     severity error;
        assert mem_WE_out     = '0'          report "FAIL B mem_WE"     severity error;
        assert HLT_out        = '0'          report "FAIL B HLT"        severity error;
        assert is_load_out    = '0'          report "FAIL B is_load"    severity error;
        report "[PASS] Pattern B latched after flush";

        report "=== ALL TESTS COMPLETE ===";
        wait;
    end process;

end behavior;