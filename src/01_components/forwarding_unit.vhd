library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity forwarding_unit is
  port (
    -- inputs from id/ex1
    rsrc1_addr           : in  std_logic_vector(2 downto 0);
    rsrc2_addr           : in  std_logic_vector(2 downto 0);

    -- inputs from ex1/ex2
    swap_state           : in  std_logic_vector(1 downto 0);
    reg_WE_ex1_ex2       : in  std_logic;
    reg_dst_addr_ex1_ex2 : in  std_logic_vector(2 downto 0);
    reg_data_ex1_ex2     : in  std_logic_vector(2 downto 0);

    -- inputs from ex2/mem
    reg_data_ex2_mem     : in  std_logic_vector(2 downto 0);
    reg_dst_addr_ex2_mem : in  std_logic_vector(2 downto 0);
    reg_WE_ex2_mem       : in  std_logic;

    -- inputs from mem/wb
    reg_WE_mem_wb        : in  std_logic;
    reg_dst_addr_mem_wb  : in  std_logic_vector(2 downto 0);
    reg_data_mem_wb      : in  std_logic_vector(2 downto 0);

    -- outputs to ex1
    operand1_sel         : out std_logic_vector(2 downto 0);
    operand2_sel         : out std_logic_vector(2 downto 0)
  );
end entity;

architecture rtl of forwarding_unit is

begin

  process (rsrc1_addr, rsrc2_addr, swap_state, reg_WE_ex1_ex2, reg_dst_addr_ex1_ex2, reg_data_ex1_ex2, reg_WE_ex2_mem, reg_dst_addr_ex2_mem, reg_data_ex2_mem, reg_WE_mem_wb, reg_dst_addr_mem_wb, reg_data_mem_wb)
  begin
    -- default is rsrc
    operand1_sel <= (others => '0');
    operand2_sel <= (others => '0');

    -- OPERAND 1
    -- check ex1/ex2 first
    if ((reg_WE_ex1_ex2 = '1') and (reg_dst_addr_ex1_ex2 = rsrc1_addr) and (swap_state /= "01")) then
      if (reg_data_ex1_ex2 = "010") then
        operand1_sel <= "101";
      elsif (reg_data_ex1_ex2 = "011" or reg_data_ex1_ex2 = "101") then
        operand1_sel <= "001";
      end if;

      -- check ex2/mem
    elsif ((reg_WE_ex2_mem = '1') and (reg_dst_addr_ex2_mem = rsrc1_addr)) then
      if (reg_data_ex2_mem = "010") then
        operand1_sel <= "110";
      elsif (reg_data_ex2_mem = "011" or reg_data_ex2_mem = "101") then
        operand1_sel <= "010";
      end if;

      --check mem/wb
    elsif ((reg_WE_mem_wb = '1') and (reg_dst_addr_mem_wb = rsrc1_addr)) then
      if (reg_data_mem_wb = "001") then
        operand1_sel <= "100";
      elsif (reg_data_mem_wb = "010") then
        operand1_sel <= "111";
      elsif (reg_data_mem_wb = "011" or reg_data_mem_wb = "101") then
        operand1_sel <= "011";
      end if;

    end if;

    --OPERAND 2
    -- check ex1/ex2 first
    if ((reg_WE_ex1_ex2 = '1') and (reg_dst_addr_ex1_ex2 = rsrc2_addr) and (swap_state /= "01")) then
      if (reg_data_ex1_ex2 = "010") then
        operand2_sel <= "101";
      elsif (reg_data_ex1_ex2 = "011" or reg_data_ex1_ex2 = "101") then
        operand2_sel <= "001";
      end if;

      --check ex2/mem
    elsif ((reg_WE_ex2_mem = '1') and (reg_dst_addr_ex2_mem = rsrc2_addr)) then
      if (reg_data_ex2_mem = "010") then
        operand2_sel <= "110";
      elsif (reg_data_ex2_mem = "011" or reg_data_ex2_mem = "101") then
        operand2_sel <= "010";
      end if;

      --check mem/wb
    elsif ((reg_WE_mem_wb = '1') and (reg_dst_addr_mem_wb = rsrc2_addr)) then
      if (reg_data_mem_wb = "001") then
        operand2_sel <= "100";
      elsif (reg_data_mem_wb = "010") then
        operand2_sel <= "111";
      elsif (reg_data_mem_wb = "011" or reg_data_mem_wb = "101") then
        operand2_sel <= "011";
      end if;

    end if;
  end process;
end architecture;
