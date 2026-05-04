library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EX2MEM_tb is
end EX2MEM_tb;

architecture behavior of EX2MEM_tb is

    component EX2MEM
        port (
            clk      : in std_logic;
            flush    : in std_logic;
            write_en : in std_logic;

            pc           : in std_logic_vector(9 downto 0);
            HW_INT_ret   : in std_logic_vector(9 downto 0);
            alu_res      : in std_logic_vector(31 downto 0);
            add_result   : in std_logic_vector(9 downto 0);
            rsrc1        : in std_logic_vector(31 downto 0);
            imm          : in std_logic_vector(15 downto 0);   -- 16-bit
            reg_dst_addr : in std_logic_vector(2 downto 0);
            input_port   : in std_logic_vector(31 downto 0);

            alu_op       : in std_logic_vector(2 downto 0);
            newSP_sel    : in std_logic;
            SP_WE        : in std_logic;
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

            pc_out           : out std_logic_vector(9 downto 0);
            HW_INT_ret_out   : out std_logic_vector(9 downto 0);
            alu_res_out      : out std_logic_vector(31 downto 0);
            add_result_out   : out std_logic_vector(9 downto 0);
            rsrc1_out        : out std_logic_vector(31 downto 0);
            imm_out          : out std_logic_vector(15 downto 0);  -- 16-bit
            reg_dst_addr_out : out std_logic_vector(2 downto 0);
            input_port_out   : out std_logic_vector(31 downto 0);

            alu_op_out       : out std_logic_vector(2 downto 0);
            newSP_sel_out    : out std_logic;
            SP_WE_out        : out std_logic;
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

    signal clk      : std_logic := '0';
    signal flush    : std_logic := '0';
    signal write_en : std_logic := '0';

    signal pc           : std_logic_vector(9 downto 0)  := (others => '0');
    signal HW_INT_ret   : std_logic_vector(9 downto 0)  := (others => '0');
    signal alu_res      : std_logic_vector(31 downto 0) := (others => '0');
    signal add_result   : std_logic_vector(9 downto 0)  := (others => '0');
    signal rsrc1        : std_logic_vector(31 downto 0) := (others => '0');
    signal imm          : std_logic_vector(15 downto 0) := (others => '0');  -- 16-bit
    signal reg_dst_addr : std_logic_vector(2 downto 0)  := (others => '0');
    signal input_port   : std_logic_vector(31 downto 0) := (others => '0');

    signal alu_op       : std_logic_vector(2 downto 0) := (others => '0');
    signal newSP_sel    : std_logic := '0';
    signal SP_WE        : std_logic := '0';
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

    signal pc_out           : std_logic_vector(9 downto 0);
    signal HW_INT_ret_out   : std_logic_vector(9 downto 0);
    signal alu_res_out      : std_logic_vector(31 downto 0);
    signal add_result_out   : std_logic_vector(9 downto 0);
    signal rsrc1_out        : std_logic_vector(31 downto 0);
    signal imm_out          : std_logic_vector(15 downto 0);  -- 16-bit
    signal reg_dst_addr_out : std_logic_vector(2 downto 0);
    signal input_port_out   : std_logic_vector(31 downto 0);

    signal alu_op_out       : std_logic_vector(2 downto 0);
    signal newSP_sel_out    : std_logic;
    signal SP_WE_out        : std_logic;
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

begin

    uut: EX2MEM
        port map (
            clk            => clk,
            flush          => flush,
            write_en       => write_en,
            pc             => pc,
            HW_INT_ret     => HW_INT_ret,
            alu_res        => alu_res,
            add_result     => add_result,
            rsrc1          => rsrc1,
            imm            => imm,
            reg_dst_addr   => reg_dst_addr,
            input_port     => input_port,
            alu_op         => alu_op,
            newSP_sel      => newSP_sel,
            SP_WE          => SP_WE,
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

            pc_out           => pc_out,
            HW_INT_ret_out   => HW_INT_ret_out,
            alu_res_out      => alu_res_out,
            add_result_out   => add_result_out,
            rsrc1_out        => rsrc1_out,
            imm_out          => imm_out,
            reg_dst_addr_out => reg_dst_addr_out,
            input_port_out   => input_port_out,
            alu_op_out       => alu_op_out,
            newSP_sel_out    => newSP_sel_out,
            SP_WE_out        => SP_WE_out,
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

        procedure drive_pattern_A is
        begin
            pc           <= "0000000100";
            HW_INT_ret   <= "0000000010";
            alu_res      <= x"DEADBEEF";
            add_result   <= "0000100000";   -- addr 32
            rsrc1        <= x"11111111";
            imm          <= x"ABCD";        -- 16-bit, positive
            reg_dst_addr <= "001";
            input_port   <= x"CAFEBABE";
            alu_op       <= "101";
            newSP_sel    <= '1';
            SP_WE        <= '1';
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
            pc           <= "0000010000";
            HW_INT_ret   <= "0000001111";
            alu_res      <= x"AAAAAAAA";
            add_result   <= "0001000000";   -- addr 64
            rsrc1        <= x"33333333";
            imm          <= x"F234";        -- 16-bit, negative (MSB=1)
            reg_dst_addr <= "100";
            input_port   <= x"FFFFFFFF";
            alu_op       <= "010";
            newSP_sel    <= '0';
            SP_WE        <= '0';
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

        -- TEST 1: Initial state
        report "=== TEST 1: Initial state ===";
        wait for 1 ns;
        assert pc_out         = "0000000000" report "FAIL initial pc"         severity error;
        assert alu_res_out    = x"00000000"  report "FAIL initial alu_res"    severity error;
        assert add_result_out = "0000000000" report "FAIL initial add_result" severity error;
        assert imm_out        = x"0000"      report "FAIL initial imm"        severity error;
        assert reg_WE_out     = '0'          report "FAIL initial reg_WE"     severity error;
        assert HLT_out        = '0'          report "FAIL initial HLT"        severity error;
        report "[PASS] Initial state - all outputs zero";

        -- TEST 2: write_en=0 ignores inputs
        report "=== TEST 2: write_en=0 ignores inputs ===";
        write_en <= '0';
        drive_pattern_A;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert pc_out         = "0000000000" report "FAIL pc not held"         severity error;
        assert alu_res_out    = x"00000000"  report "FAIL alu_res not held"    severity error;
        assert add_result_out = "0000000000" report "FAIL add_result not held" severity error;
        assert imm_out        = x"0000"      report "FAIL imm not held"        severity error;
        report "[PASS] write_en=0 - outputs stay at zero";

        -- TEST 3: write_en=1 latches pattern A
        report "=== TEST 3: write_en=1 latches pattern A ===";
        write_en <= '1';
        drive_pattern_A;
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';

        assert pc_out           = "0000000100" report "FAIL pc"           severity error;
        assert HW_INT_ret_out   = "0000000010" report "FAIL HW_INT_ret"   severity error;
        assert alu_res_out      = x"DEADBEEF"  report "FAIL alu_res"      severity error;
        assert add_result_out   = "0000100000" report "FAIL add_result"   severity error;
        assert rsrc1_out        = x"11111111"  report "FAIL rsrc1"        severity error;
        assert imm_out          = x"ABCD"      report "FAIL imm"          severity error;
        assert reg_dst_addr_out = "001"        report "FAIL reg_dst_addr" severity error;
        assert input_port_out   = x"CAFEBABE"  report "FAIL input_port"   severity error;
        assert alu_op_out       = "101"        report "FAIL alu_op"       severity error;
        assert newSP_sel_out    = '1'          report "FAIL newSP_sel"    severity error;
        assert SP_WE_out        = '1'          report "FAIL SP_WE"        severity error;
        assert mem_addr_sel_out = "100"        report "FAIL mem_addr_sel" severity error;
        assert mem_data_sel_out = "10"         report "FAIL mem_data_sel" severity error;
        assert mem_WE_out       = '1'          report "FAIL mem_WE"       severity error;
        assert mem_R_out        = '1'          report "FAIL mem_R"        severity error;
        assert reg_data_out     = "111"        report "FAIL reg_data"     severity error;
        assert reg_WE_out       = '1'          report "FAIL reg_WE"       severity error;
        assert ret_out          = '1'          report "FAIL ret"          severity error;
        assert INT_state_out    = "10"         report "FAIL INT_state"    severity error;
        assert is_load_out      = '1'          report "FAIL is_load"      severity error;
        assert swap_state_out   = "01"         report "FAIL swap_state"   severity error;
        assert out_enable_out   = '1'          report "FAIL out_enable"   severity error;
        assert HLT_out          = '1'          report "FAIL HLT"          severity error;
        report "[PASS] All pattern A signals latched correctly";

        -- TEST 4: Outputs hold when write_en=0
        report "=== TEST 4: Outputs hold when write_en=0 ===";
        write_en <= '0';
        drive_pattern_B;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert pc_out         = "0000000100" report "FAIL pc held"         severity error;
        assert alu_res_out    = x"DEADBEEF"  report "FAIL alu_res held"    severity error;
        assert add_result_out = "0000100000" report "FAIL add_result held" severity error;
        assert imm_out        = x"ABCD"      report "FAIL imm held"        severity error;
        assert HLT_out        = '1'          report "FAIL HLT held"        severity error;
        report "[PASS] Outputs hold pattern A while write_en=0";

        -- TEST 5: Flush clears all outputs
        report "=== TEST 5: Flush clears outputs ===";
        flush    <= '1';
        write_en <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        flush <= '0';
        assert pc_out         = "0000000000" report "FAIL flushed pc"         severity error;
        assert alu_res_out    = x"00000000"  report "FAIL flushed alu_res"    severity error;
        assert add_result_out = "0000000000" report "FAIL flushed add_result" severity error;
        assert imm_out        = x"0000"      report "FAIL flushed imm"        severity error;
        assert reg_WE_out     = '0'          report "FAIL flushed reg_WE"     severity error;
        assert mem_WE_out     = '0'          report "FAIL flushed mem_WE"     severity error;
        assert HLT_out        = '0'          report "FAIL flushed HLT"        severity error;
        report "[PASS] Flush cleared all outputs";

        -- TEST 6: Flush priority over write_en
        report "=== TEST 6: Flush beats write_en ===";
        write_en <= '1';
        drive_pattern_A;
        wait until rising_edge(clk);
        wait for 1 ns;

        flush    <= '1';
        write_en <= '1';
        drive_pattern_B;
        wait until rising_edge(clk);
        wait for 1 ns;
        flush    <= '0';
        write_en <= '0';

        assert pc_out         = "0000000000" report "FAIL flush>wr pc"         severity error;
        assert alu_res_out    = x"00000000"  report "FAIL flush>wr alu_res"    severity error;
        assert add_result_out = "0000000000" report "FAIL flush>wr add_result" severity error;
        assert imm_out        = x"0000"      report "FAIL flush>wr imm"        severity error;
        assert reg_WE_out     = '0'          report "FAIL flush>wr reg_WE"     severity error;
        assert HLT_out        = '0'          report "FAIL flush>wr HLT"        severity error;
        report "[PASS] Flush wins over write_en";

        -- TEST 7: Latch pattern B ? negative immediate (MSB=1)
        report "=== TEST 7: Pattern B latched (negative imm) ===";
        write_en <= '1';
        drive_pattern_B;
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';

        assert pc_out         = "0000010000" report "FAIL B pc"         severity error;
        assert alu_res_out    = x"AAAAAAAA"  report "FAIL B alu_res"    severity error;
        assert add_result_out = "0001000000" report "FAIL B add_result" severity error;
        assert rsrc1_out      = x"33333333"  report "FAIL B rsrc1"      severity error;
        assert imm_out        = x"F234"      report "FAIL B imm (neg)"  severity error;
        assert alu_op_out     = "010"        report "FAIL B alu_op"     severity error;
        assert reg_WE_out     = '0'          report "FAIL B reg_WE"     severity error;
        assert mem_WE_out     = '0'          report "FAIL B mem_WE"     severity error;
        assert HLT_out        = '0'          report "FAIL B HLT"        severity error;
        report "[PASS] Pattern B latched with negative imm";

        -- TEST 8: Boundary address ? max address 1023
        report "=== TEST 8: Max address 1023 ===";
        write_en   <= '1';
        add_result <= "1111111111";   -- addr 1023
        pc         <= "0000000001";
        alu_res    <= x"BBBBBBBB";
        imm        <= x"7FFF";        -- max positive 16-bit
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';
        assert add_result_out = "1111111111" report "FAIL max addr"    severity error;
        assert imm_out        = x"7FFF"      report "FAIL max pos imm" severity error;
        report "[PASS] Max address and max positive imm latched correctly";

        report "=== ALL TESTS COMPLETE ===";
        wait;
    end process;

end behavior;