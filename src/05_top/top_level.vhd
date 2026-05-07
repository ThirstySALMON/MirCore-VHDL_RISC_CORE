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
      clk              : in  std_logic;
      flush            : in  std_logic;
      write_en         : in  std_logic;

      -- Data inputs
      predicted_T      : in  std_logic;
      HW_INT_ret       : in  std_logic_vector(9 downto 0);
      pc               : in  std_logic_vector(9 downto 0);
      rsrc1            : in  std_logic_vector(31 downto 0);
      rsrc2            : in  std_logic_vector(31 downto 0);
      imm              : in  std_logic_vector(15 downto 0);
      reg_dst_addr     : in  std_logic_vector(2 downto 0);
      rsrc1_addr       : in  std_logic_vector(2 downto 0);
      rsrc2_addr       : in  std_logic_vector(2 downto 0);
      input_port       : in  std_logic_vector(31 downto 0);

      -- Control inputs
      alu_src          : in  std_logic;
      alu_op           : in  std_logic_vector(2 downto 0);
      ccr_sel          : in  std_logic_vector(2 downto 0);
      modify_ccr       : in  std_logic_vector(2 downto 0);
      branch_op        : in  std_logic_vector(3 downto 0);
      newSP_sel        : in  std_logic;
      SP_WE            : in  std_logic;
      add_sel          : in  std_logic;
      mem_addr_sel     : in  std_logic_vector(2 downto 0);
      mem_data_sel     : in  std_logic_vector(1 downto 0);
      mem_WE           : in  std_logic;
      mem_R            : in  std_logic;
      reg_data         : in  std_logic_vector(2 downto 0);
      reg_WE           : in  std_logic;
      ret              : in  std_logic;
      INT_state        : in  std_logic_vector(1 downto 0);
      is_load          : in  std_logic;
      swap_state       : in  std_logic_vector(1 downto 0);
      out_enable       : in  std_logic;
      HLT              : in  std_logic;

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

  component EX1 is
    port (
      HLT_in_id_ex1                   : in  std_logic;
      HLT_out_ex1_ex2                 : out std_logic;

      out_enable_in_id_ex1            : in  std_logic;
      out_enable_out_ex1_ex2          : out std_logic;

      swap_state_in_id_ex1            : in  std_logic_vector(1 downto 0);
      swap_state_out_hazard_ex1_ex2   : out std_logic_vector(1 downto 0);

      is_load_in_id_ex1               : in  std_logic;
      is_load_out_hazard_ex1_ex2      : out std_logic;

      INT_state_in_id_ex1             : in  std_logic_vector(1 downto 0);
      INT_state_out_hazard_ex1_ex2    : out std_logic_vector(1 downto 0);

      ret_in_id_ex1                   : in  std_logic;
      ret_out_hazard_ex1_ex2          : out std_logic;

      reg_WE_in_id_ex1                : in  std_logic;
      reg_WE_out_ex1_ex2              : out std_logic;

      reg_data_in_id_ex1              : in  std_logic_vector(2 downto 0);
      reg_data_out_ex1_ex2            : out std_logic_vector(2 downto 0);

      mem_R_in_id_ex1                 : in  std_logic;
      mem_R_out_ex1_ex2               : out std_logic;

      mem_WE_in_id_ex1                : in  std_logic;
      mem_WE_out_ex1_ex2              : out std_logic;

      mem_data_sel_in_id_ex1          : in  std_logic_vector(1 downto 0);
      mem_data_sel_out_ex1_ex2        : out std_logic_vector(1 downto 0);

      mem_addr_sel_in_id_ex1          : in  std_logic_vector(2 downto 0);
      mem_addr_sel_out_ex1_ex2        : out std_logic_vector(2 downto 0);

      add_sel_in_id_ex1               : in  std_logic;
      add_sel_out_ex1_ex2             : out std_logic;

      SP_WE_in_id_ex1                 : in  std_logic;
      SP_WE_out_ex1_ex2               : out std_logic;

      newSP_sel_in_id_ex1             : in  std_logic;
      newSP_sel_out_ex1_ex2           : out std_logic;

      branch_op_in_id_ex1             : in  std_logic_vector(3 downto 0);
      branch_op_out_ex1_ex2           : out std_logic_vector(3 downto 0);

      modify_ccr_in_id_ex1            : in  std_logic_vector(2 downto 0);
      modify_ccr_out_ex1_ex2          : out std_logic_vector(2 downto 0);

      ccr_sel_in_id_ex1               : in  std_logic_vector(2 downto 0);
      ccr_sel_out_ex1_ex2             : out std_logic_vector(2 downto 0);

      -- ALU operation code; fed to the ALU and forwarded to EX1/EX2
      alu_op_in_id_ex1                : in  std_logic_vector(2 downto 0);
      alu_op_out_alu_ex1_ex2          : out std_logic_vector(2 downto 0);

      -- Operand-B source select: 0 = forwarded rsrc2, 1 = sign-extended immediate
      alu_src_in_id_ex1               : in  std_logic;

      predicted_T_in_id_ex1           : in  std_logic;
      predicted_T_out_ex1_ex2         : out std_logic;

      HW_INT_ret_in_id_ex1            : in  std_logic_vector(9 downto 0);
      HW_INT_ret_out_ex1_ex2          : out std_logic_vector(9 downto 0);

      pc_in_id_ex1                    : in  std_logic_vector(9 downto 0);
      pc_out_ex1_ex2                  : out std_logic_vector(9 downto 0);

      ----------------------------------------------------------------------------
      -- Data signals
      ----------------------------------------------------------------------------
      -- Register-file reads from decode; pre-forwarding ALU operands
      rsrc1_in_id_ex1                 : in  std_logic_vector(31 downto 0);
      rsrc2_in_id_ex1                 : in  std_logic_vector(31 downto 0);

      -- Raw 16-bit immediate from decode; forwarded to EX1/EX2 as-is (SE done internally)
      imm_in_id_ex1                   : in  std_logic_vector(15 downto 0);
      imm_out_ex1_ex2                 : out std_logic_vector(15 downto 0); -- carries raw imm, despite _se_ in name

      -- Destination and source register addresses
      reg_dst_addr_in_id_ex1          : in  std_logic_vector(2 downto 0);
      reg_dst_addr_out_hazard_ex1_ex2 : out std_logic_vector(2 downto 0);

      rsrc1_addr_in_id_ex1            : in  std_logic_vector(2 downto 0);
      rsrc1_addr_out_fwd              : out std_logic_vector(2 downto 0);  -- to Forwarding Unit

      rsrc2_addr_in_id_ex1            : in  std_logic_vector(2 downto 0);
      rsrc2_addr_out_fwd              : out std_logic_vector(2 downto 0);  -- to Forwarding Unit

      -- External input port passthrough (IN instruction)
      input_port_in_id_ex1            : in  std_logic_vector(31 downto 0);
      input_port_out_ex1_ex2          : out std_logic_vector(31 downto 0);

      ----------------------------------------------------------------------------
      -- ALU outputs driven to EX1/EX2 register
      ----------------------------------------------------------------------------
      ccr_out_ex1_ex2                 : out std_logic_vector(2 downto 0);
      alu_result_out_ex1_ex2          : out std_logic_vector(31 downto 0);

      ----------------------------------------------------------------------------
      -- Forwarding-mux data sources (tapped from later pipeline registers)
      ----------------------------------------------------------------------------
      -- ALU results: used for register-value forwarding (sel "001"–"011")
      alu_res_in_ex1_ex2              : in  std_logic_vector(31 downto 0);
      alu_res_in_ex2_mem              : in  std_logic_vector(31 downto 0);
      alu_res_in_mem_wb               : in  std_logic_vector(31 downto 0);

      -- Memory read result: used for load-use forwarding (sel "100")
      mem_data_out_in_mem_wb          : in  std_logic_vector(31 downto 0);

      -- Raw 16-bit immediates from later stages; sign-extended internally for
      -- operand-B forwarding when a prior instruction used an immediate (sel "101"–"111")
      imm_in_ex1_ex2                  : in  std_logic_vector(15 downto 0);
      imm_in_ex2_mem                  : in  std_logic_vector(15 downto 0);
      imm_in_mem_wb                   : in  std_logic_vector(15 downto 0);

      -- Forwarding-mux selects driven by the Forwarding Unit
      rsrc1_fwd_sel_in_fwd            : in  std_logic_vector(2 downto 0);
      rsrc2_fwd_sel_in_fwd            : in  std_logic_vector(2 downto 0);

      -- Post-forwarding operand values forwarded to EX1/EX2
      rsrc1_out_ex1_ex2               : out std_logic_vector(31 downto 0);
      rsrc2_out_ex1_ex2               : out std_logic_vector(31 downto 0)
    );
  end component;

  component EX1EX2 is
    port (

      clk              : in  std_logic;
      flush            : in  std_logic;
      write_en         : in  std_logic;

      -- Data signals Inputs
      predicted_T      : in  std_logic;
      pc               : in  std_logic_vector(9 downto 0);
      HW_INT_ret       : in  std_logic_vector(9 downto 0);
      ccr              : in  std_logic_vector(2 downto 0);  -- Z, N, C flags
      alu_res          : in  std_logic_vector(31 downto 0); -- ALU result from EX1
      rsrc1            : in  std_logic_vector(31 downto 0);
      rsrc2            : in  std_logic_vector(31 downto 0);
      imm              : in  std_logic_vector(15 downto 0);
      reg_dst_addr     : in  std_logic_vector(2 downto 0);
      input_port       : in  std_logic_vector(31 downto 0);

      -- Control signals Inputs
      alu_op           : in  std_logic_vector(2 downto 0);
      ccr_sel          : in  std_logic_vector(2 downto 0);
      modify_ccr       : in  std_logic_vector(2 downto 0);
      branch_op        : in  std_logic_vector(3 downto 0);
      newSP_sel        : in  std_logic;
      SP_WE            : in  std_logic;
      add_sel          : in  std_logic;
      mem_addr_sel     : in  std_logic_vector(2 downto 0);
      mem_data_sel     : in  std_logic_vector(1 downto 0);
      mem_WE           : in  std_logic;
      mem_R            : in  std_logic;
      reg_data         : in  std_logic_vector(2 downto 0);
      reg_WE           : in  std_logic;
      ret              : in  std_logic;
      INT_state        : in  std_logic_vector(1 downto 0);
      is_load          : in  std_logic;
      swap_state       : in  std_logic_vector(1 downto 0);
      out_enable       : in  std_logic;
      HLT              : in  std_logic;

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
    ); end component;
    ------------------------------------------------------------------------------
    -- Internal signals
    ------------------------------------------------------------------------------

    -- Instruction memory bus
    signal memory_addr     : std_logic_vector(9 downto 0);
    signal memory_data_out : std_logic_vector(31 downto 0);

    -- Fetch -> IF/ID
    signal predict_fetch      : std_logic;
    signal pc_fetch           : std_logic_vector(9 downto 0);
    signal input_port_fetch   : std_logic_vector(31 downto 0);
    signal inst_fetch         : std_logic_vector(31 downto 0);
    signal mem_addr_out_fetch : std_logic_vector(9 downto 0);

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

    -- EX1 -> EX1/EX2 (data)
    -- TODO: feed these into the EX1/EX2 pipeline register once it exists.
    signal predicted_t_from_EX1 : std_logic;
    signal hw_int_ret_from_EX1  : std_logic_vector(9 downto 0);
    signal pc_from_EX1          : std_logic_vector(9 downto 0);
    signal rsrc1_from_EX1       : std_logic_vector(31 downto 0);
    signal rsrc2_from_EX1       : std_logic_vector(31 downto 0);
    signal imm_from_EX1         : std_logic_vector(15 downto 0);
    signal input_port_from_EX1  : std_logic_vector(31 downto 0);
    signal alu_result_from_EX1  : std_logic_vector(31 downto 0);
    signal ccr_from_EX1         : std_logic_vector(2 downto 0);

    -- EX1 -> EX1/EX2 (control)
    signal alu_op_from_EX1       : std_logic_vector(2 downto 0);
    signal ccr_sel_from_EX1      : std_logic_vector(2 downto 0);
    signal modify_ccr_from_EX1   : std_logic_vector(2 downto 0);
    signal branch_op_from_EX1    : std_logic_vector(3 downto 0);
    signal new_sp_sel_from_EX1   : std_logic;
    signal sp_we_from_EX1        : std_logic;
    signal add_sel_from_EX1      : std_logic;
    signal mem_addr_sel_from_EX1 : std_logic_vector(2 downto 0);
    signal mem_data_sel_from_EX1 : std_logic_vector(1 downto 0);
    signal mem_we_from_EX1       : std_logic;
    signal mem_r_from_EX1        : std_logic;
    signal reg_data_from_EX1     : std_logic_vector(2 downto 0);
    signal reg_we_from_EX1       : std_logic;
    signal out_enable_from_EX1   : std_logic;
    signal hlt_from_EX1          : std_logic; -- EX1 -> Hazard Unit

    -- EX1 -> Hazard Unit
    -- TODO: consume in the Hazard Unit once instantiated.
    signal swap_state_from_EX1   : std_logic_vector(1 downto 0);
    signal is_load_from_EX1      : std_logic;
    signal int_state_from_EX1    : std_logic_vector(1 downto 0);
    signal ret_from_EX1          : std_logic;
    signal reg_dst_addr_from_EX1 : std_logic_vector(2 downto 0);

    -- EX1 -> Forwarding Unit
    -- TODO: consume in the Forwarding Unit once instantiated.
    signal rsrc1_addr_from_EX1 : std_logic_vector(2 downto 0);
    signal rsrc2_addr_from_EX1 : std_logic_vector(2 downto 0);

    -- EX1/EX2 -> EX2 (data)
    -- alu_res_from_EX1EX2 and imm_from_EX1EX2 also feed EX1's forwarding muxes.
    signal predicted_t_from_EX1EX2  : std_logic;
    signal pc_from_EX1EX2           : std_logic_vector(9 downto 0);
    signal hw_int_ret_from_EX1EX2   : std_logic_vector(9 downto 0);
    signal ccr_from_EX1EX2          : std_logic_vector(2 downto 0);
    signal alu_res_from_EX1EX2      : std_logic_vector(31 downto 0);
    signal rsrc1_from_EX1EX2        : std_logic_vector(31 downto 0);
    signal rsrc2_from_EX1EX2        : std_logic_vector(31 downto 0);
    signal imm_from_EX1EX2          : std_logic_vector(15 downto 0);
    signal reg_dst_addr_from_EX1EX2 : std_logic_vector(2 downto 0);
    signal input_port_from_EX1EX2   : std_logic_vector(31 downto 0);

    -- EX1/EX2 -> EX2 (control)
    signal alu_op_from_EX1EX2       : std_logic_vector(2 downto 0);
    signal ccr_sel_from_EX1EX2      : std_logic_vector(2 downto 0);
    signal modify_ccr_from_EX1EX2   : std_logic_vector(2 downto 0);
    signal branch_op_from_EX1EX2    : std_logic_vector(3 downto 0);
    signal new_sp_sel_from_EX1EX2   : std_logic;
    signal sp_we_from_EX1EX2        : std_logic;
    signal add_sel_from_EX1EX2      : std_logic;
    signal mem_addr_sel_from_EX1EX2 : std_logic_vector(2 downto 0);
    signal mem_data_sel_from_EX1EX2 : std_logic_vector(1 downto 0);
    signal mem_we_from_EX1EX2       : std_logic;
    signal mem_r_from_EX1EX2        : std_logic;
    signal reg_data_from_EX1EX2     : std_logic_vector(2 downto 0);
    signal reg_we_from_EX1EX2       : std_logic;
    signal ret_from_EX1EX2          : std_logic;
    signal int_state_from_EX1EX2    : std_logic_vector(1 downto 0);
    signal is_load_from_EX1EX2      : std_logic;
    signal swap_state_from_EX1EX2   : std_logic_vector(1 downto 0);
    signal out_enable_from_EX1EX2   : std_logic;
    signal hlt_from_EX1EX2          : std_logic;

  begin

    ------------------------------------------------------------------------------
    -- Instruction memory
    -- During reset, force address 0 so M[0] (the reset vector) is on the bus.
    -- This breaks the feedback loop in fetch's reset path.
    -- Will become a 3-way mux once MEM/WB drives data accesses.
    ------------------------------------------------------------------------------
    memory_addr <= (others => '0') when rst = '1'
    else
    mem_addr_out_fetch;

    u_memory: memory
    port map (
      clk          => clk,
      mem_write_en => '0',             -- TODO drive from MEM stage
      mem_addr     => memory_addr,
      mem_data_in  => (others => '0'), -- TODO drive from MEM stage
      mem_data_out => memory_data_out
    );

    ------------------------------------------------------------------------------
    -- Fetch stage
    ------------------------------------------------------------------------------
    u_fetch_stage: fetch_stage
    port map (
      clk                      => clk,
      rst                      => rst,
      predicted_taken          => predict_fetch,
      pc_current               => pc_fetch,
      input_port_passthrough   => input_port_fetch,
      inst_to_ifid             => inst_fetch,
      inst_mem_addr            => mem_addr_out_fetch,
      branch_prediction_result => (others => '0'), -- TODO from hazard
      pc_write_en              => '1',             -- TODO from hazard
      pc_src_sel               => (others => '0'), -- TODO from hazard
      corrected_addr_sel       => '0',             -- TODO from hazard
      branch_target_addr       => (others => '0'), -- TODO from EX1/EX2
      branch_fallthrough_addr  => (others => '0'), -- TODO from EX1/EX2
      instruction_word         => memory_data_out,
      mem_read_addr            => (others => '0'), -- TODO from MEM/WB
      input_port               => input_port
    );

    ------------------------------------------------------------------------------
    -- IF/ID pipeline register
    ------------------------------------------------------------------------------
    u_IFID: IFID
    port map (
      clk             => clk,
      flush           => tb_flush, -- TEMP from TB; TODO from hazard
      write_en        => '1',      -- TODO from hazard
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
    u_decode_stage: decode_stage
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
    u_IDEX1: IDEX1
    port map (
      clk              => clk,
      flush            => tb_flush, -- TEMP from TB; TODO from hazard
      write_en         => '1',      -- TODO from hazard

      -- Data inputs
      predicted_T      => predicted_t_to_IDEX1,
      HW_INT_ret       => hw_int_ret_to_IDEX1,
      pc               => pc_to_IDEX1,
      rsrc1            => rsrc1_to_IDEX1,
      rsrc2            => rsrc2_to_IDEX1,
      imm              => imm_to_IDEX1,
      reg_dst_addr     => reg_dst_addr_to_IDEX1,
      rsrc1_addr       => rsrc1_addr_to_IDEX1,
      rsrc2_addr       => rsrc2_addr_to_IDEX1,
      input_port       => input_port_to_IDEX1,

      -- Control inputs
      alu_src          => alu_src_to_IDEX1,
      alu_op           => alu_op_to_IDEX1,
      ccr_sel          => ccr_sel_to_IDEX1,
      modify_ccr       => modify_fl_to_IDEX1,
      branch_op        => branch_op_to_IDEX1,
      newSP_sel        => new_sp_sel_to_IDEX1,
      SP_WE            => sp_we_to_IDEX1,
      add_sel          => add_sel_to_IDEX1,
      mem_addr_sel     => mem_addr_sel_to_IDEX1,
      mem_data_sel     => mem_data_sel_to_IDEX1,
      mem_WE           => mem_we_to_IDEX1,
      mem_R            => mem_r_to_IDEX1,
      reg_data         => reg_data_to_IDEX1,
      reg_WE           => reg_we_to_IDEX1,
      ret              => ret_to_IDEX1,
      INT_state        => int_state_to_IDEX1,
      is_load          => is_load_to_IDEX1,
      swap_state       => swap_state_to_IDEX1,
      out_enable       => out_enable_to_IDEX1,
      HLT              => hlt_to_IDEX1,

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
    -- EX1 stage
    --   Forwarding-mux data sources and selects are tied off until EX1/EX2,
    --   EX2/MEM, MEM/WB registers and the Forwarding Unit are wired up.
    --   With selects "000", the rsrc1/rsrc2 paths fall through unchanged.
    ------------------------------------------------------------------------------
    u_EX1: EX1
    port map (
      -- Control passthroughs from ID/EX1 -> EX1/EX2
      HLT_in_id_ex1                   => hlt_from_IDEX1,
      HLT_out_ex1_ex2                 => hlt_from_EX1,

      out_enable_in_id_ex1            => out_enable_from_IDEX1,
      out_enable_out_ex1_ex2          => out_enable_from_EX1,

      swap_state_in_id_ex1            => swap_state_from_IDEX1,
      swap_state_out_hazard_ex1_ex2   => swap_state_from_EX1,

      is_load_in_id_ex1               => is_load_from_IDEX1,
      is_load_out_hazard_ex1_ex2      => is_load_from_EX1,

      INT_state_in_id_ex1             => int_state_from_IDEX1,
      INT_state_out_hazard_ex1_ex2    => int_state_from_EX1,

      ret_in_id_ex1                   => ret_from_IDEX1,
      ret_out_hazard_ex1_ex2          => ret_from_EX1,

      reg_WE_in_id_ex1                => reg_we_from_IDEX1,
      reg_WE_out_ex1_ex2              => reg_we_from_EX1,

      reg_data_in_id_ex1              => reg_data_from_IDEX1,
      reg_data_out_ex1_ex2            => reg_data_from_EX1,

      mem_R_in_id_ex1                 => mem_r_from_IDEX1,
      mem_R_out_ex1_ex2               => mem_r_from_EX1,

      mem_WE_in_id_ex1                => mem_we_from_IDEX1,
      mem_WE_out_ex1_ex2              => mem_we_from_EX1,

      mem_data_sel_in_id_ex1          => mem_data_sel_from_IDEX1,
      mem_data_sel_out_ex1_ex2        => mem_data_sel_from_EX1,

      mem_addr_sel_in_id_ex1          => mem_addr_sel_from_IDEX1,
      mem_addr_sel_out_ex1_ex2        => mem_addr_sel_from_EX1,

      add_sel_in_id_ex1               => add_sel_from_IDEX1,
      add_sel_out_ex1_ex2             => add_sel_from_EX1,

      SP_WE_in_id_ex1                 => sp_we_from_IDEX1,
      SP_WE_out_ex1_ex2               => sp_we_from_EX1,

      newSP_sel_in_id_ex1             => new_sp_sel_from_IDEX1,
      newSP_sel_out_ex1_ex2           => new_sp_sel_from_EX1,

      branch_op_in_id_ex1             => branch_op_from_IDEX1,
      branch_op_out_ex1_ex2           => branch_op_from_EX1,

      modify_ccr_in_id_ex1            => modify_ccr_from_IDEX1,
      modify_ccr_out_ex1_ex2          => modify_ccr_from_EX1,

      ccr_sel_in_id_ex1               => ccr_sel_from_IDEX1,
      ccr_sel_out_ex1_ex2             => ccr_sel_from_EX1,

      alu_op_in_id_ex1                => alu_op_from_IDEX1,
      alu_op_out_alu_ex1_ex2          => alu_op_from_EX1,

      alu_src_in_id_ex1               => alu_src_from_IDEX1,

      predicted_T_in_id_ex1           => predicted_t_from_IDEX1,
      predicted_T_out_ex1_ex2         => predicted_t_from_EX1,

      HW_INT_ret_in_id_ex1            => hw_int_ret_from_IDEX1,
      HW_INT_ret_out_ex1_ex2          => hw_int_ret_from_EX1,

      pc_in_id_ex1                    => pc_from_IDEX1,
      pc_out_ex1_ex2                  => pc_from_EX1,

      -- Data signals
      rsrc1_in_id_ex1                 => rsrc1_from_IDEX1,
      rsrc2_in_id_ex1                 => rsrc2_from_IDEX1,

      imm_in_id_ex1                   => imm_from_IDEX1,
      imm_out_ex1_ex2                 => imm_from_EX1,

      reg_dst_addr_in_id_ex1          => reg_dst_addr_from_IDEX1,
      reg_dst_addr_out_hazard_ex1_ex2 => reg_dst_addr_from_EX1,

      rsrc1_addr_in_id_ex1            => rsrc1_addr_from_IDEX1,
      rsrc1_addr_out_fwd              => rsrc1_addr_from_EX1,

      rsrc2_addr_in_id_ex1            => rsrc2_addr_from_IDEX1,
      rsrc2_addr_out_fwd              => rsrc2_addr_from_EX1,

      input_port_in_id_ex1            => input_port_from_IDEX1,
      input_port_out_ex1_ex2          => input_port_from_EX1,

      -- ALU outputs
      ccr_out_ex1_ex2                 => ccr_from_EX1,
      alu_result_out_ex1_ex2          => alu_result_from_EX1,

      -- Forwarding-mux data sources
      --   EX1/EX2 feedback is now wired; EX2/MEM and MEM/WB are TODO until those registers exist.
      alu_res_in_ex1_ex2              => alu_res_from_EX1EX2,
      alu_res_in_ex2_mem              => (others => '0'),
      alu_res_in_mem_wb               => (others => '0'),
      mem_data_out_in_mem_wb          => (others => '0'),
      imm_in_ex1_ex2                  => imm_from_EX1EX2,
      imm_in_ex2_mem                  => (others => '0'),
      imm_in_mem_wb                   => (others => '0'),

      -- Forwarding-mux selects (TODO from Forwarding Unit; "000" = no forward)
      rsrc1_fwd_sel_in_fwd            => (others => '0'),
      rsrc2_fwd_sel_in_fwd            => (others => '0'),

      -- Post-forwarding rsrc values to EX1/EX2
      rsrc1_out_ex1_ex2               => rsrc1_from_EX1,
      rsrc2_out_ex1_ex2               => rsrc2_from_EX1
    );

    ------------------------------------------------------------------------------
    -- EX1/EX2 pipeline register
    --   Latches all of EX1's outputs on the rising clock edge. Flush is
    --   driven from the testbench (TODO: hazard unit) and write_en is held
    --   high (TODO: hazard unit may stall this register).
    ------------------------------------------------------------------------------
    u_EX1EX2: EX1EX2
      port map (
        clk              => clk,
        flush            => tb_flush, -- TEMP from TB; TODO from hazard
        write_en         => '1',      -- TODO from hazard

        -- Data inputs (from EX1)
        predicted_T      => predicted_t_from_EX1,
        pc               => pc_from_EX1,
        HW_INT_ret       => hw_int_ret_from_EX1,
        ccr              => ccr_from_EX1,
        alu_res          => alu_result_from_EX1,
        rsrc1            => rsrc1_from_EX1,
        rsrc2            => rsrc2_from_EX1,
        imm              => imm_from_EX1,
        reg_dst_addr     => reg_dst_addr_from_EX1,
        input_port       => input_port_from_EX1,

        -- Control inputs (from EX1)
        alu_op           => alu_op_from_EX1,
        ccr_sel          => ccr_sel_from_EX1,
        modify_ccr       => modify_ccr_from_EX1,
        branch_op        => branch_op_from_EX1,
        newSP_sel        => new_sp_sel_from_EX1,
        SP_WE            => sp_we_from_EX1,
        add_sel          => add_sel_from_EX1,
        mem_addr_sel     => mem_addr_sel_from_EX1,
        mem_data_sel     => mem_data_sel_from_EX1,
        mem_WE           => mem_we_from_EX1,
        mem_R            => mem_r_from_EX1,
        reg_data         => reg_data_from_EX1,
        reg_WE           => reg_we_from_EX1,
        ret              => ret_from_EX1,
        INT_state        => int_state_from_EX1,
        is_load          => is_load_from_EX1,
        swap_state       => swap_state_from_EX1,
        out_enable       => out_enable_from_EX1,
        HLT              => hlt_from_EX1,

        -- Data outputs (to EX2; alu_res and imm also feed EX1's forwarding muxes)
        predicted_T_out  => predicted_t_from_EX1EX2,
        pc_out           => pc_from_EX1EX2,
        HW_INT_ret_out   => hw_int_ret_from_EX1EX2,
        ccr_out          => ccr_from_EX1EX2,
        alu_res_out      => alu_res_from_EX1EX2,
        rsrc1_out        => rsrc1_from_EX1EX2,
        rsrc2_out        => rsrc2_from_EX1EX2,
        imm_out          => imm_from_EX1EX2,
        reg_dst_addr_out => reg_dst_addr_from_EX1EX2,
        input_port_out   => input_port_from_EX1EX2,

        -- Control outputs (to EX2)
        alu_op_out       => alu_op_from_EX1EX2,
        ccr_sel_out      => ccr_sel_from_EX1EX2,
        modify_ccr_out   => modify_ccr_from_EX1EX2,
        branch_op_out    => branch_op_from_EX1EX2,
        newSP_sel_out    => new_sp_sel_from_EX1EX2,
        SP_WE_out        => sp_we_from_EX1EX2,
        add_sel_out      => add_sel_from_EX1EX2,
        mem_addr_sel_out => mem_addr_sel_from_EX1EX2,
        mem_data_sel_out => mem_data_sel_from_EX1EX2,
        mem_WE_out       => mem_we_from_EX1EX2,
        mem_R_out        => mem_r_from_EX1EX2,
        reg_data_out     => reg_data_from_EX1EX2,
        reg_WE_out       => reg_we_from_EX1EX2,
        ret_out          => ret_from_EX1EX2,
        INT_state_out    => int_state_from_EX1EX2,
        is_load_out      => is_load_from_EX1EX2,
        swap_state_out   => swap_state_from_EX1EX2,
        out_enable_out   => out_enable_from_EX1EX2,
        HLT_out          => hlt_from_EX1EX2
      );




    
    ------------------------------------------------------------------------------
    -- Top-level outputs
    -- Tied off until WB and HLT logic are wired in.
    ------------------------------------------------------------------------------
    output_port <= (others => '0');
    core_enable <= '0';

  end architecture;
