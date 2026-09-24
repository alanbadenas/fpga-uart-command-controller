library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic(
    CLOCK_FREQ : integer := 50000000;  -- Frequência do clock (padrão 50MHz)
    BAUD_RATE  : integer := 115200
  );
  port(
    clk      : in std_logic;
    reset    : in std_logic;
    tx_start : in std_logic;             -- Sinal de início de transmissão (pulsado por 1 ciclo)
    tx_data  : in std_logic_vector(7 downto 0);  -- Byte a ser transmitido
    tx       : out std_logic;            -- Saída serial
    tx_busy  : out std_logic           -- Indica que a transmissão está em andamento

  );
end entity uart_tx;

architecture Behavioral of uart_tx is
  constant BAUD_PERIOD : integer := CLOCK_FREQ / BAUD_RATE;
  signal baud_counter  : integer range 0 to BAUD_PERIOD := 0;
  type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
  signal state         : state_type := IDLE;
  signal bit_index     : integer range 0 to 7 := 0;
  signal shift_reg     : std_logic_vector(7 downto 0);
  signal tx_reg        : std_logic := '0';
  signal busy_reg      : std_logic := '0';
begin
  tx <= tx_reg;
  tx_busy <= busy_reg;

  
  process(clk, reset)
  begin

    if reset = '0' then
      state        <= IDLE;
      baud_counter <= 0;
      bit_index    <= 0;
      tx_reg       <= '1';
      busy_reg     <= '0';
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          busy_reg <= '0';
          tx_reg   <= '1';
          if tx_start = '1' then
            shift_reg  <= tx_data;
            state      <= START_BIT;
            baud_counter <= 0;
            busy_reg   <= '1';
          end if;
          
        when START_BIT =>
          tx_reg <= '0';  -- Bit de início
          if baud_counter < BAUD_PERIOD - 1 then
            baud_counter <= baud_counter + 1;
          else
            baud_counter <= 0;
            state      <= DATA_BITS;
            bit_index  <= 0;
          end if;
          
        when DATA_BITS =>
          tx_reg <= shift_reg(bit_index);
          if baud_counter < BAUD_PERIOD - 1 then
            baud_counter <= baud_counter + 1;
          else
            baud_counter <= 0;
            if bit_index < 7 then
              bit_index <= bit_index + 1;
            else
              state <= STOP_BIT;
            end if;
          end if;
          
        when STOP_BIT =>
          tx_reg <= '1';  -- Bit de parada
          if baud_counter < BAUD_PERIOD - 1 then
            baud_counter <= baud_counter + 1;
          else
            baud_counter <= 0;
            state <= IDLE;
          end if;
      end case;
    end if;
  end process;
end architecture Behavioral;
