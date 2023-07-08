library ieee;
use ieee.std_logic_1164.all;

entity alu_ctrl is
    port(
        alu_op: in std_logic_vector(2 downto 0);
        instruction: in std_logic_vector(31 downto 0);
        alu_ctrl: out std_logic_vector(3 downto 0)
    );
end entity;

-- Operação  OPCODE  Br_aux
-- nop        0000     0
-- Soma       0001     0 
-- Sub        0010     0
-- and        0011     0
-- or         0100     0
-- xor        0101     0
-- slt        0110     0
-- srl        0111     0
-- equal      1000     1 if equal
-- ~equal     1001     1 if not equal
-- in1 + 4    1010     1
-- out = in2  1011     0

architecture Behavioral of alu_ctrl is
    signal funct3 : std_logic_vector(2 downto 0) := (others => '0');
    signal funct7 : std_logic_vector(6 downto 0) := (others => '0');

    function R_Type(signal funct3 : in )

begin

    funct3 <= instruction(14 downto 12);
    funct7 <= instruction(31 downto 25);

    op_decode: process(alu_op) is
        begin
            if alu_op = "001" then
                
            end if;
    end process op_decode;

end Behavioral;