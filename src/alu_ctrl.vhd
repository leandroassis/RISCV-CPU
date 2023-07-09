library ieee;
use ieee.std_logic_1164.all;

entity alu_ctrl is
    port(
        alu_op: in std_logic_vector(2 downto 0);
        instruction: in std_logic_vector(31 downto 0);
        opcode: out std_logic_vector(3 downto 0)
    );
end alu_ctrl;

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

architecture Behavioral of alu_ctrl is
    signal funct3 : std_logic_vector(2 downto 0) := (others => '0');
    signal funct7 : std_logic_vector(6 downto 0) := (others => '0');

    function logic_arith_type(func3 : std_logic_vector(2 downto 0); func7 : std_logic_vector(6 downto 0)) return std_logic_vector is
        variable opcode_temp : std_logic_vector(3 downto 0);
        begin
            if func3 = "000" then
                if func7 = "0000000" then -- add
                    opcode_temp := "0001";
                elsif func7 = "0100000" then -- sub
                    opcode_temp := "0010";
                end if;
            elsif func3 = "001" then -- sll
                opcode_temp := "0110";
            elsif func3 = "100" then -- xor
                opcode_temp := "0101";
            elsif func3 = "101" then -- srl
                opcode_temp := "0111";
            elsif func3 = "110" then -- or
                opcode_temp := "0100";
            elsif func3 = "111" then -- and
                opcode_temp := "0011";
            end if;

            return opcode_temp;
    end function;

begin

    funct3 <= instruction(14 downto 12);
    funct7 <= instruction(31 downto 25);

    op_decode: process(alu_op, funct3, funct7) is
        begin
            if alu_op = "001" or alu_op = "010" then
                opcode <= logic_arith_type(funct3, funct7);
            elsif alu_op = "011" then
                if funct3 = "000" then -- beq
                    opcode <= "1000";
                elsif funct3 = "001" then -- bne
                    opcode <= "1001";
                end if;
            elsif alu_op = "100" then
                opcode <= "0001";
            elsif alu_op = "101" then
                opcode <= "1010";
            elsif alu_op = "110" then
                opcode <= "1011";
            elsif alu_op = "111" or alu_op = "000" then
                opcode <= "0000";
            end if;
    end process op_decode;

end Behavioral;