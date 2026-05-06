library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity decode_stage is
  port (
    clk             : in  STD_LOGIC;
    rst             : in  STD_LOGIC;

    -- Inputs from IF/ID register
    predicted_t     : in  STD_LOGIC;
    pc              : in  STD_LOGIC_VECTOR(9 downto 0);
    inst            : in  STD_LOGIC_VECTOR(31 downto 0);
    input_port_in   : in  STD_LOGIC_VECTOR(31 downto 0);

    -- Inputs from Hazard Unit
    instruction_sel : in  STD_LOGIC_VECTOR(2 downto 0);
    rsrc1_sel       : in  STD_LOGIC;
    rdst_sel        : in  STD_LOGIC;

    -- Inputs from MEM/WB register
    reg_we          : in  STD_LOGIC;
    reg_data_sel    : in  STD_LOGIC_VECTOR(2 downto 0);
    reg_wb_addr     : in  STD_LOGIC_VECTOR(2 downto 0);
    mem_data_out    : in  STD_LOGIC_VECTOR(31 downto 0);
    imm_wb          : in  STD_LOGIC_VECTOR(15 downto 0);
    alu_res_wb      : in  STD_LOGIC_VECTOR(31 downto 0);
    input_port_wb   : in  STD_LOGIC_VECTOR(31 downto 0);
    rsrc1_wb        : in  STD_LOGIC_VECTOR(31 downto 0);

    -- Inputs from EX1/EX2 register
    hw_int_ret_ex1      : in STD_LOGIC_VECTOR(9 downto 0);

    -- Outputs to ID/EX1 register
    predicted_t_out : out STD_LOGIC;
    hw_int_ret      : out STD_LOGIC_VECTOR(9 downto 0);
    pc_out          : out STD_LOGIC_VECTOR(9 downto 0);
    rsrc1           : out STD_LOGIC_VECTOR(31 downto 0);
    rsrc2           : out STD_LOGIC_VECTOR(31 downto 0);
    imm             : out STD_LOGIC_VECTOR(15 downto 0);
    reg_dst_addr    : out STD_LOGIC_VECTOR(2 downto 0);
    rsrc1_addr      : out STD_LOGIC_VECTOR(2 downto 0);
    rsrc2_addr      : out STD_LOGIC_VECTOR(2 downto 0);
    input_port_out  : out STD_LOGIC_VECTOR(31 downto 0);
    hlt             : out STD_LOGIC;
    out_enable      : out STD_LOGIC;
    swap_state      : out STD_LOGIC_VECTOR(1 downto 0);
    is_load         : out STD_LOGIC;
    int_state       : out STD_LOGIC_VECTOR(1 downto 0);
    ret             : out STD_LOGIC;
    reg_we_out      : out STD_LOGIC;
    reg_data_out    : out STD_LOGIC_VECTOR(2 downto 0);
    mem_r           : out STD_LOGIC;
    mem_we          : out STD_LOGIC;
    mem_data_sel    : out STD_LOGIC_VECTOR(1 downto 0);
    mem_addr_sel    : out STD_LOGIC_VECTOR(2 downto 0);
    add_sel         : out STD_LOGIC;
    sp_we           : out STD_LOGIC;
    new_sp_sel      : out STD_LOGIC;
    branch_op       : out STD_LOGIC_VECTOR(3 downto 0);
    modify_fl       : out STD_LOGIC_VECTOR(2 downto 0);
    ccr_sel         : out STD_LOGIC_VECTOR(2 downto 0);
    alu_op          : out STD_LOGIC_VECTOR(2 downto 0);
    alu_src         : out STD_LOGIC;

    -- Outputs to Hazard Unit
    int_state_hz    : out STD_LOGIC_VECTOR(1 downto 0);
    swap_state_hz   : out STD_LOGIC_VECTOR(1 downto 0)
  );
end entity;

