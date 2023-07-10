library ieee;
use ieee.std_logic_1164.all;

entity MEM_WB is
    port(
        clk : in std_logic;
        
        alu_result_in : in std_logic_vector(31 downto 0);
        mem_in : in std_logic_vector(31 downto 0);
        wb_addr_in : in std_logic_vector(4 downto 0);

        alu_result_out : out std_logic_vector(31 downto 0);
        mem_out : out std_logic_vector(31 downto 0);

        wb_addr_out : out std_logic_vector(4 downto 0);

        -- control
        -- WB
        mem_to_reg_in : in std_logic;
        mem_to_reg_out : out std_logic;
        reg_w_in : in std_logic;
        reg_w_out : out std_logic
    );
end MEM_WB;

architecture Behavioral of MEM_WB is
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                alu_result_out <= alu_result_in;
                mem_out <= mem_in;
                wb_addr_out <= wb_addr_in;

                mem_to_reg_out <= mem_to_reg_in;
                reg_w_out <= reg_w_in;
            end if;
        end process;
end Behavioral;
