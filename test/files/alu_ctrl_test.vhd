library ieee;
use ieee.std_logic_1164.all;

entity alu_ctrl_test is
    port(
        status : out std_logic_vector(3 downto 0)
    );
end alu_ctrl_test;

architecture Behavioral of alu_ctrl_test is

    component alu_ctrl is
        port(
            alu_op: in std_logic_vector(2 downto 0);
            instruction: in std_logic_vector(31 downto 0);
            opcode: out std_logic_vector(3 downto 0)
        );
    end component;

    signal op : std_logic_vector(3 downto 0) := (others => '0');
    signal instruc : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_opcode : std_logic_vector(2 downto 0);

begin

    alu_ctrl_inst : alu_ctrl port map(
        alu_op => alu_opcode,
        instruction => instruc,
        opcode => op
    );

    process
    begin
        alu_opcode <= "010";
        instruc <= "01000000000000000000000000110011"; -- add
        wait for 10 ns;
    end process;

end Behavioral;