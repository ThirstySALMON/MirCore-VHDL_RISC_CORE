--------------------------------------------------------------------------------
-- EX2 stage
--   Second execute stage. Performs:
--     - Memory effective-address adder ((rsrc1 or rsrc2) + Zero-extended imm),
--       result truncated to the 10-bit data-memory address space
--     - Branch decision flag for the Hazard Unit (Hazard Unit XORs against
--       predicted_T to detect mispredictions)
--     - CCR register update (Z/N/C flag mux from ccr_sel; RTI restores BCCR)
--     - BCCR snapshot of CCR on interrupt entry (INT_state = "01")
--     - Passes the rest of the control/data signals through to EX2/MEM
--   Note: RET/INT/RTI branch resolution is handled in MEM/WB, not here.
--
--   Naming convention (mirrors EX1):
--     *_in_ex1_ex2             : data driven by the EX1/EX2 register
--     *_out_ex2_mem            : data driven to the EX2/MEM register
--     *_out_hazard_ex2_mem     : driven to EX2/MEM register and Hazard Unit
--     *_out_fwd_ex2_mem        : driven to EX2/MEM register and Forwarding Unit
--     *_out_hazard_fwd_ex2_mem : driven to EX2/MEM, Hazard Unit, and Forwarding Unit
--     *_out_bccr_ex2_mem       : driven to EX2/MEM and the BCCR (branch CCR) consumer
--     *_out_branch_ex2_mem     : PC correction path (also feeds Fetch INC and ID/EX1)
--     *_out_hazard             : driven only to the Hazard Unit (not latched)
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity EX2 is
  port (

    ----------------------------------------------------------------------------
    -- Control signals from EX1/EX2 register, mostly passthrough to EX2/MEM
    ----------------------------------------------------------------------------
    clk                                 : in  std_logic;
    rst                                 : in  std_logic;

    HLT_in_ex1_ex2                      : in  std_logic;
    HLT_out_ex2_mem                     : out std_logic;

    out_enable_in_ex1_ex2               : in  std_logic;
    out_enable_out_ex2_mem              : out std_logic;

    swap_state_in_ex1_ex2               : in  std_logic_vector(1 downto 0);
    swap_state_out_hazard_fwd_ex2_mem   : out std_logic_vector(1 downto 0);

    is_load_in_ex1_ex2                  : in  std_logic;
    is_load_out_hazard_ex2_mem          : out std_logic;

    INT_state_in_ex1_ex2                : in  std_logic_vector(1 downto 0);
    INT_state_out_hazard_bccr_ex2_mem   : out std_logic_vector(1 downto 0);

    ret_in_ex1_ex2                      : in  std_logic;
    ret_out_hazard_ex2_mem              : out std_logic;

    reg_WE_in_ex1_ex2                   : in  std_logic;
    reg_WE_out_fwd_ex2_mem              : out std_logic;

    reg_data_in_ex1_ex2                 : in  std_logic_vector(2 downto 0);
    reg_data_out_ex2_mem                : out std_logic_vector(2 downto 0);

    mem_R_in_ex1_ex2                    : in  std_logic;
    mem_R_out_hazard_ex2_mem            : out std_logic;

    mem_WE_in_ex1_ex2                   : in  std_logic;
    mem_WE_out_ex2_mem                  : out std_logic;

    mem_data_sel_in_ex1_ex2             : in  std_logic_vector(1 downto 0);
    mem_data_sel_out_ex2_mem            : out std_logic_vector(1 downto 0);

    mem_addr_sel_in_ex1_ex2             : in  std_logic_vector(2 downto 0);
    mem_addr_sel_out_ex2_mem            : out std_logic_vector(2 downto 0);

    -- Memory-address adder base-register select: '0' = rsrc1, '1' = rsrc2. Stays inside EX2.
    add_sel_in_ex1_ex2                  : in  std_logic;

    SP_WE_in_ex1_ex2                    : in  std_logic;
    SP_WE_out_ex2_mem                   : out std_logic;

    newSP_sel_in_ex1_ex2                : in  std_logic;
    newSP_sel_out_ex2_mem               : out std_logic;

    -- Branch / CCR update controls (consumed locally; not forwarded)
    branch_op_in_ex1_ex2                : in  std_logic_vector(3 downto 0);
    modify_fl_in_ex1_ex2                : in  std_logic_vector(2 downto 0);
    ccr_sel_in_ex1_ex2                  : in  std_logic_vector(2 downto 0);

    alu_op_in_ex1_ex2                   : in  std_logic_vector(2 downto 0);
    alu_op_out_fwd_ex2_mem              : out std_logic_vector(2 downto 0);

    pc_in_ex1_ex2                       : in  std_logic_vector(9 downto 0);
    -- PC fans out to EX2/MEM, ID/EX1 (branch correction), and Fetch INC
    pc_out_branch_ex2_mem               : out std_logic_vector(9 downto 0);

    HW_INT_ret_in_ex1_ex2               : in  std_logic_vector(9 downto 0);
    HW_INT_ret_out_ex2_mem              : out std_logic_vector(9 downto 0);

    ----------------------------------------------------------------------------
    -- Data signals
    ----------------------------------------------------------------------------
    -- ALU flags from EX1 (consumed locally by branch decision)
    ccr_in_ex1_ex2                      : in  std_logic_vector(2 downto 0);

    -- ALU result: forwarded to EX2/MEM and used by EX1 forwarding muxes
    alu_result_in_ex1_ex2               : in  std_logic_vector(31 downto 0);
    alu_result_out_ex2_mem              : out std_logic_vector(31 downto 0);

    rsrc1_in_ex1_ex2                    : in  std_logic_vector(31 downto 0);
    rsrc1_out_ex2_mem                   : out std_logic_vector(31 downto 0);

    -- rsrc2 consumed locally (alternate base register for memory-address adder); not forwarded
    rsrc2_in_ex1_ex2                    : in  std_logic_vector(31 downto 0);

    imm_in_ex1_ex2                      : in  std_logic_vector(15 downto 0);
    imm_out_ex2_mem                     : out std_logic_vector(15 downto 0);

    reg_dst_addr_in_ex1_ex2             : in  std_logic_vector(2 downto 0);
    reg_dst_addr_out_hazard_fwd_ex2_mem : out std_logic_vector(2 downto 0);

    input_port_in_ex1_ex2               : in  std_logic_vector(31 downto 0);
    input_port_out_ex2_mem              : out std_logic_vector(31 downto 0);

    ----------------------------------------------------------------------------
    -- EX2-generated outputs
    ----------------------------------------------------------------------------
    -- Memory effective-address from the (rsrc1|rsrc2)+imm adder, low 10 bits
    add_result_out_ex2_mem              : out std_logic_vector(9 downto 0);

    -- Branch-decision flag to the Hazard Unit (1 = take branch)
    branch_decision_out_hazard          : out std_logic
  );
