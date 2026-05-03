LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY control_unit IS
    PORT (
        opcode : IN STD_LOGIC_VECTOR(4 DOWNTO 0);

        alu_src : OUT STD_LOGIC;
        alu_op : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        ccr_sel : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        mod_fl : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        branch_op : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

        newSP_sel : OUT STD_LOGIC;
        SP_WE : OUT STD_LOGIC;
        add_sel : OUT STD_LOGIC;

        mem_addr_sel : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_data_sel : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        mem_we : OUT STD_LOGIC;
        mem_r : OUT STD_LOGIC;

        reg_data : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        reg_we : OUT STD_LOGIC;

        ret : OUT STD_LOGIC;
        int_state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        is_load : OUT STD_LOGIC;
        swap_state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        swap_reg_enable : OUT STD_LOGIC;

        hlt : OUT STD_LOGIC;
        out_enable : OUT STD_LOGIC
    );
END control_unit;

ARCHITECTURE behavioral OF control_unit IS
BEGIN

    PROCESS (opcode)
    BEGIN

        -- DEFAULTS (prevent latches)
        alu_src <= '0';
        alu_op <= "000";
        ccr_sel <= "000";
        mod_fl <= "000";
        branch_op <= "0000";

        newSP_sel <= '0';
        SP_WE <= '0';
        add_sel <= '0';

        mem_addr_sel <= "000";
        mem_data_sel <= "00";
        mem_we <= '0';
        mem_r <= '0';

        reg_data <= "000";
        reg_we <= '0';

        ret <= '0';
        int_state <= "00";

        is_load <= '0';
        swap_state <= "00";
        swap_reg_enable <= '0';

        hlt <= '0';
        out_enable <= '0';

        ------------------------------------------------------------------------
        -- OPCODE DECODING
        ------------------------------------------------------------------------
        CASE opcode IS

                -- NOP
            WHEN "00000" =>
                NULL;

                -- HLT
            WHEN "00001" =>
                hlt <= '1';

                -- SETC
            WHEN "00010" =>
                mod_fl <= "001";

                -- NOT
            WHEN "00011" =>
                alu_op <= "001";
                ccr_sel <= "100";
                reg_data <= "011";
                reg_we <= '1';

                -- INC
            WHEN "00100" =>
                alu_op <= "010";
                ccr_sel <= "111";
                reg_data <= "011";
                reg_we <= '1';

                -- OUT
            WHEN "00101" =>
                out_enable <= '1';

                -- IN
            WHEN "00110" =>
                reg_data <= "100";
                reg_we <= '1';

                -- MOV
            WHEN "00111" =>
                alu_op <= "111";
                reg_data <= "101";
                reg_we <= '1';

                -- SWAP
            WHEN "01000" =>
                alu_op <= "111";
                reg_data <= "101";
                reg_we <= '1'; 
                swap_state <= "01";
                swap_reg_enable <= '1';

                -- ADD
            WHEN "01001" =>
                alu_op <= "100";
                ccr_sel <= "111";
                reg_data <= "011";
                reg_we <= '1';

                -- SUB
            WHEN "01010" =>
                alu_op <= "101";
                ccr_sel <= "111";
                reg_data <= "011";
                reg_we <= '1';

                -- AND
            WHEN "01011" =>
                alu_op <= "110";
                ccr_sel <= "100";
                reg_data <= "011";
                reg_we <= '1';

                -- IADD
            WHEN "01100" =>
                alu_src <= '1';
                alu_op <= "100";
                ccr_sel <= "111";
                reg_data <= "011";
                reg_we <= '1';

                -- PUSH
            WHEN "01101" =>
                newSP_sel <= '1';
                SP_WE <= '1';
                mem_addr_sel <= "010";
                mem_data_sel <= "01";
                mem_we <= '1';

                -- POP
            WHEN "01110" =>
                SP_WE <= '1';
                mem_addr_sel <= "011";
                mem_r <= '1';
                reg_data <= "001";
                reg_we <= '1';

                -- LDM
            WHEN "01111" =>
                reg_data <= "010";
                reg_we <= '1';
                is_load <= '1';

                -- LDD
            WHEN "10000" =>
                mem_addr_sel <= "001";
                mem_r <= '1';
                reg_data <= "001";
                reg_we <= '1';
                is_load <= '1';

                -- STD
            WHEN "10001" =>
                add_sel <= '1';
                mem_addr_sel <= "001";
                mem_data_sel <= "01";
                mem_we <= '1';

                -- JZ
            WHEN "10010" =>
                mod_fl <= "010";
                branch_op <= "0001";

                -- JN
            WHEN "10011" =>
                mod_fl <= "011";
                branch_op <= "0010";

                -- JC
            WHEN "10100" =>
                mod_fl <= "100";
                branch_op <= "0011";

                -- JMP
            WHEN "10101" =>
                branch_op <= "0100";

                -- CALL
            WHEN "10110" =>
                branch_op <= "0101";
                newSP_sel <= '1';
                SP_WE <= '1';
                mem_addr_sel <= "010";
                mem_data_sel <= "10";
                mem_we <= '1';

                -- RET
            WHEN "10111" =>
                branch_op <= "0110";
                SP_WE <= '1';
                mem_addr_sel <= "011";
                mem_r <= '1';
                ret <= '1';

                -- INT
            WHEN "11000" =>
                branch_op <= "0111";
                newSP_sel <= '1';
                SP_WE <= '1';
                mem_addr_sel <= "010";
                mem_data_sel <= "10";
                mem_we <= '1';
                int_state <= "01";

                -- RTI
            WHEN "11001" =>
                ccr_sel <= "111";
                branch_op <= "1000";
                SP_WE <= '1';
                mem_addr_sel <= "011";
                mem_r <= '1';
                ret <= '1';
                int_state <= "11";

            WHEN OTHERS =>
                NULL;

        END CASE;

    END PROCESS;

END behavioral;