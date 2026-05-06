library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity top_level is
  port (

    clk         : in  std_logic;
    rst         : in  std_logic;
    interupt    : in  std_logic;
    input_port  : in  std_logic_vector(31 downto 0);

    -- outputs
    output_port : out std_logic_vector(31 downto 0);
    core_enable : out std_logic
  );
end entity;

architecture rtl of top_level is

  -- add components here 
  -- TODO
  -- add memory 
  component memory is

    port (
      clk          : in  std_logic;
      mem_write_en : in  std_logic;
      mem_addr     : in  std_logic_vector(9 downto 0);
      mem_data_in  : in  std_logic_vector(31 downto 0);
      mem_data_out : out std_logic_vector(31 downto 0)
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

  component fetch_stage is 
    port (
        clk : in std_logic;
        rst : in std_logic;
        predicted_taken         : out std_logic;
        pc_current              : out std_logic_vector(9 downto 0);   -- current PC 
        input_port_passthrough  : out std_logic_vector(31 downto 0);
        inst_to_ifid            : out std_logic_vector(31 downto 0);
        inst_mem_addr           : out std_logic_vector(9 downto 0);   -- current PC
        branch_prediction_result : in std_logic_vector(1 downto 0);
        pc_write_en              : in std_logic;
        pc_src_sel               : in std_logic_vector(1 downto 0);
        corrected_addr_sel       : in std_logic;
        branch_target_addr       : in std_logic_vector(9 downto 0); 
        branch_fallthrough_addr  : in std_logic_vector(9 downto 0); -- PC of branch inst , add 1 to it 
        instruction_word         : in std_logic_vector(31 downto 0);
        mem_read_addr            : in std_logic_vector(31 downto 0);
        input_port               : in std_logic_vector(31 downto 0)
    );
  
  end component;


  -- add fetch , decode , ex1 , ex2 , mem and wb stages
  -- add hazard unit 
  -- add forwarding unit
  -- add interupt handler unit 
  -- -- add   decode , ex1 , ex2 , mem and wb pipeline registers 



  --Add signals here 
  signal memory_data_out : std_logic_vector (31 downto 0);
  signal memory_addr : std_logic_vector (9 downto 0);
  signal predict : std_logic; -- from fetch to IF/ID
  signal pc_crr : std_logic_vector(9 downto 0); -- from fetch to IF/ID
  signal input_out_fetch : std_logic_vector(31 downto 0);
  signal inst_out_fetch : std_logic_vector(31 downto 0);
  signal mem_addr_out_fetch : std_logic_vector (9 downto 0);


begin



  memory_addr <= mem_addr_out_fetch; -- to be changed for selection between fetch and mem/wb
    u_memory : memory
    port map (
        clk          => clk,
        mem_write_en => '0',  -- to be changed when ex1/mem 
        mem_addr     => memory_addr,
        mem_data_in  => (others => '0'),
        mem_data_out => memory_data_out
    );


    u_fetch_stage : fetch_stage
    port map(    clk => clk,
        rst =>rst,

        predicted_taken        => predict,
        pc_current             => pc_crr,
        input_port_passthrough  => input_out_fetch,
        inst_to_ifid            => inst_out_fetch,
        inst_mem_addr           => mem_addr_out_fetch,
        branch_prediction_result => (others => '0'), -- to be changd from hazard
        pc_write_en              => '1', -- to be changed from hazard
        pc_src_sel              => (others => '0'), -- from hazard
        corrected_addr_sel      => '0', -- hazard
        branch_target_addr      => (others => '0') , -- from ex1/ex2
        branch_fallthrough_addr => (others => '0') , -- from ex1/ex2
        instruction_word         => memory_data_out, 
        mem_read_addr            => (others => '0') , -- from mem/wb
        input_port               => input_port
    );


    u_IFID : IFID
    port map(
                clk  => clk,
        flush => '0', -- to be changed from hazard
        write_en => '1', -- from hazard
        predicted_T => predict,
        inst => inst_out_fetch,

        input_port => input_out_fetch,
        pc  => pc_crr, -- from fetch 
        predicted_T_out => open,-- to decode
        inst_out        => open, --to decode
        input_port_out  => open , --decode
        pc_out => open -- decode

    );




end architecture;
