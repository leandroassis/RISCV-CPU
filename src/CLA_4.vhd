LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity CLA_4 is
	port(
		X : in std_logic_vector(3 downto 0);
		Y : in std_logic_vector(3 downto 0);
		ci : in std_logic;
		co : out std_logic;
		z : out std_logic_vector(3 downto 0)
	);
end CLA_4;

-- nessa arquitetura, os sinais 'p' e 'g' são gerados em paralelo. Isso acelera ao máximo o processo de soma
architecture Behavioral of CLA_4 is
	signal p     : std_logic_vector(3 downto 0);
    signal g     : std_logic_vector(3 downto 0);
    signal carrys: std_logic_vector(4 downto 0);
	begin
		-- Gerar os sinais 'p' e 'g' em paralelo
		process(X, Y)
			variable p_temp : std_logic_vector(3 downto 0);
			variable g_temp : std_logic_vector(3 downto 0);
		begin
			for i in 0 to 3 loop
				p_temp(i) := X(i) xor Y(i);
				g_temp(i) := X(i) and Y(i);
			end loop;
			p <= p_temp;
			g <= g_temp;
		end process;
	
		-- Calcular os valores dos carrys em paralelo
		carrys(0) <= ci;
		carrys(1) <= g(0) or (p(0) and carrys(0));
		carrys(2) <= g(1) or (p(1) and carrys(1));
		carrys(3) <= g(2) or (p(2) and carrys(2));
		carrys(4) <= g(3) or (p(3) and carrys(3));
	
		-- Atribuir os valores dos sinais de saída
		co <= carrys(4);
		z <= X xor Y xor carrys(3 downto 0);
	end Behavioral;