architecture rtl of decode_stage is

  -- Bundle of all control_unit outputs so we can mux them with one assignment
  type ctrl_t is record
    alu_src         : STD_LOGIC;
    alu_op          : STD_LOGIC_VECTOR(2 downto 0);
    ccr_sel         : STD_LOGIC_VECTOR(2 downto 0);
    mod_fl          : STD_LOGIC_VECTOR(2 downto 0);
    branch_op       : STD_LOGIC_VECTOR(3 downto 0);
    newSP_sel       : STD_LOGIC;
    SP_WE           : STD_LOGIC;
    add_sel         : STD_LOGIC;
    mem_addr_sel    : STD_LOGIC_VECTOR(2 downto 0);
    mem_data_sel    : STD_LOGIC_VECTOR(1 downto 0);
    mem_we          : STD_LOGIC;
    mem_r           : STD_LOGIC;
    reg_data        : STD_LOGIC_VECTOR(2 downto 0);
    reg_we          : STD_LOGIC;
    ret             : STD_LOGIC;
    int_state       : STD_LOGIC_VECTOR(1 downto 0);
    is_load         : STD_LOGIC;
    swap_state      : STD_LOGIC_VECTOR(1 downto 0);
    swap_reg_enable : STD_LOGIC;
    hlt             : STD_LOGIC;
    out_enable      : STD_LOGIC;
  end record;

  -- All-zero / NOP control bundle. Used as base for inject constants.
  constant CTRL_NOP : ctrl_t := (
    alu_src         => '0',
    alu_op          => "000",
    ccr_sel         => "000",
    mod_fl          => "000",
    branch_op       => "0000",
    newSP_sel       => '0',
    SP_WE           => '0',
    add_sel         => '0',
    mem_addr_sel    => "000",
    mem_data_sel    => "00",
    mem_we          => '0',
    mem_r           => '0',
    reg_data        => "000",
    reg_we          => '0',
    ret             => '0',
    int_state       => "00",
    is_load         => '0',
    swap_state      => "00",
    swap_reg_enable => '0',
    hlt             => '0',
    out_enable      => '0'
  );

  -- TODO add ldd[2]
    constant CTRL_INJ_2 : ctrl_t := (
    alu_src         => '0',
    alu_op          => "000",
    ccr_sel         => "000",
    mod_fl          => "000",
    branch_op       => "0000",
    newSP_sel       => '0',
    SP_WE           => '0',
    add_sel         => '0',
    mem_addr_sel    => "000",
    mem_data_sel    => "00",
    mem_we          => '0',
    mem_r           => '0',
    reg_data        => "000",
    reg_we          => '0',
    ret             => '0',
    int_state       => "00",
    is_load         => '0',
    swap_state      => "00",
    swap_reg_enable => '0',
    hlt             => '0',
    out_enable      => '0'
  );

    -- TODO add ldd[3]
