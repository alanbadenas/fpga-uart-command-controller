library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
  generic(
    CLOCK_FREQ : integer := 50000000;  -- Frequência do clock
    BAUD_RATE  : integer := 115200
  );
  port(
    clk      : in std_logic;
    reset    : in std_logic;
    rx       : in std_logic;            -- Entrada serial
    rx_data  : out std_logic_vector(7 downto 0);  -- Byte recebido
    rx_ready : out std_logic           -- Sinaliza que um byte foi recebido
  );
end entity uart_rx;

architecture Behavioral of uart_rx is
  constant BAUD_PERIOD : integer := CLOCK_FREQ / BAUD_RATE;
  signal baud_counter  : integer range 0 to BAUD_PERIOD := 0;
  type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
  signal state         : state_type := IDLE;
  signal bit_index     : integer range 0 to 7 := 0;
  signal shift_reg     : std_logic_vector(7 downto 0);
  signal rx_ready_reg  : std_logic := '0';
begin
  rx_ready <= rx_ready_reg;
  
  process(clk, reset)
  begin
    if reset = '0' then
      state        <= IDLE;
      baud_counter <= 0;
      bit_index    <= 0;
      shift_reg    <= (others => '0');
      rx_ready_reg <= '0';
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          rx_ready_reg <= '0';
          if rx = '0' then  -- Detecção do bit de início
            state <= START_BIT;
            baud_counter <= BAUD_PERIOD/2;  -- Amostra no meio do bit
          end if;
          
        when START_BIT =>
          if baud_counter < BAUD_PERIOD - 1 then
            baud_counter <= baud_counter + 1;
          else
            baud_counter <= 0;
            state <= DATA_BITS;
            bit_index <= 0;
          end if;
          
        when DATA_BITS =>
          if baud_counter < BAUD_PERIOD - 1 then
            baud_counter <= baud_counter + 1;
          else
            baud_counter <= 0;
            shift_reg(bit_index) <= rx;
            if bit_index < 7 then
              bit_index <= bit_index + 1;
            else
              state <= STOP_BIT;
            end if;
          end if;
          
        when STOP_BIT =>
          if baud_counter < BAUD_PERIOD - 1 then
            baud_counter <= baud_counter + 1;
          else
            baud_counter <= 0;
            state <= IDLE;
            rx_ready_reg <= '1';  -- Byte completo recebido
          end if;
      end case;
    end if;
  end process;
  
  rx_data <= shift_reg;
end architecture Behavioral;
