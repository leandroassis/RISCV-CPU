library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prog_count is
    port(
        clk : in std_logic;
        imm : in std_logic_vector(31 downto 0);
        branch : in std_logic;
        pc_reg_mux : in std_logic;
        reg_in : in std_logic_vector(31 downto 0);
        pc : out std_logic_vector(31 downto 0)
    );
end prog_count;

architecture Behavioral of prog_count is
    signal immediate, ptr_pc : std_logic_vector(31 downto 0) := (others => '0');
    begin
        immediate <= imm;
        pc <= ptr_pc;

        fetch_instr: process(clk, ptr_pc, branch, pc_reg_mux) is
        begin
            if rising_edge(clk) then
                if branch = '1' then
                	if pc_reg_mux = '1' then
                    	ptr_pc <= std_logic_vector(unsigned(ptr_pc) + unsigned(immediate));
                    else
                    	ptr_pc <= std_logic_vector(unsigned(reg_in) + unsigned(immediate));
                    end if;
                else
                    ptr_pc <= std_logic_vector(unsigned(ptr_pc) + 1);
                end if;
            end if;
        end process fetch_instr;
end Behavioral;
