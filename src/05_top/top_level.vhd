--------------------------------------------------------------------------------
-- top_level
--   MirCore RISC pipeline top.
--   Currently wired: instruction memory, fetch, IF/ID, decode, ID/EX1.
--   Pending: EX1, EX2, MEM, WB stages, hazard unit, forwarding unit,
--            interrupt handler.
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity top_level is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    interrupt   : in  std_logic;
    input_port  : in  std_logic_vector(31 downto 0);

    -- TEMP testbench-driven flush for IF/ID and ID/EX1.
    -- TODO remove once the hazard unit is integrated and drives flush internally.
    tb_flush    : in  std_logic;

    output_port : out std_logic_vector(31 downto 0);
    core_enable : out std_logic
  );
end entity;

architecture rtl of top_level is

  ------------------------------------------------------------------------------
  -- Component declarations
  ------------------------------------------------------------------------------

  component memory is
    port (
      clk          : in  std_logic;
      mem_write_en : in  std_logic;
      mem_addr     : in  std_logic_vector(9 downto 0);
      mem_data_in  : in  std_logic_vector(31 downto 0);
      mem_data_out : out std_logic_vector(31 downto 0)
    );
  end component;

  component fetch_stage is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      predicted_taken          : out std_logic;
      pc_current               : out std_logic_vector(9 downto 0);
      input_port_passthrough   : out std_logic_vector(31 downto 0);
      inst_to_ifid             : out std_logic_vector(31 downto 0);
      inst_mem_addr            : out std_logic_vector(9 downto 0);
      branch_prediction_result : in  std_logic_vector(1 downto 0);
      pc_write_en              : in  std_logic;
      pc_src_sel               : in  std_logic_vector(1 downto 0);
      corrected_addr_sel       : in  std_logic;
      branch_target_addr       : in  std_logic_vector(9 downto 0);
      branch_fallthrough_addr  : in  std_logic_vector(9 downto 0);
      instruction_word         : in  std_logic_vector(31 downto 0);
      mem_read_addr            : in  std_logic_vector(31 downto 0);
      input_port               : in  std_logic_vector(31 downto 0)
    );
  end component;

  component IFID is
    port (
      clk             : in  std_logic;
      flush           : in  std_logic;
      write_en        : in  std_logic;
      predicted_T     : in  std_logic;
      inst            : in  std_logic_vector(31 downto 0);
      input_port      : in  std_logic_vector(31 downto 0);
      pc              : in  std_logic_vector(9 downto 0);
      predicted_T_out : out std_logic;
      inst_out        : out std_logic_vector(31 downto 0);
      input_port_out  : out std_logic_vector(31 downto 0);
      pc_out          : out std_logic_vector(9 downto 0)
    );
  end component;

  component decode_stage is
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;

      -- From IF/ID register
      predicted_t     : in  std_logic;
      pc              : in  std_logic_vector(9 downto 0);
      inst            : in  std_logic_vector(31 downto 0);
      input_port_in   : in  std_logic_vector(31 downto 0);

      -- From hazard unit
      instruction_sel : in  std_logic_vector(2 downto 0);
      rsrc1_sel       : in  std_logic;
      rdst_sel        : in  std_logic;

      -- From MEM/WB register (write-back path)
      reg_we          : in  std_logic;
      reg_data_sel    : in  std_logic_vector(2 downto 0);
      reg_wb_addr     : in  std_logic_vector(2 downto 0);
      mem_data_out    : in  std_logic_vector(31 downto 0);
      imm_wb          : in  std_logic_vector(15 downto 0);
      alu_res_wb      : in  std_logic_vector(31 downto 0);
      input_port_wb   : in  std_logic_vector(31 downto 0);
      rsrc1_wb        : in  std_logic_vector(31 downto 0);

      -- From EX1/EX2 register
      hw_int_ret_ex1  : in  std_logic_vector(9 downto 0);

      -- To ID/EX1 register
      predicted_t_out : out std_logic;
      hw_int_ret      : out std_logic_vector(9 downto 0);
      pc_out          : out std_logic_vector(9 downto 0);
      rsrc1           : out std_logic_vector(31 downto 0);
      rsrc2           : out std_logic_vector(31 downto 0);
      imm             : out std_logic_vector(15 downto 0);
      reg_dst_addr    : out std_logic_vector(2 downto 0);
      rsrc1_addr      : out std_logic_vector(2 downto 0);
      rsrc2_addr      : out std_logic_vector(2 downto 0);
      input_port_out  : out std_logic_vector(31 downto 0);
      hlt             : out std_logic;
      out_enable      : out std_logic;
      swap_state      : out std_logic_vector(1 downto 0);
      is_load         : out std_logic;
      int_state       : out std_logic_vector(1 downto 0);
      ret             : out std_logic;
      reg_we_out      : out std_logic;
      reg_data_out    : out std_logic_vector(2 downto 0);
      mem_r           : out std_logic;
      mem_we          : out std_logic;
      mem_data_sel    : out std_logic_vector(1 downto 0);
      mem_addr_sel    : out std_logic_vector(2 downto 0);
      add_sel         : out std_logic;
      sp_we           : out std_logic;
      new_sp_sel      : out std_logic;
      branch_op       : out std_logic_vector(3 downto 0);
      modify_fl       : out std_logic_vector(2 downto 0);
      ccr_sel         : out std_logic_vector(2 downto 0);
      alu_op          : out std_logic_vector(2 downto 0);
      alu_src         : out std_logic;

      -- To hazard unit
      int_state_hz    : out std_logic_vector(1 downto 0);
      swap_state_hz   : out std_logic_vector(1 downto 0)
    );
  end component;

  component IDEX1 is
    port (
      clk      : in  std_logic;
      flush    : in  std_logic;
      write_en : in  std_logic;

      -- Data inputs
      predicted_T  : in  std_logic;
      HW_INT_ret   : in  std_logic_vector(9 downto 0);
      pc           : in  std_logic_vector(9 downto 0);
      rsrc1        : in  std_logic_vector(31 downto 0);
      rsrc2        : in  std_logic_vector(31 downto 0);
      imm          : in  std_logic_vector(15 downto 0);
      reg_dst_addr : in  std_logic_vector(2 downto 0);
      rsrc1_addr   : in  std_logic_vector(2 downto 0);
      rsrc2_addr   : in  std_logic_vector(2 downto 0);
      input_port   : in  std_logic_vector(31 downto 0);

      -- Control inputs
      alu_src      : in  std_logic;
      alu_op       : in  std_logic_vector(2 downto 0);
      ccr_sel      : in  std_logic_vector(2 downto 0);
      modify_ccr   : in  std_logic_vector(2 downto 0);
      branch_op    : in  std_logic_vector(3 downto 0);
      newSP_sel    : in  std_logic;
      SP_WE        : in  std_logic;
      add_sel      : in  std_logic;
      mem_addr_sel : in  std_logic_vector(2 downto 0);
      mem_data_sel : in  std_logic_vector(1 downto 0);
      mem_WE       : in  std_logic;
      mem_R        : in  std_logic;
      reg_data     : in  std_logic_vector(2 downto 0);
      reg_WE       : in  std_logic;
      ret          : in  std_logic;
      INT_state    : in  std_logic_vector(1 downto 0);
      is_load      : in  std_logic;
      swap_state   : in  std_logic_vector(1 downto 0);
      out_enable   : in  std_logic;
      HLT          : in  std_logic;

      -- Data outputs
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

      -- Control outputs
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


  ------------------------------------------------------------------------------
  -- Internal signals
  ------------------------------------------------------------------------------

  -- Instruction memory bus
  signal memory_addr     : std_logic_vector(9 downto 0);
  signal memory_data_out : std_logic_vector(31 downto 0);

  -- Fetch -> IF/ID
  signal predict_fetch       : std_logic;
  signal pc_fetch            : std_logic_vector(9 downto 0);
  signal input_port_fetch    : std_logic_vector(31 downto 0);
  signal inst_fetch          : std_logic_vector(31 downto 0);
  signal mem_addr_out_fetch  : std_logic_vector(9 downto 0);

  -- IF/ID -> Decode
  signal predict_to_decode    : std_logic;
  signal pc_to_decode         : std_logic_vector(9 downto 0);
  signal inst_to_decode       : std_logic_vector(31 downto 0);
  signal input_port_to_decode : std_logic_vector(31 downto 0);

  -- Decode -> ID/EX1 (data)
  signal predicted_t_to_IDEX1  : std_logic;
  signal hw_int_ret_to_IDEX1   : std_logic_vector(9 downto 0);
  signal pc_to_IDEX1           : std_logic_vector(9 downto 0);
  signal rsrc1_to_IDEX1        : std_logic_vector(31 downto 0);
  signal rsrc2_to_IDEX1        : std_logic_vector(31 downto 0);
  signal imm_to_IDEX1          : std_logic_vector(15 downto 0);
  signal reg_dst_addr_to_IDEX1 : std_logic_vector(2 downto 0);
  signal rsrc1_addr_to_IDEX1   : std_logic_vector(2 downto 0);
  signal rsrc2_addr_to_IDEX1   : std_logic_vector(2 downto 0);
  signal input_port_to_IDEX1   : std_logic_vector(31 downto 0);

  -- Decode -> ID/EX1 (control)
  -- Note: decode emits "modify_fl"; IDEX1 expects "modify_ccr". Same signal.
  signal alu_src_to_IDEX1      : std_logic;
  signal alu_op_to_IDEX1       : std_logic_vector(2 downto 0);
  signal ccr_sel_to_IDEX1      : std_logic_vector(2 downto 0);
  signal modify_fl_to_IDEX1    : std_logic_vector(2 downto 0);
  signal branch_op_to_IDEX1    : std_logic_vector(3 downto 0);
  signal new_sp_sel_to_IDEX1   : std_logic;
  signal sp_we_to_IDEX1        : std_logic;
  signal add_sel_to_IDEX1      : std_logic;
  signal mem_addr_sel_to_IDEX1 : std_logic_vector(2 downto 0);
  signal mem_data_sel_to_IDEX1 : std_logic_vector(1 downto 0);
  signal mem_we_to_IDEX1       : std_logic;
  signal mem_r_to_IDEX1        : std_logic;
  signal reg_data_to_IDEX1     : std_logic_vector(2 downto 0);
  signal reg_we_to_IDEX1       : std_logic;
  signal ret_to_IDEX1          : std_logic;
  signal int_state_to_IDEX1    : std_logic_vector(1 downto 0);
  signal is_load_to_IDEX1      : std_logic;
  signal swap_state_to_IDEX1   : std_logic_vector(1 downto 0);
  signal out_enable_to_IDEX1   : std_logic;
  signal hlt_to_IDEX1          : std_logic;

  -- ID/EX1 -> EX1 (data)
  signal predicted_t_from_IDEX1  : std_logic;
  signal hw_int_ret_from_IDEX1   : std_logic_vector(9 downto 0);
  signal pc_from_IDEX1           : std_logic_vector(9 downto 0);
  signal rsrc1_from_IDEX1        : std_logic_vector(31 downto 0);
  signal rsrc2_from_IDEX1        : std_logic_vector(31 downto 0);
  signal imm_from_IDEX1          : std_logic_vector(15 downto 0);
  signal reg_dst_addr_from_IDEX1 : std_logic_vector(2 downto 0);
  signal rsrc1_addr_from_IDEX1   : std_logic_vector(2 downto 0);
  signal rsrc2_addr_from_IDEX1   : std_logic_vector(2 downto 0);
  signal input_port_from_IDEX1   : std_logic_vector(31 downto 0);

  -- ID/EX1 -> EX1 (control)
  signal alu_src_from_IDEX1      : std_logic;
  signal alu_op_from_IDEX1       : std_logic_vector(2 downto 0);
  signal ccr_sel_from_IDEX1      : std_logic_vector(2 downto 0);
  signal modify_ccr_from_IDEX1   : std_logic_vector(2 downto 0);
  signal branch_op_from_IDEX1    : std_logic_vector(3 downto 0);
  signal new_sp_sel_from_IDEX1   : std_logic;
  signal sp_we_from_IDEX1        : std_logic;
  signal add_sel_from_IDEX1      : std_logic;
  signal mem_addr_sel_from_IDEX1 : std_logic_vector(2 downto 0);
  signal mem_data_sel_from_IDEX1 : std_logic_vector(1 downto 0);
  signal mem_we_from_IDEX1       : std_logic;
  signal mem_r_from_IDEX1        : std_logic;
  signal reg_data_from_IDEX1     : std_logic_vector(2 downto 0);
  signal reg_we_from_IDEX1       : std_logic;
  signal ret_from_IDEX1          : std_logic;
  signal int_state_from_IDEX1    : std_logic_vector(1 downto 0);
  signal is_load_from_IDEX1      : std_logic;
  signal swap_state_from_IDEX1   : std_logic_vector(1 downto 0);
  signal out_enable_from_IDEX1   : std_logic;
  signal hlt_from_IDEX1          : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Instruction memory
  -- During reset, force address 0 so M[0] (the reset vector) is on the bus.
  -- This breaks the feedback loop in fetch's reset path.
  -- Will become a 3-way mux once MEM/WB drives data accesses.
  ------------------------------------------------------------------------------
  memory_addr <= (others => '0') when rst = '1' else mem_addr_out_fetch;

  u_memory : memory
    port map (
      clk          => clk,
      mem_write_en => '0',                 -- TODO drive from MEM stage
      mem_addr     => memory_addr,
      mem_data_in  => (others => '0'),     -- TODO drive from MEM stage
      mem_data_out => memory_data_out
    );


  ------------------------------------------------------------------------------
  -- Fetch stage
  ------------------------------------------------------------------------------
  u_fetch_stage : fetch_stage
    port map (
      clk                      => clk,
      rst                      => rst,
      predicted_taken          => predict_fetch,
      pc_current               => pc_fetch,
      input_port_passthrough   => input_port_fetch,
      inst_to_ifid             => inst_fetch,
      inst_mem_addr            => mem_addr_out_fetch,
      branch_prediction_result => (others => '0'),  -- TODO from hazard
      pc_write_en              => '1',              -- TODO from hazard
      pc_src_sel               => (others => '0'),  -- TODO from hazard
      corrected_addr_sel       => '0',              -- TODO from hazard
      branch_target_addr       => (others => '0'),  -- TODO from EX1/EX2
      branch_fallthrough_addr  => (others => '0'),  -- TODO from EX1/EX2
      instruction_word         => memory_data_out,
      mem_read_addr            => (others => '0'),  -- TODO from MEM/WB
      input_port               => input_port
    );


  ------------------------------------------------------------------------------
  -- IF/ID pipeline register
  ------------------------------------------------------------------------------
  u_IFID : IFID
    port map (
      clk             => clk,
      flush           => tb_flush,              -- TEMP from TB; TODO from hazard
      write_en        => '1',                   -- TODO from hazard
      predicted_T     => predict_fetch,
      inst            => inst_fetch,
      input_port      => input_port_fetch,
      pc              => pc_fetch,
      predicted_T_out => predict_to_decode,
      inst_out        => inst_to_decode,
      input_port_out  => input_port_to_decode,
      pc_out          => pc_to_decode
    );


  ------------------------------------------------------------------------------
  -- Decode stage
  ------------------------------------------------------------------------------
  u_decode_stage : decode_stage
    port map (
      clk             => clk,
      rst             => rst,

      -- From IF/ID
      predicted_t     => predict_to_decode,
      pc              => pc_to_decode,
      inst            => inst_to_decode,
      input_port_in   => input_port_to_decode,

      -- From hazard unit (TODO)
      instruction_sel => (others => '0'),
      rsrc1_sel       => '0',
      rdst_sel        => '0',

      -- From MEM/WB write-back path (TODO)
      reg_we          => '0',
      reg_data_sel    => (others => '0'),
      reg_wb_addr     => (others => '0'),
      mem_data_out    => (others => '0'),
      imm_wb          => (others => '0'),
      alu_res_wb      => (others => '0'),
      input_port_wb   => (others => '0'),
      rsrc1_wb        => (others => '0'),

      -- From EX1/EX2 (TODO)
      hw_int_ret_ex1  => (others => '0'),

      -- To ID/EX1
      predicted_t_out => predicted_t_to_IDEX1,
      hw_int_ret      => hw_int_ret_to_IDEX1,
      pc_out          => pc_to_IDEX1,
      rsrc1           => rsrc1_to_IDEX1,
      rsrc2           => rsrc2_to_IDEX1,
      imm             => imm_to_IDEX1,
      reg_dst_addr    => reg_dst_addr_to_IDEX1,
      rsrc1_addr      => rsrc1_addr_to_IDEX1,
      rsrc2_addr      => rsrc2_addr_to_IDEX1,
      input_port_out  => input_port_to_IDEX1,
      hlt             => hlt_to_IDEX1,
      out_enable      => out_enable_to_IDEX1,
      swap_state      => swap_state_to_IDEX1,
      is_load         => is_load_to_IDEX1,
      int_state       => int_state_to_IDEX1,
      ret             => ret_to_IDEX1,
      reg_we_out      => reg_we_to_IDEX1,
      reg_data_out    => reg_data_to_IDEX1,
      mem_r           => mem_r_to_IDEX1,
      mem_we          => mem_we_to_IDEX1,
      mem_data_sel    => mem_data_sel_to_IDEX1,
      mem_addr_sel    => mem_addr_sel_to_IDEX1,
      add_sel         => add_sel_to_IDEX1,
      sp_we           => sp_we_to_IDEX1,
      new_sp_sel      => new_sp_sel_to_IDEX1,
      branch_op       => branch_op_to_IDEX1,
      modify_fl       => modify_fl_to_IDEX1,
      ccr_sel         => ccr_sel_to_IDEX1,
      alu_op          => alu_op_to_IDEX1,
      alu_src         => alu_src_to_IDEX1,

      -- To hazard unit (TODO consume)
      int_state_hz    => open,
      swap_state_hz   => open
    );


  ------------------------------------------------------------------------------
  -- ID/EX1 pipeline register
  ------------------------------------------------------------------------------
  u_IDEX1 : IDEX1
    port map (
      clk          => clk,
      flush        => tb_flush,             -- TEMP from TB; TODO from hazard
      write_en     => '0',                  -- TODO from hazard

      -- Data inputs
      predicted_T  => predicted_t_to_IDEX1,
      HW_INT_ret   => hw_int_ret_to_IDEX1,
      pc           => pc_to_IDEX1,
      rsrc1        => rsrc1_to_IDEX1,
      rsrc2        => rsrc2_to_IDEX1,
      imm          => imm_to_IDEX1,
      reg_dst_addr => reg_dst_addr_to_IDEX1,
      rsrc1_addr   => rsrc1_addr_to_IDEX1,
      rsrc2_addr   => rsrc2_addr_to_IDEX1,
      input_port   => input_port_to_IDEX1,

      -- Control inputs
      alu_src      => alu_src_to_IDEX1,
      alu_op       => alu_op_to_IDEX1,
      ccr_sel      => ccr_sel_to_IDEX1,
      modify_ccr   => modify_fl_to_IDEX1,
      branch_op    => branch_op_to_IDEX1,
      newSP_sel    => new_sp_sel_to_IDEX1,
      SP_WE        => sp_we_to_IDEX1,
      add_sel      => add_sel_to_IDEX1,
      mem_addr_sel => mem_addr_sel_to_IDEX1,
      mem_data_sel => mem_data_sel_to_IDEX1,
      mem_WE       => mem_we_to_IDEX1,
      mem_R        => mem_r_to_IDEX1,
      reg_data     => reg_data_to_IDEX1,
      reg_WE       => reg_we_to_IDEX1,
      ret          => ret_to_IDEX1,
      INT_state    => int_state_to_IDEX1,
      is_load      => is_load_to_IDEX1,
      swap_state   => swap_state_to_IDEX1,
      out_enable   => out_enable_to_IDEX1,
      HLT          => hlt_to_IDEX1,

      -- Data outputs (to EX1)
      predicted_T_out  => predicted_t_from_IDEX1,
      HW_INT_ret_out   => hw_int_ret_from_IDEX1,
      pc_out           => pc_from_IDEX1,
      rsrc1_out        => rsrc1_from_IDEX1,
      rsrc2_out        => rsrc2_from_IDEX1,
      imm_out          => imm_from_IDEX1,
      reg_dst_addr_out => reg_dst_addr_from_IDEX1,
      rsrc1_addr_out   => rsrc1_addr_from_IDEX1,
      rsrc2_addr_out   => rsrc2_addr_from_IDEX1,
      input_port_out   => input_port_from_IDEX1,

      -- Control outputs (to EX1)
      alu_src_out      => alu_src_from_IDEX1,
      alu_op_out       => alu_op_from_IDEX1,
      ccr_sel_out      => ccr_sel_from_IDEX1,
      modify_ccr_out   => modify_ccr_from_IDEX1,
      branch_op_out    => branch_op_from_IDEX1,
      newSP_sel_out    => new_sp_sel_from_IDEX1,
      SP_WE_out        => sp_we_from_IDEX1,
      add_sel_out      => add_sel_from_IDEX1,
      mem_addr_sel_out => mem_addr_sel_from_IDEX1,
      mem_data_sel_out => mem_data_sel_from_IDEX1,
      mem_WE_out       => mem_we_from_IDEX1,
      mem_R_out        => mem_r_from_IDEX1,
      reg_data_out     => reg_data_from_IDEX1,
      reg_WE_out       => reg_we_from_IDEX1,
      ret_out          => ret_from_IDEX1,
      INT_state_out    => int_state_from_IDEX1,
      is_load_out      => is_load_from_IDEX1,
      swap_state_out   => swap_state_from_IDEX1,
      out_enable_out   => out_enable_from_IDEX1,
      HLT_out          => hlt_from_IDEX1
    );


  ------------------------------------------------------------------------------
  -- Top-level outputs
  -- Tied off until WB and HLT logic are wired in.
  ------------------------------------------------------------------------------
  output_port <= (others => '0');
  core_enable <= '0';

end architecture;
