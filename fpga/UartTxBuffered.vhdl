library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity UartTxBuffered is
    generic(
        -- The frequency of i_clk, measured in hz
        CLOCK_HZ        : positive := 25_000_000;

        -- Baud of UART communication. Must be within ~5% of the other end of the line's baud setting for successful communication, and obviously the closer to perfectly matching, the better
        BAUD            : positive;

        -- The buffer size will be 2**BUFFER_SIZE_BITS - 1
        BUFFER_SIZE_BITS: positive
    );
    port (
        i_clk           : in std_logic;
        o_txPin         : out std_logic := '1';             -- the external gpio pin we'll drive high/low to transmit data
        o_txActive      : out std_logic := '0';             -- When 1, we are currently transmitting a byte

        -- AXI write handshake
        i_wrData        : in std_logic_vector(7 downto 0);  -- The next byte our owner wants us to transmit. Only actually pushed into the tx buffer when i_wrValid and o_wrReady are simultaneously 1
        i_wrValid       : in std_logic;                     -- 1 if `i_wrData` represents a new byte to transmit, 0 if stale/invalid.
        o_wrReady       : out std_logic                     -- When 1, indicates to our owner that we are ready for another byte of data
    );
end UartTxBuffered;

architecture RTL of UartTxBuffered is
    signal w_txWrData   : std_logic_vector(7 downto 0);
    signal w_txWrValid  : std_logic;
    signal w_txWrReady  : std_logic;
begin
    uart_tx_inst : entity work.UartTx
        generic map(
            CLOCK_HZ    => CLOCK_HZ,
            BAUD        => BAUD
        )
        port map(
            i_clk       => i_clk,
            o_txPin     => o_txPin,
            o_txActive  => o_txActive,

            -- AXI write handshake
            i_wrData    => w_txWrData,
            i_wrValid   => w_txWrValid,
            o_wrReady   => w_txWrReady
        );
    fifo_tx_inst : entity work.Fifo
        generic map(
            DEPTH_BITS  => BUFFER_SIZE_BITS,
            WIDTH       => 8
        )
        port map(
            i_clk       => i_clk,

            -- AXI write handshake
            i_wrData    => i_wrData,
            i_wrValid   => i_wrValid,
            o_wrReady   => o_wrReady,

            -- AXI read handshake
            o_rdData    => w_txWrData,
            o_rdValid   => w_txWrValid,
            i_rdReady   => w_txWrReady
        );
end RTL;
