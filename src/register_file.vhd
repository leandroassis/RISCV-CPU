use ieee.std_logic_1164.all;


entity register_file is
    port(
        clk : in std_logic;
        write_en : in std_logic;
        write_addr : in std_logic_vector(4 downto 0);
        reg_a_addr : in std_logic_vector(4 downto 0);
        reg_b_addr : in std_logic_vector(4 downto 0);

        reg_a_data : out std_logic_vector(31 downto 0);
        reg_b_data : out std_logic_vector(31 downto 0);

    )
end register_file;