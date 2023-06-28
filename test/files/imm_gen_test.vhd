library ieee;
use ieee.std_logic_1164.all;

entity test is
    port(
        clk : in std_logic
    );
end entity;

architecture sim of test is
    
    component imm_gen is
        port(
            instr : in std_logic_vector(31 downto 0);
            imm : out std_logic_vector(31 downto 0)
        );
    end component;


    signal a, b : std_logic_vector(31 downto 0) := (others => '0');
    begin
        
        teste : imm_gen port map("10111010101110101010000001100011", a);

        process is
            begin
                for i in 0 to 100 loop
                    b <= a;
                    wait for 10 ns;
                end loop;
        end process;

end architecture;