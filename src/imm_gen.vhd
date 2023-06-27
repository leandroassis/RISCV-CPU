library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity imm_gen is
    port(
        instr : in std_logic_vector(31 downto 0);
        imm : out std_logic_vector(11 downto 0)
    );
end entity;

architecture Behavioral of imm_gen is
begin
    decode_instr : process(instr)
    begin
        -- logica para fazer decode da instrução
    end process decode_instr;
end architecture;