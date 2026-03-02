library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Required for math operations


entity GEN_alu_partb is
    generic( N: integer := 8);
    port (
        A   : in  std_logic_vector(N-1 downto 0);
        B   : in  std_logic_vector(N-1 downto 0);
	sel : in std_logic_vector(1 downto 0);
	cin : in std_logic;
	F   : out  std_logic_vector(N-1 downto 0);
	cout: out std_logic
    );
end GEN_alu_partb;

architecture Behavioral of GEN_alu_partb is
begin

    cout <= '0';
    F <= A or B when sel = "00"
    else A and B when sel = "01"
    else A nor B when sel = "10"
    else not A when sel = "11"	
    else A;
end Behavioral;

