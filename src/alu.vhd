library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port(
        in_a, in_b : in std_logic_vector(31 downto 0);
        op : in std_logic_vector(3 downto 0);
        out_r : out std_logic_vector(31 downto 0);
        aux_br : out std_logic
    );
end alu;

-- Operação  OPCODE  Br_aux
-- nop        0000     0
-- Soma       0001     0 
-- Sub        0010     0
-- and        0011     0
-- or         0100     0
-- xor        0101     0
-- sll        0110     0
-- srl        0111     0
-- equal      1000     1 if equal
-- ~equal     1001     1 if not equal
-- in1 + 1    1010     1
-- out = in2  1011     0
-- nop        others   0
architecture Behavioral of alu is
    begin

    process(in_a, in_b, op)
    begin
        case op is
            when "0001" => 
                out_r <= std_logic_vector(signed(in_a) + signed(in_b));
                aux_br <= '0';
            when "0010" => 
                out_r <= std_logic_vector(signed(in_a) - signed(in_b));
                aux_br <= '0';
            when "0011" => 
                out_r <= in_a and in_b;
                aux_br <= '0';
            when "0100" =>
                out_r <= in_a or in_b;
            when "0101" => 
                out_r <= in_a xor in_b;
                aux_br <= '0';
            when "0110" => 
                out_r <= std_logic_vector(shift_left(unsigned(in_a), to_integer(unsigned(in_b(4 downto 0)))));
                aux_br <= '0';
            when "0111" => 
                out_r <= std_logic_vector(shift_right(unsigned(in_a), to_integer(unsigned(in_b(4 downto 0)))));
                aux_br <= '0';
            when "1000" => 
                out_r <= (others => 'X');
                if in_a = in_b then
                	aux_br <= '1';
                else aux_br <= '0';
                end if;
            when "1001" => 
                out_r <= (others => 'X');
                if in_a /= in_b then
                	aux_br <= '1';
                else aux_br <= '0';
                end if;
            when "1010" => 
                out_r <= std_logic_vector(unsigned(in_a) + 1);
                aux_br <= '1';
            when "1011" => 
                out_r <= in_b;
                aux_br <= '0';
            when others => 
                out_r <= in_a;
                aux_br <= '0';
        end case;
    end process;
end Behavioral;
