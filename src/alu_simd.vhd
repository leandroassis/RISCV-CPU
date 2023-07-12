library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_simd is
	port(
		A_i, B_i  : in std_logic_vector(31 downto 0);
		instruction : in std_logic_vector(31 downto 0);
		S_o		 : out std_logic_vector(31 downto 0);

        opcode : in std_logic_vector(3 downto 0)
	);
end alu_simd;

architecture Behavioral of alu_simd is
	component CLA_4 is
		port(
			X : in std_logic_vector(3 downto 0);
			y : in std_logic_vector(3 downto 0);
			ci : in std_logic;
			co : out std_logic;
			z : out std_logic_vector(3 downto 0)
		);
	end component CLA_4;
	
	signal vecSize_i : std_logic_vector(2 downto 0) := (others => '0');
	signal A, B, saida8, saida4, saida2, saida1 : std_logic_vector(31 downto 0) := (others => '0');
	signal carrys : std_logic_vector(8 downto 0) := (others => '0'); -- sinal auxiliar 7 downto 0 = carrys, e carrys(0) sempre depende de mode_i
	
begin

	ints_8: for i in 0 to 7 generate
		adder0to7: CLA_4 port map(A(4*(i+1)-1 downto 4*i), B(4*(i+1)-1 downto 4*i), carrys(0), carrys(i+1), saida8(4*(i+1)-1 downto 4*i));
	end generate;

	-- to do: corrigir lógica
	ints_4: for i in 0 to 3 generate
		adder8to11: CLA_4 port map(A(4*(2*i+1)-1 downto 8*i), B(4*(i*2+1)-1 downto 8*i), carrys(0), carrys(2*i+1), saida4(4*(i*2+1)-1 downto 8*i));
		adder12to15: CLA_4 port map(A(4*(2*i+2)-1 downto 4*(i*2+1)), B(4*(2*i+2)-1 downto 4*(i*2+1)), carrys(2*i+1), carrys(2*i+2), saida4(4*(2*i+2)-1 downto 4*(i*2+1)));
	end generate;

	ints_2: for i in 0 to 1 generate
		adder16to17: CLA_4 port map(A(4*(4*i+1)-1 downto 16*i), B(4*(4*i+1)-1 downto 16*i), carrys(0), carrys(4*i+1), saida2(4*(4*i+1)-1 downto 16*i));
		adder18to19: CLA_4 port map(A(4*(4*i+2)-1 downto 4*(i*4+1)), B(4*(4*i+2)-1 downto 4*(i*4+1)), carrys(4*i+1), carrys(4*i+2), saida2(4*(4*i+2)-1 downto 4*(i*4+1)));
		adder20to21: CLA_4 port map(A(4*(4*i+3)-1 downto 4*(i*4+2)), B(4*(4*i+3)-1 downto 4*(i*4+2)), carrys(4*i+2), carrys(4*i+3), saida2(4*(4*i+3)-1 downto 4*(i*4+2)));
		adder22to23: CLA_4 port map(A(4*(4*i+4)-1 downto 4*(i*4+3)), B(4*(4*i+4)-1 downto 4*(i*4+3)), carrys(4*i+3), carrys(4*i+4), saida2(4*(4*i+4)-1 downto 4*(i*4+3)));
	end generate;

	ints_1: for i in 0 to 7 generate
		adder24to30: CLA_4 port map(A(4*(i+1)-1 downto 4*i), B(4*(i+1)-1 downto 4*i), carrys(i), carrys(i+1), saida1(4*(i+1)-1 downto 4*i));
	end generate;
	
	process(saida1, saida2, saida4, saida8, opcode, instruction) is
		begin
            if instruction(6 downto 0) = "1110011" or instruction(6 downto 0) = "0011011" or instruction(6 downto 0) = "0111011" then
                -- addi, slli, srli
                vecSize_i <= instruction(14 downto 12);
            else vecSize_i <= instruction(27 downto 25); -- add, sub, sll e srl
            end if;

            if opcode = "0001" then -- soma
                A <= A_i;
                B <= B_i;
                carrys(0) <= '0';
            elsif opcode = "0010" then -- sub
                A <= A_i;
                B <= not B_i;
                carrys(0) <= '1';

            elsif opcode = "0110" then -- shift left
                A <= A_i;
                B <= B_i;
                case vecSize_i is
                    when "000" => -- se 8 de 4 bits
                        if B(2 downto 0) >= "100" then
                            S_o <= (others => '0');
                        elsif B(2 downto 0) = "000" then
                            S_o <= A;
                        else
                            S_o(3 downto 0) <= std_logic_vector(shift_left(A(3 downto 0), to_integer(B(2 downto 0))));
                            S_o(7 downto 4) <= std_logic_vector(shift_left(A(7 downto 4), to_integer(B(2 downto 0))));
                            S_o(11 downto 8) <= std_logic_vector(shift_left(A(11 downto 8), to_integer(B(2 downto 0))));
                            S_o(15 downto 12) <= std_logic_vector(shift_left(A(15 downto 12), to_integer(B(2 downto 0))));
                            S_o(19 downto 16) <= std_logic_vector(shift_left(A(19 downto 16), to_integer(B(2 downto 0))));
                            S_o(23 downto 20) <= std_logic_vector(shift_left(A(23 downto 20), to_integer(B(2 downto 0))));
                            S_o(27 downto 24) <= std_logic_vector(shift_left(A(27 downto 24), to_integer(B(2 downto 0))));
                            S_o(31 downto 28) <= std_logic_vector(shift_left(A(31 downto 28), to_integer(B(2 downto 0))));
                        end if;
                    when "001" => -- se 4 de 8 bits
                        if B(3 downto 0) >= "1000" then
                            S_o <= (others => '0');
                        elsif B(3 downto 0) = "0000" then
                            S_o <= A;
                        else
                            S_o(7 downto 0) <= std_logic_vector(shift_left(A(7 downto 0), to_integer(B(3 downto 0))));
                            S_o(15 downto 8) <= std_logic_vector(shift_left(A(15 downto 8), to_integer(B(3 downto 0))));
                            S_o(23 downto 16) <= std_logic_vector(shift_left(A(23 downto 16), to_integer(B(3 downto 0))));
                            S_o(31 downto 24) <= std_logic_vector(shift_left(A(31 downto 24), to_integer(B(3 downto 0))));
                        end if;
                    when "010" => -- se 2 de 16 bits
                        if B(4 downto 0) >= "10000" then
                            S_o <= (others => '0');
                        elsif B(4 downto 0) = "00000" then
                            S_o <= A;
                        else
                            S_o(15 downto 0) <= std_logic_vector(shift_left(A(15 downto 0), to_integer(B(4 downto 0))));
                            S_o(31 downto 16) <= std_logic_vector(shift_left(A(31 downto 16), to_integer(B(4 downto 0))));
                        end if;
                    when "011" => -- se 1 de 32 bits
                        if B(5 downto 0) >= "100000" then
                            S_o <= (others => '0');
                        elsif B(5 downto 0) = "000000" then
                            S_o <= A;
                        else
                            S_o <= std_logic_vector(shift_left(A, to_integer(B(5 downto 0))));
                        end if;
                    when others =>
                        S_o <= (others => 'Z');
                end case;
            
            elsif opcode = "0111" then -- shift right
                A <= A_i;
                B <= B_i;
                case vecSize_i is
                    when "000" => -- se 8 de 4 bits
                        if B(2 downto 0) >= "100" then
                            S_o <= (others => '0');
                        elsif B(2 downto 0) = "000" then
                            S_o <= A;
                        else
                            S_o(3 downto 0) <= std_logic_vector(shift_right(A(3 downto 0), to_integer(B(2 downto 0))));
                            S_o(7 downto 4) <= std_logic_vector(shift_right(A(7 downto 4), to_integer(B(2 downto 0))));
                            S_o(11 downto 8) <= std_logic_vector(shift_right(A(11 downto 8), to_integer(B(2 downto 0))));
                            S_o(15 downto 12) <= std_logic_vector(shift_right(A(15 downto 12), to_integer(B(2 downto 0))));
                            S_o(19 downto 16) <= std_logic_vector(shift_right(A(19 downto 16), to_integer(B(2 downto 0))));
                            S_o(23 downto 20) <= std_logic_vector(shift_right(A(23 downto 20), to_integer(B(2 downto 0))));
                            S_o(27 downto 24) <= std_logic_vector(shift_right(A(27 downto 24), to_integer(B(2 downto 0))));
                            S_o(31 downto 28) <= std_logic_vector(shift_right(A(31 downto 28), to_integer(B(2 downto 0))));
                        end if;
                    when "001" => -- se 4 de 8 bits
                        if B(3 downto 0) >= "1000" then
                            S_o <= (others => '0');
                        elsif B(3 downto 0) = "0000" then
                            S_o <= A;
                        else
                            S_o(7 downto 0) <= std_logic_vector(shift_right(A(7 downto 0), to_integer(B(3 downto 0))));
                            S_o(15 downto 8) <= std_logic_vector(shift_right(A(15 downto 8), to_integer(B(3 downto 0))));
                            S_o(23 downto 16) <= std_logic_vector(shift_right(A(23 downto 16), to_integer(B(3 downto 0))));
                            S_o(31 downto 24) <= std_logic_vector(shift_right(A(31 downto 24), to_integer(B(3 downto 0))));
                        end if;
                    when "010" => -- se 2 de 16 bits
                        if B(4 downto 0) >= "10000" then
                            S_o <= (others => '0');
                        elsif B(4 downto 0) = "00000" then
                            S_o <= A;
                        else
                            S_o(15 downto 0) <= std_logic_vector(shift_right(A(15 downto 0), to_integer(B(4 downto 0))));
                            S_o(31 downto 16) <= std_logic_vector(shift_right(A(31 downto 16), to_integer(B(4 downto 0))));
                        end if;
                    when "011" => -- se 1 de 32 bits
                        if B(5 downto 0) >= "100000" then
                            S_o <= (others => '0');
                        elsif B(5 downto 0) = "000000" then
                            S_o <= A;
                        else
                            S_o <= std_logic_vector(shift_right(A, to_integer(B(5 downto 0))));
                        end if;
                    when others =>
                        S_o <= (others => 'Z');
                end case;
            else S_o <= (others => 'Z');
            end if;

            if opcode = "0001" or opcode = "0010" then
                case vecSize_i is
                    when "000" =>
                        S_o <= saida8;
                    when "001" =>
                        S_o <= saida4;
                    when "010" =>	
                        S_o <= saida2;
                    when "011" =>
                        S_o <= saida1;
                    when others =>
                        S_o <= (others => 'Z');
                end case;
            end if;
	end process;
end Behavioral;