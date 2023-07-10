library ieee;
use ieee.std_logic_1164.all;

entity EX_MEM is
    port(
        clk : in std_logic;
        
        alu_result_in : in std_logic_vector(31 downto 0);
        branch_alu_in : in std_logic;
        reg_a_in : in std_logic_vector(31 downto 0);
        reg_b_in : in std_logic_vector(31 downto 0);
        imm_in : in std_logic_vector(31 downto 0);
        wb_addr_in : in std_logic_vector(4 downto 0);

        imm_out : out std_logic_vector(31 downto 0);
        reg_a_out : out std_logic_vector(31 downto 0);
        reg_b_out : out std_logic_vector(31 downto 0);
        alu_result_out : out std_logic_vector(31 downto 0);
        branch_alu_out : out std_logic;
        wb_addr_out : out std_logic_vector(4 downto 0);

        -- control
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
        reg_w_out : out std_logic
    );
end EX_MEM;

architecture Behavioral of EX_MEM is
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                imm_out <= imm_in;
                reg_a_out <= reg_a_in;
                reg_b_out <= reg_b_in;
                alu_result_out <= alu_result_in;
                branch_alu_out <= branch_alu_in;
                wb_addr_out <= wb_addr_in;

                mem_w_out <= mem_w_in;
                mem_r_out <= mem_r_in;
                branch_out <= branch_in;
                pc_reg_br_out <= pc_reg_br_in;
                mem_to_reg_out <= mem_to_reg_in;
                reg_w_out <= reg_w_in;
            end if;
        end process;
end Behavioral;
