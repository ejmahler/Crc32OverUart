library ieee;
use ieee.std_logic_1164.all;

entity UartRx is
    generic(
        -- The frequency of i_clk, measured in hz
        CLOCK_HZ    : positive := 25_000_000;

        -- Baud of UART communication. Must be within ~5% of the other end of the line's baud setting for successful communication, and obviously the closer to perfectly matching, the better
        BAUD        : positive
    );
    port (
        i_clk       : in std_logic;
        i_rxPin     : in std_logic;                     -- the external gpio pin we'll sample to receive data
        o_rxActive  : out std_logic;                    -- 1 if this instance is currently in the middle of receiving a frame of data, 0 if idle

        -- AXI read handshake
        o_rdData    : out std_logic_vector(7 downto 0); -- The byte of data we just received. Only valid if o_rdValid is 1.
        o_rdValid   : out std_logic;                    -- 1 if o_rdData contains valid data, 0 otherwise
        i_rdReady   : in std_logic                      -- 1 if our owner is ready to accept a byte of data. Bytes that are not accepted are dropped.
    );
end UartRx;

architecture RTL of UartRx is
    constant CYCLES_PER_BIT : positive := CLOCK_HZ / BAUD;

    -- Stores the partial frame we've received so far
    -- has enough bits to store the received byte. If we wanted a parity bit or more/less payload bits, we'd also store those here.
    signal r_partialFrame: std_logic_vector(7 downto 0) := "00000000";

    -- The current state. Stored as an integer (as opposed to enum) because we treat idle, dead, etc as individual states, 
    -- but we also also treat each data bit as a state, and an int makes it easier to transition between those
    signal r_state              : integer range 0 to 11;
    constant STATE_DEAD         : integer := 0;
    constant STATE_IDLE         : integer := 1;
    constant STATE_STOP         : integer := 2;
    constant STATE_FIRSTDATA    : integer := 10;
    constant STATE_START        : integer := 11;

    -- A decrementing counter we use to track when to sample the rx pin.
    signal r_timer      : integer range 0 to CYCLES_PER_BIT - 1;

    -- Used to double flop the i_rxPin input. From testing, i_rxPin ends up metastable on maybe 0.1% of edges, this protects against that
    signal r_rxPinSync  : std_logic := '0';

begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- Synchronize rx pin
            r_rxPinSync <= i_rxPin;

            -- When the timer is nonzero, tick it down
            if r_timer /= 0 then
                r_timer <= r_timer - 1;
            end if;

            case r_state is
                when STATE_DEAD =>
                    -- When dead, we ignore the current state of the line (IE we don't treat a 0 as a start bit) until we see the line go high
                    if r_rxPinSync = '1' then
                        r_state <= STATE_IDLE;
                    end if;
                when STATE_IDLE =>
                    -- When idle, we're wiating for the line to go low to indicate the start of an rx frame
                    if r_rxPinSync = '0' then
                        r_state <= STATE_START;
                        r_timer <= CYCLES_PER_BIT / 2;
                    end if;


                -- All other states only operate when the timer hits 0
                when STATE_START =>
                    if r_timer = 0 then
                        if r_rxPinSync = '1' then
                            -- If the rx pin is high again when sampling the start bit, this isn't a valid frame
                            r_state <= STATE_IDLE;
                        else
                            -- We have found a start bit, so prepare to receive a frame, which is 8 data bits and a stop bit
                            r_partialFrame <= "00000000";
                            r_timer <= CYCLES_PER_BIT - 1;
                            r_state <= STATE_FIRSTDATA;
                        end if;
                    end if;
                when STATE_STOP =>
                    if r_timer = 0 then
                        if r_rxPinSync = '1' then
                            -- We have seen a valid stop bit, we're done. Combinational logic below will notify our owner that we have received a byte
                            r_state <= STATE_IDLE;
                        else
                            -- The rx pin is 0, so this isn't a valid stop bit. We're going to assume the line is dead until we see a 1
                            r_state <= STATE_DEAD;
                        end if;
                    end if;
                when others =>
                    if r_timer = 0 then
                        -- Receive a data bit and reset the timer
                        r_partialFrame <= r_rxPinSync & r_partialFrame(7 downto 1);
                        r_timer <= CYCLES_PER_BIT - 1;
                        r_state <= r_state - 1;
                    end if;
            end case;
          end if;
    end process;

    o_rxActive <= '1' when r_state > STATE_IDLE else '0';
    o_rdData <= r_partialFrame;
    o_rdValid <= '1' when r_state = STATE_STOP and r_timer = 0 and r_rxPinSync = '1' else '0';
end RTL;