constant CTRL_INJ_3 : ctrl_t := (
    alu_src         => '0',
    alu_op          => "000",
    ccr_sel         => "000",
    mod_fl          => "000",
    branch_op       => "0000",
    newSP_sel       => '0',
    SP_WE           => '0',
    add_sel         => '0',
    mem_addr_sel    => "000",
    mem_data_sel    => "00",
    mem_we          => '0',
    mem_r           => '0',
    reg_data        => "000",
    reg_we          => '0',
    ret             => '0',
    int_state       => "00",
    is_load         => '0',
    swap_state      => "00",
    swap_reg_enable => '0',
    hlt             => '0',
    out_enable      => '0'
  );

  -- todo add swap b
  constant CTRL_INJ_4 : ctrl_t := (
    alu_src         => '0',
    alu_op          => "000",
    ccr_sel         => "000",
    mod_fl          => "000",
    branch_op       => "0000",
    newSP_sel       => '0',
    SP_WE           => '0',
    add_sel         => '0',
    mem_addr_sel    => "000",
    mem_data_sel    => "00",
    mem_we          => '0',
    mem_r           => '0',
    reg_data        => "000",
    reg_we          => '0',
    ret             => '0',
    int_state       => "00",
    is_load         => '0',
    swap_state      => "00",
    swap_reg_enable => '0',
    hlt             => '0',
    out_enable      => '0'
  );

    -- TODO add ldd[0]
  constant CTRL_INJ_5 : ctrl_t := (
    alu_src         => '0',
    alu_op          => "000",
    ccr_sel         => "000",
    mod_fl          => "000",
    branch_op       => "0000",
    newSP_sel       => '0',
    SP_WE           => '0',
    add_sel         => '0',
    mem_addr_sel    => "000",
    mem_data_sel    => "00",
    mem_we          => '0',
    mem_r           => '0',
    reg_data        => "000",
    reg_we          => '0',
    ret             => '0',
    int_state       => "00",
    is_load         => '0',
    swap_state      => "00",
    swap_reg_enable => '0',
    hlt             => '0',
    out_enable      => '0'
  );




  signal cu_isr_vect : ctrl_t;
  -- Raw output of control_unit, before instruction_sel mux
  signal cu_raw : ctrl_t;
  -- Final control bundle after mux, drives the entity outputs
  signal cu_out : ctrl_t;

  -- component delcaration
  component register_file is
    port (
      clk            : in  STD_LOGIC;
      rst            : in  STD_LOGIC;
      reg_write_en   : in  STD_LOGIC;
      reg_write_addr : in  STD_LOGIC_VECTOR(2 downto 0);
      reg_write_data : in  STD_LOGIC_VECTOR(31 downto 0);
      reg_read_addr1 : in  STD_LOGIC_VECTOR(2 downto 0);
      reg_read_addr2 : in  STD_LOGIC_VECTOR(2 downto 0);
      reg_read_data1 : out STD_LOGIC_VECTOR(31 downto 0);
      reg_read_data2 : out STD_LOGIC_VECTOR(31 downto 0)
    );
  end component;

  component sign_extend is
    port (
      imm_16bit : in  STD_LOGIC_VECTOR(15 downto 0);
      imm_32bit : out STD_LOGIC_VECTOR(31 downto 0)
    );
  end component;

  component control_unit is
    port (
      opcode          : in  STD_LOGIC_VECTOR(4 downto 0);

      alu_src         : out STD_LOGIC;
      alu_op          : out STD_LOGIC_VECTOR(2 downto 0);
      ccr_sel         : out STD_LOGIC_VECTOR(2 downto 0);
      mod_fl          : out STD_LOGIC_VECTOR(2 downto 0);
      branch_op       : out STD_LOGIC_VECTOR(3 downto 0);

      newSP_sel       : out STD_LOGIC;
      SP_WE           : out STD_LOGIC;
      add_sel         : out STD_LOGIC;

      mem_addr_sel    : out STD_LOGIC_VECTOR(2 downto 0);
      mem_data_sel    : out STD_LOGIC_VECTOR(1 downto 0);
      mem_we          : out STD_LOGIC;
      mem_r           : out STD_LOGIC;

      reg_data        : out STD_LOGIC_VECTOR(2 downto 0);
      reg_we          : out STD_LOGIC;

      ret             : out STD_LOGIC;
      int_state       : out STD_LOGIC_VECTOR(1 downto 0);

      is_load         : out STD_LOGIC;
      swap_state      : out STD_LOGIC_VECTOR(1 downto 0);
      swap_reg_enable : out STD_LOGIC;

      hlt             : out STD_LOGIC;
      out_enable      : out STD_LOGIC
    );
  end component;

  signal wb_write_data       : STD_LOGIC_VECTOR(31 downto 0);
  signal imm_wb_sext         : STD_LOGIC_VECTOR(31 downto 0);
  signal swap1               : STD_LOGIC_VECTOR(2 downto 0);
  signal swap2               : STD_LOGIC_VECTOR(2 downto 0);
  signal selected_rsrc1_addr : std_logic_vector(2 downto 0);
  signal selected_rdst_addr  : std_logic_vector(2 downto 0);

