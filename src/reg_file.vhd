library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    port(
        clk : in std_logic;
        write_en : in std_logic;

        write_addr : in std_logic_vector(4 downto 0);
        write_data : in std_logic_vector(31 downto 0);

        reg_a_addr : in std_logic_vector(4 downto 0);
        reg_b_addr : in std_logic_vector(4 downto 0);

        reg_a_data : out std_logic_vector(31 downto 0);
        reg_b_data : out std_logic_vector(31 downto 0)
    );
end reg_file;

architecture Behavioral of reg_file is
    -- 32 registradores de 32 bits
    type register_mem is array (31 downto 0) of std_logic_vector(31 downto 0);
    signal register_bank : register_mem;

    begin
        register_access: process(clk) is
        begin
            -- na borda de subida
            if rising_edge(clk) then
                --  se write_en = 1, escreve no registrador
                if write_en = '1' then
                    register_bank(to_integer(unsigned(write_addr))) <= write_data;
                    reg_a_data <= (others => 'X');
                    reg_b_data <= (others => 'X');
                end if;
            elsif falling_edge(clk) then -- na borda de descida
                if write_en = '0' then -- se write_en = 0, lê do registrador
                    reg_a_data <= register_bank(to_integer(unsigned(reg_a_addr)));
                    reg_b_data <= register_bank(to_integer(unsigned(reg_b_addr)));
                end if;
            else -- se write_en = X, não faz nada
                reg_a_data <= (others => 'X');
                reg_b_data <= (others => 'X');
            end if;
        end process register_access;

end Behavioral;