library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UartTx is
    generic(
        -- The frequency of i_clk, measured in hz
        CLOCK_HZ    : positive := 25_000_000;

        -- Baud of UART communication. Must be within ~5% of the other end of the line's baud setting for successful communication, and obviously the closer to perfectly matching, the better
        BAUD        : positive
    );
    port (
        i_clk       : in std_logic;
        o_txPin     : out std_logic;                    -- the external gpio pin we'll drive high/low to transmit data
        o_txActive  : out std_logic := '0';             -- 1 if we are currently in the middle of transmitting a byte of data, 0 if we're idle

        -- AXI write handshake
        i_wrData    : in std_logic_vector(7 downto 0);  -- The next byte our owner wants us to transmit. Transmission only actually begins when i_wrValid and o_wrReady are simultaneously 1
        i_wrValid   : in std_logic;                     -- 1 if `i_wrData` represents a new byte to transmit, 0 if stale/invalid.
        o_wrReady   : out std_logic                     -- When 1, indicates to our owner that we are ready for another byte of data
    );
end UartTx;

architecture RTL of UartTx is
    constant CYCLES_PER_BIT : positive := CLOCK_HZ / BAUD;

    -- Stores what's left of the frame we're currently transmitting. Includes all stop bits, parity bits, etc, although right now we only support no parity and 1 stop bit.
    -- The stop bit serves as a sentinel, so we know we're done when this contains all zeros
    signal r_partialFrame: std_logic_vector(8 downto 0) := "000000000";

    -- A decrementing counter we use to track when to write to the tx pin.
    signal r_timer : natural range 0 to CYCLES_PER_BIT - 1 := 0;
begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- When the timer is nonzero, tick it down
            if r_timer /= 0 then
                r_timer <= r_timer - 1;
            end if;

            -- When we have data to transmit and the timer is 0, transmit a bit
            if r_partialFrame /= "000000000" and r_timer = 0 then 
                o_txPin <= r_partialFrame(0);
                r_partialFrame <= '0' & r_partialFrame(8 downto 1);
                r_timer <= CYCLES_PER_BIT - 1;
            end if;

            -- When we're idle, listen for a new byte to transmit
            if o_wrReady = '1' then
                if i_wrValid = '1' then
                    -- We were just given a new byte to transmit. Set up to transmit it.
                    o_txPin <= '0'; -- start bit
                    r_partialFrame <= '1' & i_wrData; -- data bits followed by stop bit
                    r_timer <= CYCLES_PER_BIT - 1;
                else
                    -- No new byte to transmit, so just keep the tx pin high
                    o_txPin <= '1';
                end if;
            end if;
          end if;
    end process;

    -- We're active whenever we have data to transmit, but we also want the count the lame duck period after the last bit has been sent, while the timer is still counting down
    o_txActive <= '1' when r_partialFrame /= "000000000" or r_timer /= 0 else '0';

    -- We're ready whenever we aren't active
    o_wrReady <= '1' when r_partialFrame = "000000000" and r_timer = 0 else '0';
end RTL;
