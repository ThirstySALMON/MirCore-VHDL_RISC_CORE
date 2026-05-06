library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch_stage is
    port (
        clk : in std_logic;
        rst : in std_logic;

        --  Outputs  IF/ID register 
        predicted_taken         : out std_logic;
        pc_current              : out std_logic_vector(9 downto 0);   -- current PC 
        input_port_passthrough  : out std_logic_vector(31 downto 0);
        inst_to_ifid            : out std_logic_vector(31 downto 0);

        -- Output  Memory (async read, responds same cycle) 
        inst_mem_addr           : out std_logic_vector(9 downto 0);   -- current PC

        -- Inputs from Hazard unit 
        branch_prediction_result : in std_logic_vector(1 downto 0);
        pc_write_en              : in std_logic;
        pc_src_sel               : in std_logic_vector(1 downto 0);
        corrected_addr_sel       : in std_logic;

        -- Inputs from EX1/EX2 register 
        branch_target_addr       : in std_logic_vector(9 downto 0); 
        branch_fallthrough_addr  : in std_logic_vector(9 downto 0); -- PC of branch inst , add 1 to it 

        --  Input from Memory (async, instruction word) 
        instruction_word         : in std_logic_vector(31 downto 0);

        --  Input from MEM/WB register 
        mem_read_addr            : in std_logic_vector(31 downto 0);

        --  External input port 
        input_port               : in std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of fetch_stage is

    
    -- PC register  holds address of instruction currently being fetched
    signal pc_reg   : std_logic_vector(9 downto 0) := (others => '0');

    -- PC+1  next sequential address (combinational)
    signal pc_plus1 : std_logic_vector(9 downto 0);

    -- PC input MUX 2 output 
    signal pc_in    : std_logic_vector(9 downto 0);

    -- Branch predictor output
    signal predicted : std_logic ;
    signal branch_predicted_addr : std_logic_vector(9 downto 0);


    --Conditional Decoder 

    signal conditional_jmp_addr : std_logic_vector(9 downto 0);

begin


    --------------------PC Inputs--------------------------------
    -- TODO PC input mux
    pc_in <= pc_plus1;   --  also add reset
    --------------------PC Logic----------------------------------
    --  PC + 1 adder (combinational) 
    pc_plus1 <= std_logic_vector(unsigned(pc_reg) + 1);

    

   
    process(clk, rst)
    begin
        if rst = '1' then
            pc_reg <= instruction_word(9 downto 0);  -- M[0] holds reset vector (e.g. 4)
        elsif rising_edge(clk) then
            if pc_write_en = '1' then
                pc_reg <= pc_in;
            end if;
        end if;
    end process;
    ----------------------- PC outputs-----------------------------
    pc_current <= pc_reg;
    inst_mem_addr <= pc_reg;

    ---------------------------------------------------------------









    --  TODO: Branch predictor logic 


    predicted <= '0';





   

    inst_to_ifid<=instruction_word;

    -- Passthrough signals

    predicted_taken        <= predicted;
    input_port_passthrough <= input_port;

end rtl;