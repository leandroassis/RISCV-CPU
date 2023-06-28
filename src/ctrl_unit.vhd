library ieee;
use ieee.std_logic_1164.all;


entity ctrl_unit is
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
end entity;

architecture Behavioral of ctrl_unit is
begin
    
    ctrl_decode : process(instr)
    begin
        case instr(6 downto 0) is
            when "0110011" => -- instruções tipo R
                reg_write <= '1'; -- escreve no reg
                mem_to_reg <= '0'; -- passa alu
                mem_write <= 'X';  -- não é mem
                mem_read <= 'X'; 
                branch <= '0'; -- sem branch
                alu_src <= '0'; -- reg
                alu_op <= "0000"; -- resolver dps (add, sub, and, or, xor, sll, slr)
                pc_reg <= '0'; -- passa reg
                pc_reg_branch <= '0'; -- passa pc
            when "0010011" => -- instruções tipo I
                reg_write <= '1';
                mem_to_reg <= '0'; -- passa alu
                mem_write <= 'X';  -- não é mem
                mem_read <= 'X'; 
                branch <= '0'; -- sem branch
                alu_src <= '1'; -- imediato
                alu_op <= "0000"; -- resolver dps (addi, andi, ori, xori, slli, slri)
                pc_reg <= '0'; -- passa reg
                pc_reg_branch <= '0'; -- passa pc
            when "1100011" => -- instruções de branch
                reg_write <= '0';
                mem_to_reg <= 'X'; -- não escreve em reg
                mem_write <= 'X';  -- não é mem
                mem_read <= 'X';
                branch <= '1'; -- branch
                alu_src <= '0'; -- reg
                alu_op <= "0000"; -- resolver dps (equal or not equal)
                pc_reg <= '0'; -- passa reg
                pc_reg_branch <= '0'; -- passa pc
            when "0010111" => -- auipc
                reg_write <= '1';
                mem_to_reg <= '0'; -- passa alu
                mem_write <= 'X';  -- não é mem
                mem_read <= 'X';
                branch <= '0'; -- sem branch
                alu_src <= '1'; -- imediato
                alu_op <= "0000"; -- resolver dps (add)
                pc_reg <= '1'; -- pc
                pc_reg_branch <= '0'; -- passa pc
            when "0110111" => -- lui
                reg_write <= '1';
                mem_to_reg <= '0'; -- passa alu
                mem_write <= 'X';  -- não é mem
                mem_read <= 'X';
                branch <= '0'; -- sem branch
                alu_src <= '1'; -- imediato
                alu_op <= "0000"; -- resolver dps (passa o imediato pra saída)
                pc_reg <= 'X'; -- essa entrada não é processada nessa alu_op
                pc_reg_branch <= '0'; -- passa pc
            when "0000011" => -- lw
                reg_write <= '1';
                mem_to_reg <= '1'; -- passa mem
                mem_write <= '0';  -- le na memória
                mem_read <= '1';
                branch <= '0'; -- sem branch
                alu_src <= '1'; -- imediato
                alu_op <= "0000"; -- resolver dps (add)
                pc_reg <= '0'; -- passa reg
                pc_reg_branch <= '0'; -- passa pc
            when "0100011" => -- sw
                reg_write <= '0';
                mem_to_reg <= 'X'; -- não escreve em reg
                mem_write <= '1';  -- escreve na memória
                mem_read <= '0';
                branch <= '0'; -- sem branch
                alu_src <= '1'; -- imediato
                alu_op <= "0000"; -- resolver dps (add)
                pc_reg <= '0'; -- passa reg
                pc_reg_branch <= '0'; -- passa pc
            when "1101111" => -- jal
                reg_write <= '1';
                mem_to_reg <= '0'; -- passa alu
                mem_write <= 'X';  -- não é mem
                mem_read <= 'X';
                branch <= '1'; -- branch
                alu_src <= '1'; -- imediato
                alu_op <= "0000"; -- resolver dps (add + 4)
                pc_reg <= '1'; -- passa pc
                pc_reg_branch <= '0'; -- passa pc
            when "1100111" => -- jalr
                reg_write <= '1';
                mem_to_reg <= '0'; -- passa alu
                mem_write <= 'X';  -- não é mem
                mem_read <= 'X';
                branch <= '1'; -- branch
                alu_src <= '1'; -- imediato
                alu_op <= "0000"; -- resolver dps (add + 4)
                pc_reg <= '1'; -- passa pc
                pc_reg_branch <= '1'; -- passa reg1
            when others =>
                reg_write <= 'X';
                mem_to_reg <= 'X'; -- não escreve em reg
                mem_write <= 'X';  -- não é mem
                mem_read <= 'X';
                branch <= 'X'; -- sem branch
                alu_src <= 'X'; -- imediato
                alu_op <= "XXXX"; -- resolver dps (add)
                pc_reg <= 'X'; -- passa reg
                pc_reg_branch <= '0'; -- passa pc      
        end case;
    end process ctrl_decode;
end architecture;