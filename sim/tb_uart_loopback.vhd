library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_uart_loopback is
end entity;

architecture sim of tb_uart_loopback is
    constant CLOCK_FREQ : positive := 1_000_000;
    constant BAUD_RATE  : positive := 100_000;
    constant CLK_PERIOD : time := 1 us;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal tx_start     : std_logic := '0';
    signal tx_data      : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy      : std_logic;
    signal serial_line  : std_logic;
    signal rx_data      : std_logic_vector(7 downto 0);
    signal rx_ready     : std_logic;
begin
    clk <= not clk after CLK_PERIOD / 2;

    tx_i : entity work.uart_tx
        generic map (CLOCK_FREQ => CLOCK_FREQ, BAUD_RATE => BAUD_RATE)
        port map (
            clk => clk, reset => reset, tx_start => tx_start,
            tx_data => tx_data, tx => serial_line, tx_busy => tx_busy
        );

    rx_i : entity work.uart_rx
        generic map (CLOCK_FREQ => CLOCK_FREQ, BAUD_RATE => BAUD_RATE)
        port map (
            clk => clk, reset => reset, rx => serial_line,
            rx_data => rx_data, rx_ready => rx_ready
        );

    stimulus : process
    begin
        reset <= '0';
        wait for 5 * CLK_PERIOD;
        reset <= '1';
        wait for 3 * CLK_PERIOD;

        tx_data  <= x"55";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';

        wait until rx_ready = '1';
        assert rx_data = x"55"
            report "UART loopback mismatch"
            severity failure;

        report "UART loopback passed" severity note;
        stop;
        wait;
    end process;
end architecture sim;