end entity;

architecture rtl of EX2 is

  signal ccr_str      : std_logic_vector(2 downto 0);  -- live CCR (Z/N/C)
  signal bccr_str     : std_logic_vector(2 downto 0);  -- saved CCR for RTI
  signal add_operand1 : std_logic_vector(31 downto 0); -- base register for mem-addr adder
  signal add_operand2 : std_logic_vector(31 downto 0); -- sign-extended immediate
  signal add_sum      : std_logic_vector(31 downto 0); -- full-width sum (low 10 bits drive output)

begin

  -- BCCR register 
  process (clk, rst)
  begin
    if rst = '1' then
      bccr_str <= (others => '0');
    elsif rising_edge(clk) then
      if INT_state_in_ex1_ex2 = "01" then
        bccr_str <= ccr_str;
      end if;
    end if;
  end process;

  -- CCR register
  --   Priority on the rising edge:
  --     1. INT_state = "11" (RTI)  -> restore BCCR snapshot
  --     2. ccr_sel mux              -> update flags from ALU ccr per the table below
  --     3. modify_fl override       -> force-set/reset individual flags
  --
  --   ccr_sel encoding (selects which flags update from ccr_in_ex1_ex2):
  --     "000" hold | "001" Z | "010" N | "011" C
  --     "100" Z+N  | "101" Z+C | "110" N+C | "111" Z+N+C
  --
  --   modify_fl encoding (applied after ccr_sel; overrides one bit):
  --     "001" set C   | "010" reset Z | "011" reset N | "100" reset C
  --     all other codes: NOP
  --
  --   CCR layout: [2]=C, [1]=N, [0]=Z.
  process (clk, rst)
    variable v_ccr : std_logic_vector(2 downto 0);
  begin
    if rst = '1' then
      ccr_str <= (others => '0');
    elsif rising_edge(clk) then
      if INT_state_in_ex1_ex2 = "11" then
        ccr_str <= bccr_str; -- RTI: restore saved flags
      else
        -- Step 1: regular ccr_sel mux
        case ccr_sel_in_ex1_ex2 is
          when "000" => v_ccr := ccr_str;                                                 -- hold
          when "001" => v_ccr := ccr_str(2) & ccr_str(1) & ccr_in_ex1_ex2(0);             -- Z
          when "010" => v_ccr := ccr_str(2) & ccr_in_ex1_ex2(1) & ccr_str(0);             -- N
          when "011" => v_ccr := ccr_in_ex1_ex2(2) & ccr_str(1) & ccr_str(0);             -- C
          when "100" => v_ccr := ccr_str(2) & ccr_in_ex1_ex2(1) & ccr_in_ex1_ex2(0);      -- Z + N
          when "101" => v_ccr := ccr_in_ex1_ex2(2) & ccr_str(1) & ccr_in_ex1_ex2(0);      -- Z + C
          when "110" => v_ccr := ccr_in_ex1_ex2(2) & ccr_in_ex1_ex2(1) & ccr_str(0);      -- N + C
          when "111" => v_ccr := ccr_in_ex1_ex2;                                          -- Z + N + C
          when others => v_ccr := ccr_str;
        end case;

        -- Step 2: modify_fl override (force-set/reset individual flag bits)
        case modify_fl_in_ex1_ex2 is
          when "001" => v_ccr(2) := '1';   -- set C
          when "010" => v_ccr(0) := '0';   -- reset Z
          when "011" => v_ccr(1) := '0';   -- reset N
          when "100" => v_ccr(2) := '0';   -- reset C
          when others => null;             -- NOP
        end case;

        ccr_str <= v_ccr;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- Memory effective-address adder
  --   add_sel = '0' : rsrc1 + Zero-extended imm  (LDD/STD form)
  --   add_sel = '1' : rsrc2 + Zero-extended imm  (alternate base register)
  --   Output is truncated to the 10-bit data-memory address space.
  ----------------------------------------------------------------------------
  with add_sel_in_ex1_ex2 select add_operand1 <=
    rsrc1_in_ex1_ex2    when '0',
    rsrc2_in_ex1_ex2    when '1',
    (others => '0')     when others;

  add_operand2 <= (31 downto 16 => '0') & imm_in_ex1_ex2;
  add_sum      <= std_logic_vector(unsigned(add_operand1) + unsigned(add_operand2));

  add_result_out_ex2_mem <= add_sum(9 downto 0);

  ----------------------------------------------------------------------------
  -- Branch decision (taken flag)
  --   Asserted for unconditional branches (JMP, CALL) and for conditional
  --   branches when the matching CCR flag is set. The Hazard Unit XORs this
  --   against predicted_T to detect mispredictions.
  --   RET/INT/RTI are resolved in MEM/WB, not here.
  ----------------------------------------------------------------------------
  branch_decision_out_hazard <= '1' when ((branch_op_in_ex1_ex2 = "0100" or branch_op_in_ex1_ex2 = "0101") or
                                          (branch_op_in_ex1_ex2 = "0001" and ccr_str(0) = '1') or
                                          (branch_op_in_ex1_ex2 = "0010" and ccr_str(1) = '1') or
                                          (branch_op_in_ex1_ex2 = "0011" and ccr_str(2) = '1'))
                                else '0';

  ----------------------------------------------------------------------------
  -- Passthroughs to EX2/MEM register (and Hazard / Forwarding / BCCR consumers)
  ----------------------------------------------------------------------------
  HLT_out_ex2_mem                     <= HLT_in_ex1_ex2;
  out_enable_out_ex2_mem              <= out_enable_in_ex1_ex2;
  swap_state_out_hazard_fwd_ex2_mem   <= swap_state_in_ex1_ex2;
  is_load_out_hazard_ex2_mem          <= is_load_in_ex1_ex2;
  INT_state_out_hazard_bccr_ex2_mem   <= INT_state_in_ex1_ex2;
  ret_out_hazard_ex2_mem              <= ret_in_ex1_ex2;
  reg_WE_out_fwd_ex2_mem              <= reg_WE_in_ex1_ex2;
  reg_data_out_ex2_mem                <= reg_data_in_ex1_ex2;
  mem_R_out_hazard_ex2_mem            <= mem_R_in_ex1_ex2;
  mem_WE_out_ex2_mem                  <= mem_WE_in_ex1_ex2;
  mem_data_sel_out_ex2_mem            <= mem_data_sel_in_ex1_ex2;
  mem_addr_sel_out_ex2_mem            <= mem_addr_sel_in_ex1_ex2;
  SP_WE_out_ex2_mem                   <= SP_WE_in_ex1_ex2;
  newSP_sel_out_ex2_mem               <= newSP_sel_in_ex1_ex2;
  alu_op_out_fwd_ex2_mem              <= alu_op_in_ex1_ex2;
  pc_out_branch_ex2_mem               <= pc_in_ex1_ex2;
  HW_INT_ret_out_ex2_mem              <= HW_INT_ret_in_ex1_ex2;

  alu_result_out_ex2_mem              <= alu_result_in_ex1_ex2;
  rsrc1_out_ex2_mem                   <= rsrc1_in_ex1_ex2;
  imm_out_ex2_mem                     <= imm_in_ex1_ex2;
  reg_dst_addr_out_hazard_fwd_ex2_mem <= reg_dst_addr_in_ex1_ex2;
  input_port_out_ex2_mem              <= input_port_in_ex1_ex2;

end architecture;



