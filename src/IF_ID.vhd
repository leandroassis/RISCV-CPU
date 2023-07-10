library ieee;
use ieee.std_logic_1164.all;

entity IF_ID is
    port(
        clk : in std_logic;
        instr_in: in std_logic_vector(31 downto 0);
        pc_in : in std_logic_vector(31 downto 0);

        instr_out: out std_logic_vector(31 downto 0);
        pc_out : out std_logic_vector(31 downto 0)
    );
end IF_ID;

architecture Behavioral of IF_ID is
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                instr_out <= instr_in;
                pc_out <= pc_in;
            end if;
        end process;
end Behavioral;