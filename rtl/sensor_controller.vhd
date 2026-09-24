library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sensor_controller is
    generic (
        CLOCK_FREQ : positive := 50_000_000;
        BAUD_RATE  : positive := 115_200
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;  -- active-low reset
        btn_error   : in  std_logic;  -- active-low push button
        btn_manual1 : in  std_logic;
        btn_manual2 : in  std_logic;
        btn_manual3 : in  std_logic;
        rs232_rx    : in  std_logic;
        rs232_tx    : out std_logic;
        led1        : out std_logic;
        led2        : out std_logic;
        led3        : out std_logic;
        led4        : out std_logic
    );
end entity sensor_controller;

architecture rtl of sensor_controller is
    signal tx_start     : std_logic := '0';
    signal tx_data      : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_busy : std_logic;
    signal rx_data      : std_logic_vector(7 downto 0);
    signal rx_ready     : std_logic;

    type fsm_state is (IDLE, START_TX, WAIT_TX_BUSY, WAIT_TX_DONE, WAIT_ACK);
    signal state           : fsm_state := IDLE;
    signal command_pending : std_logic := '0';
    signal command_byte    : std_logic_vector(7 downto 0) := (others => '0');
    signal show_field_led  : std_logic := '0';

    signal btn_error_prev   : std_logic := '1';
    signal btn_manual1_prev : std_logic := '1';
    signal btn_manual2_prev : std_logic := '1';
    signal btn_manual3_prev : std_logic := '1';

    signal error_addr : unsigned(3 downto 0) := (others => '0');
    signal error_data : std_logic_vector(7 downto 0);
begin
    uart_tx_inst : entity work.uart_tx
        generic map (
            CLOCK_FREQ => CLOCK_FREQ,
            BAUD_RATE  => BAUD_RATE
        )
        port map (
            clk      => clk,
            reset    => reset,
            tx_start => tx_start,
            tx_data  => tx_data,
            tx       => rs232_tx,
            tx_busy  => uart_tx_busy
        );

    uart_rx_inst : entity work.uart_rx
        generic map (
            CLOCK_FREQ => CLOCK_FREQ,
            BAUD_RATE  => BAUD_RATE
        )
        port map (
            clk      => clk,
            reset    => reset,
            rx       => rs232_rx,
            rx_data  => rx_data,
            rx_ready => rx_ready
        );

    error_buffer_inst : entity work.error_buffer
        port map (
            clk      => clk,
            addr     => error_addr,
            data_out => error_data
        );

    process (clk, reset)
    begin
        if reset = '0' then
            state            <= IDLE;
            command_pending  <= '0';
            command_byte     <= (others => '0');
            tx_start         <= '0';
            tx_data          <= (others => '0');
            show_field_led   <= '0';
            btn_error_prev   <= '1';
            btn_manual1_prev <= '1';
            btn_manual2_prev <= '1';
            btn_manual3_prev <= '1';
            error_addr       <= (others => '0');
        elsif rising_edge(clk) then
            btn_error_prev   <= btn_error;
            btn_manual1_prev <= btn_manual1;
            btn_manual2_prev <= btn_manual2;
            btn_manual3_prev <= btn_manual3;
            tx_start         <= '0';

            case state is
                when IDLE =>
                    command_pending <= '0';
                    show_field_led  <= '0';

                    if btn_error = '0' and btn_error_prev = '1' then
                        command_byte    <= error_data;
                        command_pending <= '1';
                        show_field_led  <= '1';
                        state           <= START_TX;
                        if error_addr = "1111" then
                            error_addr <= (others => '0');
                        else
                            error_addr <= error_addr + 1;
                        end if;

                    elsif btn_manual1 = '0' and btn_manual1_prev = '1' then
                        command_byte    <= x"10";
                        command_pending <= '1';
                        show_field_led  <= '1';
                        state           <= START_TX;

                    elsif btn_manual2 = '0' and btn_manual2_prev = '1' then
                        command_byte    <= x"20";
                        command_pending <= '1';
                        show_field_led  <= '1';
                        state           <= START_TX;

                    elsif btn_manual3 = '0' and btn_manual3_prev = '1' then
                        command_byte    <= x"30";
                        command_pending <= '1';
                        show_field_led  <= '1';
                        state           <= START_TX;
                    end if;

                when START_TX =>
                    if command_pending = '1' and uart_tx_busy = '0' then
                        tx_data  <= command_byte;
                        tx_start <= '1';
                        state    <= WAIT_TX_BUSY;
                    end if;

                when WAIT_TX_BUSY =>
                    if uart_tx_busy = '1' then
                        state <= WAIT_TX_DONE;
                    end if;

                when WAIT_TX_DONE =>
                    if uart_tx_busy = '0' then
                        state <= WAIT_ACK;
                    end if;

                when WAIT_ACK =>
                    if rx_ready = '1' and rx_data = x"01" then
                        command_pending <= '0';
                        state           <= IDLE;
                    end if;
            end case;
        end if;
    end process;

    -- LEDs are active-low on the target board.
    led1 <= '0' when (show_field_led = '1' and command_byte(5 downto 4) = "01" and state /= IDLE) else '1';
    led2 <= '0' when (show_field_led = '1' and command_byte(5 downto 4) = "10" and state /= IDLE) else '1';
    led3 <= '0' when (show_field_led = '1' and command_byte(5 downto 4) = "11" and state /= IDLE) else '1';
    led4 <= '0' when state = IDLE else '1';
end architecture rtl;
