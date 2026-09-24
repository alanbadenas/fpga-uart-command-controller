
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_serial is
end entity tb_serial;

architecture Behavioral of tb_serial is
    -- Constantes para clock e baudrate
    constant CLOCK_FREQ : integer := 50000000;
    constant BAUD_RATE  : integer := 115200;
    
    -- Sinais para simulação
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal tx_start     : std_logic;
    signal tx_data      : std_logic_vector(7 downto 0);
    signal uart_tx_busy : std_logic;
    signal rs232_tx     : std_logic;
    
    signal rx_data      : std_logic_vector(7 downto 0);
    signal rx_ready     : std_logic;
    
begin

    -- Geração do clock: 20 ns de período (50MHz)
    clk_process : process
    begin
        clk <= '0';
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
    end process;
    
    -- Instanciação do módulo UART Transmissor
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
    
    -- Instanciação do módulo UART Receptor (loopback: conecta a saída do TX)
    uart_rx_inst : entity work.uart_rx
        generic map(
            CLOCK_FREQ => CLOCK_FREQ,
            BAUD_RATE  => BAUD_RATE
        )
        port map(
            clk      => clk,
            reset    => reset,
            rx       => rs232_tx,  -- Loopback: rs232_tx ligado a rx
            rx_data  => rx_data,
            rx_ready => rx_ready
        );
    
    -- Processo de teste
    tb_process : process
    begin
        -- Aplicação do reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;
        
        -- Envia um byte de teste, por exemplo, 0x55
        tx_data  <= x"55";
        tx_start <= '1';
        wait for 20 ns;    -- Pulso curto para iniciar a transmissão
        tx_start <= '0';
        
        -- Aguarda a transmissão e a recepção (rx_ready sinaliza byte recebido)
        wait until rx_ready = '1';
        
        -- Verifica se o dado recebido é igual ao enviado
        assert rx_data = x"55"
            report "Teste falhou: rx_data não é igual a tx_data"
            severity error;
        
        wait for 100 ns;
        
        -- Finaliza a simulação
        assert false report "Fim da simulação" severity failure;
    end process;
    
end architecture Behavioral;
