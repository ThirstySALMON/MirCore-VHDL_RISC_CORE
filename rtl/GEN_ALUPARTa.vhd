
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;


ENTITY GEN_aluparta is
    generic(N : integer := 8);
    PORT(A , B : IN std_logic_vector(N-1 downto 0);
         cin : IN std_logic;
         sel : IN std_logic_vector(1 downto 0);
         F : OUT std_logic_vector(N-1 downto 0);
         cout : OUT std_logic
    );
    END ENTITY GEN_aluparta;


architecture structural of GEN_aluparta is
    COMPONENT my_nadder
    GENERIC (n : integer := 8);
       PORT (a, b : IN std_logic_vector(n-1 DOWNTO 0) ;
        cin : IN std_logic;
        s : OUT std_logic_vector(n-1 DOWNTO 0);
        cout : OUT std_logic);
    END COMPONENT;

    -- Helper signals
    signal not_B     : std_logic_vector(N-1 downto 0);
    signal plus_one  : std_logic_vector(N-1 downto 0) := (0 => '1', others => '0');
    signal minus_one : std_logic_vector(N-1 downto 0) := (others => '1');

    -- Operation results
    signal temp_sub, s1, s2, s3, s4, s5, s6 : std_logic_vector(N-1 downto 0);
    -- Individual carry signals
    signal c0, c1, c2, c3, c4, c5, c6 : std_logic;

Begin
    not_B <= NOT B;

    
    adder0: my_nadder GENERIC MAP(N) PORT MAP (A, not_B,     '1', temp_sub, c0); -- A-B
    adder1: my_nadder GENERIC MAP(N) PORT MAP (A, plus_one,  '0', s1,       c1); -- A+1
    adder2: my_nadder GENERIC MAP(N) PORT MAP (temp_sub, minus_one, '0', s2, c2); -- (A-B)-1
    adder3: my_nadder GENERIC MAP(N) PORT MAP (temp_sub, plus_one,  '0', s3, c3); -- (A-B)+1
    adder4: my_nadder GENERIC MAP(N) PORT MAP (A, B,         '1', s4,       c4); -- A+B+1
    adder5: my_nadder GENERIC MAP(N) PORT MAP (A, minus_one, '0', s5,       c5); -- A-1
    adder6: my_nadder GENERIC MAP(N) PORT MAP (B, plus_one,  '0', s6,       c6); -- B+1

    
    F <= A        when (sel = "00" and cin = '0') ELSE
         s1       when (sel = "00" and cin = '1') ELSE
         temp_sub when (sel = "01" and cin = '0') ELSE
         s2       when (sel = "01" and cin = '1') ELSE
         s3       when (sel = "10" and cin = '0') ELSE
         s4       when (sel = "10" and cin = '1') ELSE
         s5       when (sel = "11" and cin = '0') ELSE
         s6;    


    cout <= '0' when (sel = "00" and cin = '0') ELSE -- F=A has no carry
            c1  when (sel = "00" and cin = '1') ELSE
            c0  when (sel = "01" and cin = '0') ELSE
            c2  when (sel = "01" and cin = '1') ELSE
            c3  when (sel = "10" and cin = '0') ELSE
            c4  when (sel = "10" and cin = '1') ELSE
            c5  when (sel = "11" and cin = '0') ELSE
            c6;

END structural;
