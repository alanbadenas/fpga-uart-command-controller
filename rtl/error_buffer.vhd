library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity error_buffer is
    port (
        clk      : in std_logic;
        addr     : in unsigned(3 downto 0);  
        data_out : out std_logic_vector(7 downto 0)
    );
end entity error_buffer;

architecture Behavioral of error_buffer is
    type memory_array is array (0 to 15) of std_logic_vector(7 downto 0);
    constant MEM : memory_array := (
        0  => x"21",  
        1  => x"32",  
        2  => x"13",  
        3  => x"11",  
        4  => x"12",  
        5  => x"23",  
        6  => x"10",  
        7  => x"22",
        8  => x"30",
        9  => x"21",
        10 => x"20",
        11 => x"12",
        12 => x"31",
        13 => x"12",
        14 => x"22",
        15 => x"23"
    );
begin
    process(clk)
    begin
        if rising_edge(clk) then
            data_out <= MEM(to_integer(addr));
        end if;
    end process;
end architecture Behavioral;
