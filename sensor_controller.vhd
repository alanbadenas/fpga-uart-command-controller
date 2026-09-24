library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sensor_controller is
    port(
         clk         : in std_logic;
         reset       : in std_logic;
         btn_error   : in std_logic;  -- Botão para gerar erro (utiliza a ROM)
         btn_manual1 : in std_logic;  -- Botões para comando manual dos canteiros
         btn_manual2 : in std_logic;
         btn_manual3 : in std_logic;
         rs232_rx    : in std_logic;
         rs232_tx    : out std_logic;
         led1        : out std_logic;
         led2        : out std_logic;
         led3        : out std_logic;
			led4        : out std_logic

    );
end entity sensor_controller;

architecture Behavioral of sensor_controller is

    constant CLOCK_FREQ : integer := 50000000;
    constant BAUD_RATE  : integer := 115200;
    
    -- Sinais para UART
    signal tx_start      : std_logic := '0';
    signal tx_data       : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_busy  : std_logic;
    
    signal rx_data       : std_logic_vector(7 downto 0);
    signal rx_ready      : std_logic;
    
    -- Sinais para controle de comando
    type fsm_state is (IDLE, SEND_CMD, WAIT_TX_DONE, WAIT_ACK);
    signal state           : fsm_state := IDLE;
    signal command_pending : std_logic := '0';
    signal command_byte    : std_logic_vector(7 downto 0) := (others => '0');
    signal is_error        : std_logic := '0';
    
    -- Detecção de borda para os botões
    signal btn_error_prev, btn_manual1_prev, btn_manual2_prev, btn_manual3_prev : std_logic := '0';
    
    -- Registrador de endereço para o buffer de erros (ROM)
    signal error_addr : unsigned(3 downto 0) := (others => '0');
    signal error_data : std_logic_vector(7 downto 0);
    
begin

    -- Instanciação do UART Transmissor
    uart_tx_inst : entity work.uart_tx
        generic map(
            CLOCK_FREQ => CLOCK_FREQ,
            BAUD_RATE  => BAUD_RATE
        )
        port map(
            clk      => clk,
            reset    => reset,
            tx_start => tx_start,
            tx_data  => tx_data,
            tx       => rs232_tx,
            tx_busy  => uart_tx_busy
        );
    
    -- Instanciação do UART Receptor
    uart_rx_inst : entity work.uart_rx
        generic map(
            CLOCK_FREQ => CLOCK_FREQ,
            BAUD_RATE  => BAUD_RATE
        )
        port map(
            clk      => clk,
            reset    => reset,
            rx       => rs232_rx,
            rx_data  => rx_data,
            rx_ready => rx_ready
        );
    
    -- Instanciação do Buffer de Erros (ROM)
    error_buffer_inst : entity work.error_buffer
        port map(
            clk      => clk,
            addr     => error_addr,
            data_out => error_data
        );
    
    -- FSM de controle de envio de comandos e handshake com o RX
    process(clk, reset)
    begin
        if reset = '0' then
            state              <= IDLE;
            command_pending    <= '0';
            tx_start           <= '0';
            tx_data            <= (others => '0');
            is_error           <= '0';
            btn_error_prev     <= '1';
            btn_manual1_prev   <= '1';
            btn_manual2_prev   <= '1';
            btn_manual3_prev   <= '1';
            error_addr         <= (others => '0');
        elsif rising_edge(clk) then
            -- Detecção de borda para os botões
            btn_error_prev   <= btn_error;
            btn_manual1_prev <= btn_manual1;
            btn_manual2_prev <= btn_manual2;
            btn_manual3_prev <= btn_manual3;
            
            case state is
                when IDLE =>
						  led4 <= '0' ;

                    if (btn_error = '0' and btn_error_prev = '1') then
                        -- Leitura do próximo erro na ROM
                        command_byte <= error_data;
                        command_pending <= '1';
                        is_error <= '1';
                        state <= SEND_CMD;
                        -- Incrementa o endereço com wrap-around
                        if error_addr = "1111" then
                            error_addr <= (others => '0');
                        else
                            error_addr <= error_addr + 1;
                        end if;
                        
                    elsif (btn_manual1 = '0' and btn_manual1_prev = '1') then
                        command_byte <= std_logic_vector(to_unsigned(16, command_byte'length));
                        command_pending <= '1';
                        is_error <= '1';
                        state <= SEND_CMD;
                        
                    elsif (btn_manual2 = '0' and btn_manual2_prev = '1') then
                        command_byte <= std_logic_vector(to_unsigned(32, command_byte'length));
                        command_pending <= '1';
                        is_error <= '1';
                        state <= SEND_CMD;
                        
                    elsif (btn_manual3 = '0' and btn_manual3_prev = '1') then
                        command_byte <= std_logic_vector(to_unsigned(48, command_byte'length));
                        command_pending <= '1';
                        is_error <= '1';
                        state <= SEND_CMD;
                    end if;
                    
                when SEND_CMD =>
						  led4 <= '1' ;

                    if command_pending = '1' then
							 tx_data  <= command_byte;
							 tx_start <= '1';  -- Pulso de início de transmissão
							 state <= WAIT_TX_DONE;
							end if;
                    
                when WAIT_TX_DONE =>

                    tx_start <= '0';  -- Garante pulso único
                    if uart_tx_busy = '0' then
                        state <= WAIT_ACK;
                    end if;
                    
                when WAIT_ACK =>
                    if rx_ready = '1' then
                        if rx_data = x"01" then
                            command_pending <= '0';
                            state <= IDLE;
                        end if;
                    end if;
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
    
    -- Acionamento dos LEDs: enquanto comando de erro estiver pendente, a LED do canteiro correspondente é acesa.
    led1 <= '0' when (is_error = '1' and command_byte(5 downto 4) = "01" and state /= IDLE) else '1';
    led2 <= '0' when (is_error = '1' and command_byte(5 downto 4) = "10" and state /= IDLE) else '1';
    led3 <= '0' when (is_error = '1' and command_byte(5 downto 4) = "11" and state /= IDLE) else '1';

end architecture Behavioral;
