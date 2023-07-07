library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity imm_gen is
    port(
        instr : in std_logic_vector(31 downto 0);
        imm : out std_logic_vector(31 downto 0)
    );
end imm_gen;

architecture Behavioral of imm_gen is
begin
    decode_instr : process(instr)
    begin
        -- logica para fazer decode da instrução
        case instr(6 downto 0) is
            when "0110111" => -- lui
                imm(31 downto 12) <= instr(31 downto 12);
                imm(11 downto 0) <= (others => '0');
            when "0010111" => -- auipc
                imm(31 downto 12) <= instr(31 downto 12);
                imm(11 downto 0) <= (others => '0');
            when "1101111" => -- jal
                imm(0) <= '0';
                imm(20 downto 1) <= instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21);
                imm(31 downto 21) <= (others => instr(31));
            when "1100111" => -- jalr
                imm(11 downto 0) <= instr(31 downto 20);
                imm(31 downto 12) <= (others => instr(31));
            when "1100011" => -- branch
                imm(0) <= '0';
                imm(12 downto 1) <= instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8);
                imm(31 downto 13) <= (others => instr(31));
            when "0000011" => -- load
                imm(11 downto 0) <= instr(31 downto 20);
                imm(31 downto 12) <= (others => instr(31));
            when "0100011" => -- store
                imm(11 downto 0) <= instr(31 downto 25) & instr(11 downto 7);
                imm(31 downto 12) <= (others => instr(31));
            when "0010011" => -- i-type
                if (instr(13) or (not instr(12))) = '1' then -- andi, ori, xori, 
                    imm(11 downto 0) <= instr(31 downto 20);
                    imm(31 downto 12) <= (others => instr(31));
                else                               -- slli e srli
                    imm(4 downto 0) <= instr(24 downto 20);
                    imm(31 downto 5) <= (others => instr(31));
                end if;
            when others => -- outros
                imm <= (others => 'X');
        end case;
    end process decode_instr;
end architecture;
