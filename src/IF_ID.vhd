library ieee;
use ieee.std_logic_1164.all;

entity IF_ID is
    port(
        clk : in std_logic;
        instr_in: in std_logic_vector(31 downto 0);
        pc_in : in std_logic_vector(31 downto 0);

        instr_out: out std_logic_vector(31 downto 0);
        pc_out : out std_logic_vector(31 downto 0);

	   write : in std_logic;
        flush : in std_logic
    );
end IF_ID;

architecture Behavioral of IF_ID is
    begin
        process(clk, flush, write)
        begin
            if rising_edge(clk) and write = '1' then
                instr_out <= instr_in;
                pc_out <= pc_in;
            end if;
            if flush = '1' then
                instr_out <= (others => '0');
                pc_out <= (others => '0');
            end if;
        end process;
end Behavioral;
