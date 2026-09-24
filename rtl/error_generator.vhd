library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity error_generator is
    port (
        clk                : in  std_logic;
        reset              : in  std_logic;
        btn_generate_error : in  std_logic;
        error_type         : out std_logic_vector(1 downto 0);
        error_field        : out std_logic_vector(1 downto 0);
        error_valid        : out std_logic
    );
end entity error_generator;

architecture rtl of error_generator is
    signal counter        : unsigned(7 downto 0) := (others => '0');
    signal btn_last_state : std_logic := '0';
begin
    process (clk)
        variable type_value  : natural;
        variable field_value : natural;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                counter        <= (others => '0');
                btn_last_state <= '0';
                error_type     <= "01";
                error_field    <= "01";
                error_valid    <= '0';
            else
                counter     <= counter + 1;
                error_valid <= '0';

                if btn_generate_error = '1' and btn_last_state = '0' then
                    type_value  := (to_integer(counter(1 downto 0)) mod 2) + 1;
                    field_value := (to_integer(counter(3 downto 2)) mod 3) + 1;
                    error_type  <= std_logic_vector(to_unsigned(type_value, error_type'length));
                    error_field <= std_logic_vector(to_unsigned(field_value, error_field'length));
                    error_valid <= '1';
                end if;

                btn_last_state <= btn_generate_error;
            end if;
        end if;
    end process;
end architecture rtl;
