-- Test Bench for Zero Extend Module

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity zero_extend_tb is
end zero_extend_tb;

architecture behavioral of zero_extend_tb is
  
  -- Component declaration
  component zero_extend is
    port (
      imm_16bit : in std_logic_vector(15 downto 0);
      imm_32bit : out std_logic_vector(31 downto 0)
    );
  end component;
  
  -- Test signals
  signal imm_16bit : std_logic_vector(15 downto 0);
  signal imm_32bit : std_logic_vector(31 downto 0);
  
begin
  
  -- Instantiate the unit under test
  uut : zero_extend port map (
    imm_16bit => imm_16bit,
    imm_32bit => imm_32bit
  );
  
  -- Test process
  process
  begin

    -- Test 1: Small positive number
    imm_16bit <= x"00AB";  
    wait for 10 ns;
    assert imm_32bit = x"000000AB" 
      report "Test 1 FAILED: Expected 0x000000AB, got "
           
      severity error;
    report "Test 1 PASSED: 0x00AB extended to 0x000000AB";
    
    -- Test 2: Larger value
    imm_16bit <= x"ABCD";
    wait for 10 ns;
    assert imm_32bit = x"0000ABCD"
      report "Test 2 FAILED"
      severity error;
    report "Test 2 PASSED: 0xABCD extended to 0x0000ABCD";
  
    
    -- Test 4: All ones
    imm_16bit <= x"FFFF";
    wait for 10 ns;
    assert imm_32bit = x"0000FFFF"
      report "Test 4 FAILED"
      severity error;
    report "Test 4 PASSED: 0xFFFF extended to 0x0000FFFF";
    
    -- All tests passed
    report "All zero_extend tests completed successfully!";
    wait;
    
  end process;
  
end behavioral;