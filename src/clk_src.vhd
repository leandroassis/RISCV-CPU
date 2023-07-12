library ieee;
use ieee.std_logic_1164.all;

entity clk_src is
    port(
        clk : out std_logic
    );
end clk_src;

architecture Behavioral of clk_src is
    begin
        clock: process is -- clock de 2 GHz
            begin
                clk <= '0';
                wait for 0.5 ns;
                clk <= '1';
                wait for 0.5 ns;
        end process clock;
end architecture;