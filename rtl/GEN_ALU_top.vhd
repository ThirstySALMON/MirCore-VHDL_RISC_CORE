       
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GEN_alu_top is
    GENERIC (N : integer := 8);
    port (
        A    : in  std_logic_vector(N-1 downto 0);
        B    : in  std_logic_vector(N-1 downto 0);
        S    : in  std_logic_vector(3 downto 0);
        cin  : in  std_logic;
        F    : out std_logic_vector(N-1 downto 0);
        cout : out std_logic
    );
end GEN_alu_top;

architecture Structural of GEN_alu_top is





    component GEN_aluparta 
    generic(N : integer := 8);
    PORT(A , B : IN std_logic_vector(N-1 downto 0);
         cin : IN std_logic;
         sel : IN std_logic_vector(1 downto 0);
         F : OUT std_logic_vector(N-1 downto 0);
         cout : OUT std_logic
    );
    END component;



  component GEN_alu_partb is
    generic( N: integer := 8);
    port (
        A   : in  std_logic_vector(N-1 downto 0);
        B   : in  std_logic_vector(N-1 downto 0);
	sel : in std_logic_vector(1 downto 0);
	cin : in std_logic;
	F   : out  std_logic_vector(N-1 downto 0);
	cout: out std_logic
    );
    end component;


    component GEN_alu_partc 
        generic (
        N : integer := 8
        );
        port (
        A: in std_logic_vector(N-1 downto 0);
        B: in std_logic_vector(N-1 downto 0);
        sel : in std_logic_vector(1 downto 0);
        cin : in std_logic;
        F: out std_logic_vector(N-1 downto 0);
        cout: out std_logic
        );
    end component;

    component GEN_alu_partd is
    generic( N : integer := 8);
     port (
        A : in std_logic_vector(N-1 downto 0);
        B : in std_logic_vector(N-1 downto 0);
        sel : in std_logic_vector(1 downto 0);
        cin : in std_logic;
        F: out std_logic_vector(N-1 downto 0);
        cout: out std_logic
     );
end component;





    
    signal F_a ,F_b, F_c, F_d : std_logic_vector(N-1 downto 0);
    signal cout_a ,cout_b, cout_c, cout_d : std_logic;

begin

    part_a: GEN_aluparta GENERIC MAP(N) port map (A => A, B => B, sel => S(1 downto 0), cin => cin,F => F_a, cout => cout_a);
    
    part_b: GEN_alu_partb GENERIC MAP(N) port map (A => A, B => B, sel => S(1 downto 0), cin => cin,F => F_b, cout => cout_b);

   
    part_c: GEN_alu_partc GENERIC MAP(N) port map (A => A,B => B, sel => S(1 downto 0), cin => cin, F => F_c, cout => cout_c);

  
    part_d: GEN_alu_partd GENERIC MAP(N) port map (A => A, B=> B, sel => S(1 downto 0), cin => cin, F => F_d, cout => cout_d);

  
    process(S,F_a, F_b, F_c, F_d, cout_a,cout_b, cout_c, cout_d)
    begin
        case S(3 downto 2) is

            when "00"=>
                F <=F_a;
                cout <= cout_a;
            when "01" =>  
                F <= F_b;
                cout <= cout_b;
            when "10" =>  
                F <= F_c;
                cout <= cout_c;
            when "11" =>  
                F <= F_d;
                cout <= cout_d;
            when others => 
                F <= (others => '0');
                cout <= '0';
        end case;
    end process;

end Structural;