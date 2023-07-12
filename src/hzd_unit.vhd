library ieee;
use ieee.std_logic_1164.all;


entity hzd_unit is
    port(
        id_ex_mem_r : in std_logic;
        id_ex_reg_dst : in std_logic_vector(4 downto 0);
        if_id_reg_s1 : in std_logic_vector(4 downto 0);
        if_id_reg_s2 : in std_logic_vector(4 downto 0);

        pc_write : out std_logic;
        if_id_write : out std_logic;
        bubble : out std_logic
    );
end hzd_unit;

architecture Behavioral of hzd_unit is
    begin 

        hzd_detection: process(id_ex_mem_r, id_ex_reg_dst, if_id_reg_s1, if_id_reg_s2)
        begin 
            if (id_ex_mem_r = '1') then
                if (id_ex_reg_dst = if_id_reg_s1) or (id_ex_reg_dst = if_id_reg_s2) then -- stall
                    pc_write <= '0';
                    if_id_write <= '0';
                    bubble <= '1';
                end if;
            else
               pc_write <= '1';
            	if_id_write <= '1';
            	bubble <= '0';
            end if;
        end process hzd_detection;
end Behavioral;
