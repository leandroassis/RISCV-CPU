library ieee;
use ieee.std_logic_1164.all;

entity alu_ctrl is
    port(
        alu_op: in std_logic_vector(2 downto 0);
        instruction: in std_logic_vector(31 downto 0);
        alu_ctrl: out std_logic_vector(3 downto 0)
    );
end entity;

architecture Behavioral of alu_ctrl is

    signal 

begin

end Behavioral;