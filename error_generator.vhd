library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity error_generator is
    Port ( 
        clk              : in STD_LOGIC;
        reset            : in STD_LOGIC;
        btn_generate_error : in STD_LOGIC;
        error_type       : out STD_LOGIC_VECTOR(1 downto 0);  -- 2 bits para tipo de erro (1 ou 2)
        error_field      : out STD_LOGIC_VECTOR(1 downto 0);  -- 2 bits para identificar o canteiro (1,2,3)
        error_valid      : out STD_LOGIC
    );
end error_generator;

architecture Behavioral of error_generator is
    signal counter : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal btn_last_state : STD_LOGIC := '0';  -- Para detectar borda do botão

begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                counter <= (others => '0');
                error_valid <= '0';
            else
                counter <= counter + 1;  -- Gera um valor pseudoaleatório
                
                -- Detecta borda de subida do botão
                if btn_generate_error = '1' and btn_last_state = '0' then
                    error_type <= counter(1 downto 0) mod 2 + 1;  -- Gera erro 1 ou 2
                    error_field <= counter(3 downto 2) mod 3 + 1;  -- Gera canteiro 1, 2 ou 3
                    error_valid <= '1';
                else
                    error_valid <= '0';
                end if;
                
                btn_last_state <= btn_generate_error;
            end if;
        end if;
    end process;
end Behavioral;
