--------------------------------------------------------------------------------
-- ALU Testbench (SIGNED + EDGE CASE COMPLETE)
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY alu_tb IS
END alu_tb;

ARCHITECTURE behavioral OF alu_tb IS

    SIGNAL operand1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL operand2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_op : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL alu_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_flags : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL z_flag : STD_LOGIC;
    SIGNAL n_flag : STD_LOGIC;
    SIGNAL c_flag : STD_LOGIC;

    SIGNAL test_count : INTEGER := 0;
    SIGNAL pass_count : INTEGER := 0;
    SIGNAL fail_count : INTEGER := 0;

BEGIN

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : ENTITY work.ALU
        PORT MAP(
            operand1 => operand1,
            operand2 => operand2,
            alu_op => alu_op,
            alu_result => alu_result,
            alu_flags => alu_flags
        );

    z_flag <= alu_flags(0);
    n_flag <= alu_flags(1);
    c_flag <= alu_flags(2);

    --------------------------------------------------------------------------
    -- TEST PROCESS
    --------------------------------------------------------------------------
    PROCESS

        VARIABLE L : line;

        PROCEDURE test_alu (
            op1_val : STD_LOGIC_VECTOR(31 DOWNTO 0);
            op2_val : STD_LOGIC_VECTOR(31 DOWNTO 0);
            op : STD_LOGIC_VECTOR(2 DOWNTO 0);
            exp_res : STD_LOGIC_VECTOR(31 DOWNTO 0);
            exp_z : STD_LOGIC;
            exp_n : STD_LOGIC;
            exp_c : STD_LOGIC;
            name : STRING
        ) IS
        BEGIN

            test_count <= test_count + 1;

            operand1 <= op1_val;
            operand2 <= op2_val;
            alu_op <= op;

            WAIT FOR 10 ns;

            IF (alu_result = exp_res AND
                z_flag = exp_z AND
                n_flag = exp_n AND
                c_flag = exp_c) THEN

                write(L, STRING'("[PASS] "));
                write(L, name);
                write(L, STRING'(" -> 0x"));
                hwrite(L, alu_result);
                writeline(output, L);

                pass_count <= pass_count + 1;

            ELSE

                write(L, STRING'("[FAIL] "));
                write(L, name);
                writeline(output, L);

                write(L, STRING'(" Expected: 0x"));
                hwrite(L, exp_res);
                writeline(output, L);

                write(L, STRING'(" Got:      0x"));
                hwrite(L, alu_result);
                writeline(output, L);

                fail_count <= fail_count + 1;

            END IF;

        END PROCEDURE;

    BEGIN

        ----------------------------------------------------------------------
        -- 000 NOP
        ----------------------------------------------------------------------
        test_alu(x"12345678", x"00000000", "000",
        x"00000000", '1', '0', '0', "NOP");

        ----------------------------------------------------------------------
        -- 001 NOT EDGE CASES
        ----------------------------------------------------------------------
        test_alu(x"00000000", x"00000000", "001",
        x"FFFFFFFF", '0', '1', '0', "NOT zero");

        test_alu(x"FFFFFFFF", x"00000000", "001",
        x"00000000", '1', '0', '0', "NOT all ones");

        test_alu(x"AAAAAAAA", x"00000000", "001",
        x"55555555", '0', '0', '0', "NOT pattern");

        ----------------------------------------------------------------------
        -- 010 INC EDGE CASES
        ----------------------------------------------------------------------
        test_alu(x"00000005", x"00000000", "010",
        x"00000006", '0', '0', '0', "INC normal");

        test_alu(x"FFFFFFFF", x"00000000", "010",
        x"00000000", '1', '0', '0', "INC overflow max");

        test_alu(x"7FFFFFFF", x"00000000", "010",
        x"80000000", '0', '1', '1', "INC sign overflow");

        test_alu(x"00000000", x"00000000", "010",
        x"00000001", '0', '0', '0', "INC zero");

        ----------------------------------------------------------------------
        -- 011 MOV
        ----------------------------------------------------------------------
        test_alu(x"12345678", x"00000000", "011",
        x"12345678", '0', '0', '0', "MOV");

        test_alu(x"80000000", x"00000000", "011",
        x"80000000", '0', '1', '0', "MOV negative");

        ----------------------------------------------------------------------
        -- 100 ADD EDGE CASES
        ----------------------------------------------------------------------
        test_alu(x"00000005", x"00000003", "100",
        x"00000008", '0', '0', '0', "ADD normal");

        test_alu(x"7FFFFFFF", x"7FFFFFFF", "100",
        x"FFFFFFFE", '0', '1', '1', "ADD +MAX + +MAX");

        test_alu(x"80000000", x"80000000", "100",
        x"00000000", '1', '0', '1', "ADD -MAX + -MAX");

        test_alu(x"7FFFFFFF", x"80000000", "100",
        x"FFFFFFFF", '0', '1', '0', "ADD opposite signs");

        ----------------------------------------------------------------------
        -- 101 SUB EDGE CASES
        ----------------------------------------------------------------------
        test_alu(x"0000000A", x"00000003", "101",
        x"00000007", '0', '0', '0', "SUB normal");

        test_alu(x"00000000", x"00000001", "101",
        x"FFFFFFFF", '0', '1', '0', "SUB underflow");

        test_alu(x"00000001", x"00000002", "101",
        x"FFFFFFFF", '0', '1', '0', "SUB negative result");

        test_alu(x"80000000", x"00000001", "101",
        x"7FFFFFFF", '0', '0', '1', "SUB boundary");

        test_alu(x"12345678", x"12345678", "101",
        x"00000000", '1', '0', '0', "SUB equal");

        ----------------------------------------------------------------------
        -- 110 AND EDGE CASES
        ----------------------------------------------------------------------
        test_alu(x"FFFF0000", x"0FFF0000", "110",
        x"0FFF0000", '0', '0', '0', "AND mask");

        test_alu(x"FFFFFFFF", x"00000000", "110",
        x"00000000", '1', '0', '0', "AND zero");

        test_alu(x"F0F0F0F0", x"0F0F0F0F", "110",
        x"00000000", '1', '0', '0', "AND alternating");

        ----------------------------------------------------------------------
        -- 111 PASS EDGE CASES
        ----------------------------------------------------------------------
        test_alu(x"DEADBEEF", x"00000000", "111",
        x"DEADBEEF", '0', '1', '0', "PASS random");

        test_alu(x"7FFFFFFF", x"00000000", "111",
        x"7FFFFFFF", '0', '0', '0', "PASS max");

        test_alu(x"80000000", x"00000000", "111",
        x"80000000", '0', '1', '0', "PASS min");

        ----------------------------------------------------------------------
        -- SUMMARY
        ----------------------------------------------------------------------
        WAIT FOR 10 ns;

        write(L, STRING'("============== SUMMARY =============="));
        writeline(output, L);

        write(L, STRING'("Total: "));
        write(L, test_count);
        writeline(output, L);

        write(L, STRING'("Passed: "));
        write(L, pass_count);
        writeline(output, L);

        write(L, STRING'("Failed: "));
        write(L, fail_count);
        writeline(output, L);

        WAIT;

    END PROCESS;

END behavioral;