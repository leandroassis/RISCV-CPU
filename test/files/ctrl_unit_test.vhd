library ieee;
use ieee.std_logic_1164.all;


entity ctrl_unit_test is
end entity;

architecture Behavioral of ctrl_unit_test is
    component ctrl_unit is
    port(
        instr : in std_logic_vector(31 downto 0);
        pc_reg : out std_logic; -- 0 -> pc, 1 -> reg1
        alu_op : out std_logic_vector(3 downto 0); -- alu opcode
        branch : out std_logic; -- 0 -> não é branch e 1 -> é branch
        mem_read : out std_logic; -- 0 -> sem leitura, 1 -> leitura
        mem_write : out std_logic; -- 0 -> sem escrita, 1 -> escrita
        mem_to_reg : out std_logic; -- 0 -> alu, 1 -> mem
        alu_src : out std_logic; -- 0 -> reg, 1 -> imediato
        reg_write : out std_logic; -- 0 -> leitura , 1 -> escrita
        pc_reg_branch : out std_logic -- 0 -> pc, 1 -> reg1 (entrada do somador do branch)
    );
    end component;

    signal instruc : std_logic_vector(31 downto 0) := (others => '0');
    signal pcorreg, brch, mem_r, mem_w, mem_reg, aluorsrc, reg_w, pcorreg_brch : std_logic := '0';
    signal aluop : std_logic_vector(3 downto 0) := (others => '0');

    begin

        uut : ctrl_unit port map(instruc, pcorreg, aluop, brch, mem_r, mem_w, mem_reg, aluorsrc, reg_w, pcorreg_brch);

        process
        begin
            instruc(6 downto 0) <= "0110011";
            instruc(31 downto 7) <= (others => '0');
            wait for 10 ns;
            instruc(6 downto 0) <= "1100011";
            instruc(31 downto 7) <= (others => '0');
            wait for 10 ns;
            instruc(6 downto 0) <= "0000011";
            instruc(31 downto 7) <= (others => '0');
            wait for 10 ns;
        end process;
end architecture;