begin

  -- swap 1 and swap 2 registers 
  process (clk, rst)
  begin
    if rst = '1' then
      swap1 <= (others => '0');
      swap2 <= (others => '0');
    elsif rising_edge(clk) then
      if cu_out.swap_reg_enable = '1' then
        swap1 <= inst(23 downto 21); -- rsrc1 addr
        swap2 <= inst(26 downto 24); -- rdst addr
      end if;
    end if;
  end process;

  -- rsrc 1 selector
  with rsrc1_sel select selected_rsrc1_addr <=
    inst(23 downto 21) when '0',
    swap1              when '1',
    (others => '0')    when others;

  -- rdst selector
  with rdst_sel select selected_rdst_addr <=
    inst(26 downto 24) when '0',
    swap2              when '1',
    (others => '0')    when others;

  u_sign_extend: sign_extend
    port map (
      imm_16bit => imm_wb,
      imm_32bit => imm_wb_sext
    );

  u_reg_file: register_file
    port map (
      clk            => clk,
      rst            => rst,
      reg_write_en   => reg_we,
      reg_write_addr => reg_wb_addr,
      reg_write_data => wb_write_data,
      reg_read_addr1 => selected_rsrc1_addr,
      reg_read_addr2 => inst(20 downto 18),
      reg_read_data1 => rsrc1,
      reg_read_data2 => rsrc2
    );

  u_control_unit: control_unit
    port map (
      opcode          => inst(31 downto 27),
      alu_src         => cu_raw.alu_src,
      alu_op          => cu_raw.alu_op,
      ccr_sel         => cu_raw.ccr_sel,
      mod_fl          => cu_raw.mod_fl,
      branch_op       => cu_raw.branch_op,
      newSP_sel       => cu_raw.newSP_sel,
      SP_WE           => cu_raw.SP_WE,
      add_sel         => cu_raw.add_sel,
      mem_addr_sel    => cu_raw.mem_addr_sel,
      mem_data_sel    => cu_raw.mem_data_sel,
      mem_we          => cu_raw.mem_we,
      mem_r           => cu_raw.mem_r,
      reg_data        => cu_raw.reg_data,
      reg_we          => cu_raw.reg_we,
      ret             => cu_raw.ret,
      int_state       => cu_raw.int_state,
      is_load         => cu_raw.is_load,
      swap_state      => cu_raw.swap_state,
      swap_reg_enable => cu_raw.swap_reg_enable,
      hlt             => cu_raw.hlt,
      out_enable      => cu_raw.out_enable
    );

  -- One mux for the entire control bundle. Edit the inject constants above
  -- to change what each instruction_sel value injects.

  with inst(0) select cu_isr_vect <=
        CTRL_INJ_2 when '0',
        CTRL_INJ_3 when '1',
        CTRL_NOP when others;



  with instruction_sel select cu_out <=
    cu_raw     when "000",
    CTRL_NOP   when "001",
    cu_isr_vect when "010",
    CTRL_INJ_4 when "011",
    CTRL_INJ_5 when "100",
    CTRL_NOP   when others;

  -- Fan record fields out to entity ports
  alu_src         <= cu_out.alu_src;
  alu_op          <= cu_out.alu_op;
  ccr_sel         <= cu_out.ccr_sel;
  modify_fl       <= cu_out.mod_fl;
  branch_op       <= cu_out.branch_op;
  new_sp_sel      <= cu_out.newSP_sel;
  sp_we           <= cu_out.SP_WE;
  add_sel         <= cu_out.add_sel;
  mem_addr_sel    <= cu_out.mem_addr_sel;
  mem_data_sel    <= cu_out.mem_data_sel;
  mem_we          <= cu_out.mem_we;
  mem_r           <= cu_out.mem_r;
  reg_data_out    <= cu_out.reg_data;
  reg_we_out      <= cu_out.reg_we;
  ret             <= cu_out.ret;
  int_state       <= cu_out.int_state;
  is_load         <= cu_out.is_load;
  swap_state      <= cu_out.swap_state;
  hlt             <= cu_out.hlt;
  out_enable      <= cu_out.out_enable;

  with reg_data_sel select wb_write_data <=
    mem_data_out        when "001",
    imm_wb_sext         when "010",
    alu_res_wb          when "011",
    input_port_wb       when "100",
    rsrc1_wb            when "101",
        (others => '0') when others;

  rsrc1_addr      <= selected_rsrc1_addr;
  rsrc2_addr      <= inst(20 downto 18);
  reg_dst_addr    <= selected_rdst_addr;
  imm             <= inst(15 downto 0);
  pc_out          <= pc;
  predicted_t_out <= predicted_t;
  input_port_out  <= input_port_in;
  hw_int_ret      <= hw_int_ret_ex1;
  int_state_hz    <= cu_out.int_state;
  swap_state_hz   <= cu_out.swap_state;

end architecture;
