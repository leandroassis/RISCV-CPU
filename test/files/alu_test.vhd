library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_test is
    port(
        status : std_logic
    );
end alu_test;

-- Operação  OPCODE  Br_aux
-- nop        0000     0
-- Soma       0001     0 
-- Sub        0010     0
-- and        0011     0
-- or         0100     0
-- xor        0101     0
-- sll        0110     0
-- srl        0111     0
-- equal      1000     1 if equal
-- ~equal     1001     1 if not equal
-- in1 + 1    1010     1
-- out = in2  1011     0
-- nop        others   0
architecture Behavioral of alu_test is

    component alu is
        port(
            in_a, in_b : in std_logic_vector(31 downto 0);
            op : in std_logic_vector(3 downto 0);
            out_r : out std_logic_vector(31 downto 0);
            aux_br : out std_logic
        );
    end component;

    signal a, b, result : std_logic_vector(31 downto 0);
    signal opcode : std_logic_vector(3 downto 0);
    signal branch : std_logic;

    begin

    oper : alu port map(a, b, opcode, result, branch);

    process
    begin
        branch <= '0';
        a <= "00000000000000000000000000000101";
        b <= "00000000000000000000000000000010";
        opcode <= "1000";
        wait for 10 ns;
    end process;
end Behavioral;