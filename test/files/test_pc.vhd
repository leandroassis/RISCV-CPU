library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_pc is
    port(
        btn : in std_logic
    );
end entity;

architecture Behavioral of test_pc is
    component prog_count is 
        port(
            clk : in std_logic;
            imm : in std_logic_vector(31 downto 0);
            branch : in std_logic;
            pc : out std_logic_vector(31 downto 0)
        );
    end component;

    signal immediate, ptr_pc : std_logic_vector(31 downto 0) := (others => '0');
    signal clock : std_logic := '0';

    begin 

        teste : prog_count port map(clock,immediate, '1', ptr_pc);

        process is
        begin
            for i in 0 to 100 loop
                immediate <= std_logic_vector(to_unsigned(i, 32));
                clock <= '0';
                wait for 10 ns;

                clock <= '1';
                wait for 10 ns;
            end loop;
        end process;
end Behavioral;