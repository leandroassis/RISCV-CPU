library ieee;
use ieee.std_logic_1164.all;

entity IF_ID is
    port(
        clk : in std_logic;
        instr_in: in std_logic_vector(31 downto 0);
        pc_in : in std_logic_vector(31 downto 0);
        if_id_write : in std_logic;
        if_id_flush : in std_logic;

        instr_out: out std_logic_vector(31 downto 0);
        pc_out : out std_logic_vector(31 downto 0)
    );
end IF_ID;

architecture Behavioral of IF_ID is
    begin
        process(clk, if_id_flush, if_id_write)
        begin
            if rising_edge(clk) and if_id_write = '1' and not if_id_flush = '1' then
                instr_out <= instr_in;
                pc_out <= pc_in;
            else
                instr_out <= (others => '0');
                pc_out <= (others => '0');
            end if;
        end process;
end Behavioral;