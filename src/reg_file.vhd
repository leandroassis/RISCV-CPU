library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    port(
        clk : in std_logic;
        write_en : in std_logic;

        write_data : in std_logic_vector(31 downto 0);
        
        write_addr : in std_logic_vector(4 downto 0);
        reg_a_addr : in std_logic_vector(4 downto 0);
        reg_b_addr : in std_logic_vector(4 downto 0);

        reg_a_data : out std_logic_vector(31 downto 0);
        reg_b_data : out std_logic_vector(31 downto 0)
    );
end reg_file;

architecture Behavioral of reg_file is
    -- 32 registradores de 32 bits
    type register_mem is array (integer range <>) of std_logic_vector(31 downto 0);
    signal register_bank : register_mem(0 to 31) := (others => x"00000000");

    begin
        reg_a_data <= register_bank(to_integer(unsigned(reg_a_addr)));
        reg_b_data <= register_bank(to_integer(unsigned(reg_b_addr)));
        
        register_access: process(clk, write_en, write_addr) is
        begin
            -- na borda de subida
            if rising_edge(clk) and write_en = '1' then
            	if write_addr /= "00000" then
            		register_bank(to_integer(unsigned(write_addr))) <= write_data;
            	end if;
            end if;
        end process register_access;

end Behavioral;
