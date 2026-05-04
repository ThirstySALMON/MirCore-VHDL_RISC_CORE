library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MEMWB_tb is
end MEMWB_tb;

architecture behavior of MEMWB_tb is

    component MEMWB
        port (
            clk      : in std_logic;
            flush    : in std_logic;
            write_en : in std_logic;

            alu_res      : in std_logic_vector(31 downto 0);
            rsrc1        : in std_logic_vector(31 downto 0);
            mem_data_out : in std_logic_vector(31 downto 0);
            imm          : in std_logic_vector(15 downto 0);
            reg_dst_addr : in std_logic_vector(2 downto 0);
            input_port   : in std_logic_vector(31 downto 0);

            alu_op       : in std_logic_vector(2 downto 0);
            reg_data     : in std_logic_vector(2 downto 0);
            reg_WE       : in std_logic;
            ret          : in std_logic;
            SW_INTDone   : in std_logic_vector(1 downto 0);
            is_load      : in std_logic;
            out_enable   : in std_logic;
            HLT          : in std_logic;

            alu_res_out      : out std_logic_vector(31 downto 0);
            rsrc1_out        : out std_logic_vector(31 downto 0);
            mem_data_out_out : out std_logic_vector(31 downto 0);
            imm_out          : out std_logic_vector(15 downto 0);
            reg_dst_addr_out : out std_logic_vector(2 downto 0);
            input_port_out   : out std_logic_vector(31 downto 0);

            alu_op_out       : out std_logic_vector(2 downto 0);
            reg_data_out     : out std_logic_vector(2 downto 0);
            reg_WE_out       : out std_logic;
            ret_out          : out std_logic;
            SW_INTDone_out   : out std_logic_vector(1 downto 0);
            is_load_out      : out std_logic;
            out_enable_out   : out std_logic;
            HLT_out          : out std_logic
        );
    end component;

    signal clk      : std_logic := '0';
    signal flush    : std_logic := '0';
    signal write_en : std_logic := '0';

    signal alu_res      : std_logic_vector(31 downto 0) := (others => '0');
    signal rsrc1        : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_data_out : std_logic_vector(31 downto 0) := (others => '0');
    signal imm          : std_logic_vector(15 downto 0) := (others => '0');
    signal reg_dst_addr : std_logic_vector(2 downto 0)  := (others => '0');
    signal input_port   : std_logic_vector(31 downto 0) := (others => '0');

    signal alu_op       : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_data     : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_WE       : std_logic := '0';
    signal ret          : std_logic := '0';
    signal SW_INTDone   : std_logic_vector(1 downto 0) := (others => '0');
    signal is_load      : std_logic := '0';
    signal out_enable   : std_logic := '0';
    signal HLT          : std_logic := '0';

    signal alu_res_out      : std_logic_vector(31 downto 0);
    signal rsrc1_out        : std_logic_vector(31 downto 0);
    signal mem_data_out_out : std_logic_vector(31 downto 0);
    signal imm_out          : std_logic_vector(15 downto 0);
    signal reg_dst_addr_out : std_logic_vector(2 downto 0);
    signal input_port_out   : std_logic_vector(31 downto 0);

    signal alu_op_out       : std_logic_vector(2 downto 0);
    signal reg_data_out     : std_logic_vector(2 downto 0);
    signal reg_WE_out       : std_logic;
    signal ret_out          : std_logic;
    signal SW_INTDone_out   : std_logic_vector(1 downto 0);
    signal is_load_out      : std_logic;
    signal out_enable_out   : std_logic;
    signal HLT_out          : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: MEMWB
        port map (
            clk              => clk,
            flush            => flush,
            write_en         => write_en,
            alu_res          => alu_res,
            rsrc1            => rsrc1,
            mem_data_out     => mem_data_out,
            imm              => imm,
            reg_dst_addr     => reg_dst_addr,
            input_port       => input_port,
            alu_op           => alu_op,
            reg_data         => reg_data,
            reg_WE           => reg_WE,
            ret              => ret,
            SW_INTDone       => SW_INTDone,
            is_load          => is_load,
            out_enable       => out_enable,
            HLT              => HLT,

            alu_res_out      => alu_res_out,
            rsrc1_out        => rsrc1_out,
            mem_data_out_out => mem_data_out_out,
            imm_out          => imm_out,
            reg_dst_addr_out => reg_dst_addr_out,
            input_port_out   => input_port_out,
            alu_op_out       => alu_op_out,
            reg_data_out     => reg_data_out,
            reg_WE_out       => reg_WE_out,
            ret_out          => ret_out,
            SW_INTDone_out   => SW_INTDone_out,
            is_load_out      => is_load_out,
            out_enable_out   => out_enable_out,
            HLT_out          => HLT_out
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc : process

        -- Pattern A: ALU instruction writing back result
        procedure drive_pattern_A is
        begin
            alu_res      <= x"DEADBEEF";
            rsrc1        <= x"11111111";
            mem_data_out <= x"00000000";    -- no memory data
            imm          <= x"ABCD";
            reg_dst_addr <= "001";
            input_port   <= x"CAFEBABE";
            alu_op       <= "101";
            reg_data     <= "111";
            reg_WE       <= '1';
            ret          <= '0';
            SW_INTDone   <= "00";
            is_load      <= '0';
            out_enable   <= '1';
            HLT          <= '0';
        end procedure;

        -- Pattern B: LDD instruction writing back memory data
        procedure drive_pattern_B is
        begin
            alu_res      <= x"AAAAAAAA";
            rsrc1        <= x"33333333";
            mem_data_out <= x"FEEDFACE";    -- data read from memory
            imm          <= x"F234";
            reg_dst_addr <= "100";
            input_port   <= x"FFFFFFFF";
            alu_op       <= "010";
            reg_data     <= "010";
            reg_WE       <= '1';
            ret          <= '1';
            SW_INTDone   <= "10";           -- interrupt done state
            is_load      <= '1';
            out_enable   <= '0';
            HLT          <= '1';
        end procedure;

    begin

        -- TEST 1: Initial state
        report "=== TEST 1: Initial state ===";
        wait for 1 ns;
        assert alu_res_out      = x"00000000"  report "FAIL initial alu_res"      severity error;
        assert mem_data_out_out = x"00000000"  report "FAIL initial mem_data_out" severity error;
        assert imm_out          = x"0000"      report "FAIL initial imm"          severity error;
        assert reg_WE_out       = '0'          report "FAIL initial reg_WE"       severity error;
        assert HLT_out          = '0'          report "FAIL initial HLT"          severity error;
        assert SW_INTDone_out   = "00"         report "FAIL initial SW_INTDone"   severity error;
        report "[PASS] Initial state - all outputs zero";

        -- TEST 2: write_en=0 ignores inputs
        report "=== TEST 2: write_en=0 ignores inputs ===";
        write_en <= '0';
        drive_pattern_A;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert alu_res_out      = x"00000000" report "FAIL alu_res not held"      severity error;
        assert mem_data_out_out = x"00000000" report "FAIL mem_data_out not held" severity error;
        assert reg_WE_out       = '0'         report "FAIL reg_WE not held"       severity error;
        report "[PASS] write_en=0 - outputs stay at zero";

        -- TEST 3: write_en=1 latches pattern A (ALU writeback)
        report "=== TEST 3: write_en=1 latches pattern A ===";
        write_en <= '1';
        drive_pattern_A;
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';

        assert alu_res_out      = x"DEADBEEF"  report "FAIL alu_res"      severity error;
        assert rsrc1_out        = x"11111111"  report "FAIL rsrc1"        severity error;
        assert mem_data_out_out = x"00000000"  report "FAIL mem_data_out" severity error;
        assert imm_out          = x"ABCD"      report "FAIL imm"          severity error;
        assert reg_dst_addr_out = "001"        report "FAIL reg_dst_addr" severity error;
        assert input_port_out   = x"CAFEBABE"  report "FAIL input_port"   severity error;
        assert alu_op_out       = "101"        report "FAIL alu_op"       severity error;
        assert reg_data_out     = "111"        report "FAIL reg_data"     severity error;
        assert reg_WE_out       = '1'          report "FAIL reg_WE"       severity error;
        assert ret_out          = '0'          report "FAIL ret"          severity error;
        assert SW_INTDone_out   = "00"         report "FAIL SW_INTDone"   severity error;
        assert is_load_out      = '0'          report "FAIL is_load"      severity error;
        assert out_enable_out   = '1'          report "FAIL out_enable"   severity error;
        assert HLT_out          = '0'          report "FAIL HLT"          severity error;
        report "[PASS] All pattern A signals latched correctly";

        -- TEST 4: Outputs hold when write_en=0
        report "=== TEST 4: Outputs hold when write_en=0 ===";
        write_en <= '0';
        drive_pattern_B;
        wait until rising_edge(clk);
        wait for 1 ns;
        assert alu_res_out      = x"DEADBEEF" report "FAIL alu_res held"      severity error;
        assert mem_data_out_out = x"00000000" report "FAIL mem_data_out held" severity error;
        assert out_enable_out   = '1'         report "FAIL out_enable held"   severity error;
        assert HLT_out          = '0'         report "FAIL HLT held"          severity error;
        report "[PASS] Outputs hold pattern A while write_en=0";

        -- TEST 5: Flush clears all outputs
        report "=== TEST 5: Flush clears outputs ===";
        flush    <= '1';
        write_en <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        flush <= '0';
        assert alu_res_out      = x"00000000" report "FAIL flushed alu_res"      severity error;
        assert mem_data_out_out = x"00000000" report "FAIL flushed mem_data_out" severity error;
        assert imm_out          = x"0000"     report "FAIL flushed imm"          severity error;
        assert reg_WE_out       = '0'         report "FAIL flushed reg_WE"       severity error;
        assert SW_INTDone_out   = "00"        report "FAIL flushed SW_INTDone"   severity error;
        assert HLT_out          = '0'         report "FAIL flushed HLT"          severity error;
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

        assert alu_res_out    = x"00000000" report "FAIL flush>wr alu_res"    severity error;
        assert reg_WE_out     = '0'         report "FAIL flush>wr reg_WE"     severity error;
        assert SW_INTDone_out = "00"        report "FAIL flush>wr SW_INTDone" severity error;
        assert HLT_out        = '0'         report "FAIL flush>wr HLT"        severity error;
        report "[PASS] Flush wins over write_en";

        -- TEST 7: Pattern B — LDD writeback with mem_data_out + interrupt done
        report "=== TEST 7: Pattern B (LDD + interrupt done) ===";
        write_en <= '1';
        drive_pattern_B;
        wait until rising_edge(clk);
        wait for 1 ns;
        write_en <= '0';

        assert alu_res_out      = x"AAAAAAAA"  report "FAIL B alu_res"      severity error;
        assert rsrc1_out        = x"33333333"  report "FAIL B rsrc1"        severity error;
        assert mem_data_out_out = x"FEEDFACE"  report "FAIL B mem_data_out" severity error;
        assert imm_out          = x"F234"      report "FAIL B imm"          severity error;
        assert reg_dst_addr_out = "100"        report "FAIL B reg_dst_addr" severity error;
        assert alu_op_out       = "010"        report "FAIL B alu_op"       severity error;
        assert reg_data_out     = "010"        report "FAIL B reg_data"     severity error;
        assert reg_WE_out       = '1'          report "FAIL B reg_WE"       severity error;
        assert ret_out          = '1'          report "FAIL B ret"          severity error;
        assert SW_INTDone_out   = "10"         report "FAIL B SW_INTDone"   severity error;
        assert is_load_out      = '1'          report "FAIL B is_load"      severity error;
        assert out_enable_out   = '0'          report "FAIL B out_enable"   severity error;
        assert HLT_out          = '1'          report "FAIL B HLT"          severity error;
        report "[PASS] Pattern B latched correctly (LDD + interrupt done)";

        report "=== ALL TESTS COMPLETE ===";
        wait;
    end process;

end behavior;
