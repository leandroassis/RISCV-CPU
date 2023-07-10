library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fwd_unit is
    port(
        reg_s1 : in std_logic_vector(4 downto 0);
        reg_s2 : in std_logic_vector(4 downto 0);
        reg_dst : in std_logic_vector(4 downto 0);

        mem_wb_reg_dst : in std_logic_vector(4 downto 0);
        ex_mem_reg_dst : in std_logic_vector(4 downto 0);

        -- flags control ex/mem e mem/wb
        ex_mem_reg_w : in std_logic;
        mem_wb_reg_w : in std_logic;

        forward_a : out std_logic_vector(1 downto 0);
        forward_b : out std_logic_vector(1 downto 0)
    );
end fwd_unit;

architecture Behavioral of fwd_unit is
    begin
        forward_decode : process(reg_s1, reg_s2, reg_dst, mem_wb_reg_dst, ex_mem_reg_dst, ex_mem_reg_w, mem_wb_reg_w) is
            begin
                if ex_mem_reg_w = '1' and (ex_mem_reg_dst /= "00000") then
                    if ex_mem_reg_dst = reg_s1 then
                        forward_a <= "10";
                    end if;
                    if ex_mem_reg_dst = reg_s2 then
                        forward_b <= "10";
                    end if;
                elsif mem_wb_reg_w = '1' and (mem_wb_reg_dst /= "00000") then
                    if (mem_wb_reg_dst = reg_s1) and (ex_mem_reg_dst = reg_s1) then
                        forward_a <= "01";
                    end if;
                    if (mem_wb_reg_dst = reg_s2) and (ex_mem_reg_dst = reg_s2) then
                        forward_b <= "01";
                    end if;
                else
                    forward_a <= "00";
                    forward_b <= "00";
                end if;
        end process forward_decode;
end Behavioral;