--------------------------------------------------------------------------------
-- EX1 stage
--   First execute stage. Performs:
--     - ALU operand forwarding mux for rsrc1 and rsrc2/imm (operand B)
--     - Sign-extension of the 16-bit immediate (local and forwarded)
--     - ALU operand-B source mux: forwarded rsrc2 vs. sign-extended immediate
--     - ALU operation via u_alu instance
--     - Passes all unused control signals through to EX1/EX2 register
--
--   Forwarding-mux select encoding (rsrc1_fwd_sel / rsrc2_fwd_sel):
--     "000" : no forward  -- use register-file value from ID/EX1
--     "001" : EX1/EX2     -- ALU result one cycle ahead
--     "010" : EX2/MEM     -- ALU result two cycles ahead
--     "011" : MEM/WB      -- ALU result three cycles ahead
--     "100" : MEM/WB      -- memory read data (LDM load result)
--     "101" : EX1/EX2     -- sign-extended immediate (LDM imm forwarded, one cycle ahead)
--     "110" : EX2/MEM     -- sign-extended immediate (LDM imm forwarded, two cycles ahead)
--     "111" : MEM/WB      -- sign-extended immediate (LDM imm forwarded, three cycles ahead)
--
--   Naming convention:
--     *_in_id_ex1            : data driven by the ID/EX1 register
--     *_out_ex1_ex2          : data driven to the EX1/EX2 register
--     *_out_hazard_ex1_ex2   : driven to both EX1/EX2 register and Hazard Unit
--     *_out_alu_ex1_ex2      : ALU input that is also forwarded to EX1/EX2
--     *_out_se_ex1_ex2       : sign-extender output forwarded to EX1/EX2
--     *_out_fwd              : driven to the Forwarding Unit
--     *_in_ex1_ex2 / _ex2_mem / _mem_wb : forwarding-mux source data
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity EX1 is
  port (

    ----------------------------------------------------------------------------
    -- Control signals from ID/EX1 register, mostly passthrough to EX1/EX2
    ----------------------------------------------------------------------------
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
    imm_out_ex1_ex2              : out std_logic_vector(15 downto 0); -- carries raw imm, despite _se_ in name

    -- Destination and source register addresses
    reg_dst_addr_in_id_ex1          : in  std_logic_vector(2 downto 0);
    reg_dst_addr_out_hazard_ex1_ex2 : out std_logic_vector(2 downto 0);

    rsrc1_addr_in_id_ex1            : in  std_logic_vector(2 downto 0);
    rsrc1_addr_out_fwd              : out std_logic_vector(2 downto 0); -- to Forwarding Unit

    rsrc2_addr_in_id_ex1            : in  std_logic_vector(2 downto 0);
    rsrc2_addr_out_fwd              : out std_logic_vector(2 downto 0); -- to Forwarding Unit

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
end entity;

architecture rtl of EX1 is

  component alu is

    port (
      operand1   : in  STD_LOGIC_VECTOR(31 downto 0);
      operand2   : in  STD_LOGIC_VECTOR(31 downto 0);
      alu_op     : in  STD_LOGIC_VECTOR(2 downto 0);
      alu_result : out STD_LOGIC_VECTOR(31 downto 0);
      alu_flags  : out STD_LOGIC_VECTOR(2 downto 0) -- [2]=C, [1]=N, [0]=Z
    );
  end component;

  --Signals--
  signal alu_input1 : std_logic_vector(31 downto 0);
  signal alu_input2 : std_logic_vector(31 downto 0);

  -- rsrc2 after forwarding mux, before operand-B source mux
  signal alu_input2_mid : std_logic_vector(31 downto 0);

  -- Sign-extended immediates (16 -> 32 bit, bit 15 replicated into [31:16])
  signal se_imm_local      : std_logic_vector(31 downto 0); -- from ID/EX1
  signal se_imm_in_ex1_ex2 : std_logic_vector(31 downto 0);
  signal se_imm_in_ex2_mem : std_logic_vector(31 downto 0);
  signal se_imm_in_mem_wb  : std_logic_vector(31 downto 0);

begin

  -- Sign-extend all immediate sources inline (no component needed)
  se_imm_local      <= (31 downto 16 => imm_in_id_ex1(15)) & imm_in_id_ex1;
  se_imm_in_ex1_ex2 <= (31 downto 16 => imm_in_ex1_ex2(15)) & imm_in_ex1_ex2;
  se_imm_in_ex2_mem <= (31 downto 16 => imm_in_ex2_mem(15)) & imm_in_ex2_mem;
  se_imm_in_mem_wb  <= (31 downto 16 => imm_in_mem_wb(15)) & imm_in_mem_wb;

  -- Forwarding mux: ALU operand A (rsrc1)
  --   sel "000" = no hazard, use register-file value
  --   sel "001"-"011" = forward ALU result from EX1/EX2, EX2/MEM, MEM/WB
  --   sel "100" = forward memory read data (LDM load result) from MEM/WB
  --   sel "101"-"111" = forward sign-extended LDM immediate from EX1/EX2, EX2/MEM, MEM/WB
  with rsrc1_fwd_sel_in_fwd select alu_input1 <=
    rsrc1_in_id_ex1        when "000",
    alu_res_in_ex1_ex2     when "001",
    alu_res_in_ex2_mem     when "010",
    alu_res_in_mem_wb      when "011",
    mem_data_out_in_mem_wb when "100",
    se_imm_in_ex1_ex2      when "101",
    se_imm_in_ex2_mem      when "110",
    se_imm_in_mem_wb       when "111",
        (others => '0')    when others;

  -- Forwarding mux: ALU operand B (rsrc2 path, before alu_src mux)
  --   sel "000"-"100" = same encoding as rsrc1 mux (register / ALU result / load)
  --   sel "101"-"111" = forward sign-extended LDM immediate from EX1/EX2, EX2/MEM, MEM/WB
  --                     (the Forwarding Unit picks this when the producing instruction was LDM)
  with rsrc2_fwd_sel_in_fwd select alu_input2_mid <=
    rsrc2_in_id_ex1        when "000",
    alu_res_in_ex1_ex2     when "001",
    alu_res_in_ex2_mem     when "010",
    alu_res_in_mem_wb      when "011",
    mem_data_out_in_mem_wb when "100",
    se_imm_in_ex1_ex2      when "101",
    se_imm_in_ex2_mem      when "110",
    se_imm_in_mem_wb       when "111",
        (others => '0')    when others;

  -- Operand-B source mux: register/forwarded path vs. local sign-extended immediate
  alu_input2 <= se_imm_local when alu_src_in_id_ex1 = '1' else alu_input2_mid;

--ALU instantiation (alu_input1, alu_input2, alu_op_in_id_ex1 -> alu_result_out_ex1_ex2, ccr_out_ex1_ex2)
  u_alu: alu
    port map (
      operand1   => alu_input1,
      operand2   => alu_input2,
      alu_op     => alu_op_in_id_ex1,
      alu_result => alu_result_out_ex1_ex2,
      alu_flags  => ccr_out_ex1_ex2
    );

  ----------------------------------------------------------------------------
  -- Passthroughs and signal drivers
  ----------------------------------------------------------------------------

  -- Control signals: combinational passthrough to EX1/EX2 register
  HLT_out_ex1_ex2                 <= HLT_in_id_ex1;
  out_enable_out_ex1_ex2          <= out_enable_in_id_ex1;
  swap_state_out_hazard_ex1_ex2   <= swap_state_in_id_ex1;
  is_load_out_hazard_ex1_ex2      <= is_load_in_id_ex1;
  INT_state_out_hazard_ex1_ex2    <= INT_state_in_id_ex1;
  ret_out_hazard_ex1_ex2          <= ret_in_id_ex1;
  reg_WE_out_ex1_ex2              <= reg_WE_in_id_ex1;
  reg_data_out_ex1_ex2            <= reg_data_in_id_ex1;
  mem_R_out_ex1_ex2               <= mem_R_in_id_ex1;
  mem_WE_out_ex1_ex2              <= mem_WE_in_id_ex1;
  mem_data_sel_out_ex1_ex2        <= mem_data_sel_in_id_ex1;
  mem_addr_sel_out_ex1_ex2        <= mem_addr_sel_in_id_ex1;
  add_sel_out_ex1_ex2             <= add_sel_in_id_ex1;
  SP_WE_out_ex1_ex2               <= SP_WE_in_id_ex1;
  newSP_sel_out_ex1_ex2           <= newSP_sel_in_id_ex1;
  branch_op_out_ex1_ex2           <= branch_op_in_id_ex1;
  modify_ccr_out_ex1_ex2          <= modify_ccr_in_id_ex1;
  ccr_sel_out_ex1_ex2             <= ccr_sel_in_id_ex1;
  alu_op_out_alu_ex1_ex2          <= alu_op_in_id_ex1;
  predicted_T_out_ex1_ex2         <= predicted_T_in_id_ex1;
  HW_INT_ret_out_ex1_ex2          <= HW_INT_ret_in_id_ex1;
  pc_out_ex1_ex2                  <= pc_in_id_ex1;

  -- Data passthroughs
  imm_out_ex1_ex2              <= imm_in_id_ex1;       -- raw 16-bit imm (SE happens downstream/locally)
  input_port_out_ex1_ex2          <= input_port_in_id_ex1;

  -- Register addresses
  reg_dst_addr_out_hazard_ex1_ex2 <= reg_dst_addr_in_id_ex1;
  rsrc1_addr_out_fwd              <= rsrc1_addr_in_id_ex1; -- to Forwarding Unit
  rsrc2_addr_out_fwd              <= rsrc2_addr_in_id_ex1; -- to Forwarding Unit

  -- Post-forwarding rsrc values (after fwd mux, before operand-B src mux for rsrc2)
  rsrc1_out_ex1_ex2               <= alu_input1;
  rsrc2_out_ex1_ex2               <= alu_input2_mid;

end architecture;
