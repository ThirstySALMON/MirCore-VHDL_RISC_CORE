LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;  

-- Simple Incrementer Module for unsigned integers
-- Takes an N-bit input and produces the incremented result
-- Note: This does not handle overflow, so if 'a' is all 1's
-- the result will wrap around to 0.


entity incrementer is 
generic (
    N : integer := 32
);
port (
    a : in std_logic_vector(N-1 downto 0);
    result : out std_logic_vector(N-1 downto 0)
);
end incrementer;

architecture rtl of incrementer is
begin

    result <= std_logic_vector(unsigned(a) + 1);

end rtl;