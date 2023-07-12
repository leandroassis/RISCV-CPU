library ieee;
use ieee.std_logic_1164.all;

entity ID_EX is
    port(
        clk : in std_logic;

        -- data
        instr_in: in std_logic_vector(31 downto 0);
        pc_in : in std_logic_vector(31 downto 0);

        instr_out: out std_logic_vector(31 downto 0);
        pc_out : out std_logic_vector(31 downto 0);

        reg_a_out : out std_logic_vector(31 downto 0);
        reg_b_out : out std_logic_vector(31 downto 0);
        reg_a_in : in std_logic_vector(31 downto 0);
        reg_b_in : in std_logic_vector(31 downto 0);

        imm_in : in std_logic_vector(31 downto 0);
        imm_out : out std_logic_vector(31 downto 0);

        -- control
        -- EX
        pc_reg_alu_in : in std_logic;
        pc_reg_alu_out : out std_logic;
        alu_src_in : in std_logic;
        alu_src_out : out std_logic;
        alu_op_in : in std_logic_vector(2 downto 0);
        alu_op_out : out std_logic_vector(2 downto 0);

        -- MEM
        mem_w_in : in std_logic;
        mem_w_out : out std_logic;
        mem_r_in : in std_logic;
        mem_r_out : out std_logic;
        branch_in : in std_logic;
        branch_out : out std_logic;
        pc_reg_br_in : in std_logic;
        pc_reg_br_out : out std_logic;

        -- WB
        mem_to_reg_in : in std_logic;
        mem_to_reg_out : out std_logic;
        reg_w_in : in std_logic;
        reg_w_out : out std_logic;

        -- harzard
        flush : in std_logic;
        bubble : in std_logic
    );
end ID_EX;

architecture Behavioral of ID_EX is
    begin
        process(clk, flush, bubble)
        begin
            if rising_edge(clk) and not bubble = '1' then
                instr_out <= instr_in;
                pc_out <= pc_in;

                reg_a_out <= reg_a_in;
                reg_b_out <= reg_b_in;
                imm_out <= imm_in;

                pc_reg_alu_out <= pc_reg_alu_in;
                alu_src_out <= alu_src_in;
                alu_op_out <= alu_op_in;
                mem_w_out <= mem_w_in;
                mem_r_out <= mem_r_in;
                branch_out <= branch_in;
                pc_reg_br_out <= pc_reg_br_in;
                mem_to_reg_out <= mem_to_reg_in;
                reg_w_out <= reg_w_in;
            end if;
            if flush = '1' then
                instr_out <= (others => '0');
                pc_out <= (others => '0');

                reg_a_out <= (others => '0');
                reg_b_out <= (others => '0');
                imm_out <= (others => '0');

                pc_reg_alu_out <= '0';
                alu_src_out <= '0';
                alu_op_out <= (others => '0');
                mem_w_out <= '0';
                mem_r_out <= '0';
                branch_out <= '0';
                pc_reg_br_out <= '0';
                mem_to_reg_out <= '0';
                reg_w_out <= '0';
            end if;
        end process;
end Behavioral;
