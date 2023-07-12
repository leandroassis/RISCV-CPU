library ieee;
use ieee.std_logic_1164.all;

entity mem_br_taken is
    port (
        alu_br : in std_logic;
        branch : in std_logic;

        if_ex_flush : out std_logic;
        if_id_flush : out std_logic
    );
end mem_br_taken;

architecture Behavioral of mem_br_taken is
    begin
        process (alU_br, branch)
        begin
            if_ex_flush <= '0';
            if_id_flush <= '0';
            if (alU_br = '1' and branch = '1') then
                if_ex_flush <= '1';
                if_id_flush <= '1';
            end if;
        end process;
end Behavioral;
