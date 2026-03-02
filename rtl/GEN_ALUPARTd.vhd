        

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Required for math operations


entity GEN_alu_partd is
    generic( N : integer := 8);
     port (
        A : in std_logic_vector(N-1 downto 0);
        B : in std_logic_vector(N-1 downto 0);
        sel : in std_logic_vector(1 downto 0);
        cin : in std_logic;
        F: out std_logic_vector(N-1 downto 0);
        cout: out std_logic
     );
end GEN_alu_partd;

architecture Behavioral of GEN_alu_partd is
begin
    
    cout <= A(0);

    F <= '0' & A(N-1 downto 1)          when sel = "00" 
    else A(0) & A(N-1 downto 1)         when sel = "01" 
    else cin & A(N-1 downto 1)          when sel = "10" 
    else A(N-1) & A(N-1 downto 1)        when sel = "11" 
    else A;
end Behavioral;

