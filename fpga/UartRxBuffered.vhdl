library ieee;
use ieee.std_logic_1164.all;

entity UartRxBuffered is
    generic(
        -- The frequency of i_clk, measured in hz
        CLOCK_HZ        : positive := 25_000_000;

        -- Baud of UART communication. Must be within ~5% of the other end of the line's baud setting for successful communication, and obviously the closer to perfectly matching, the better
        BAUD            : positive;

        -- Size of our tx buffer in bytes
        BUFFER_SIZE_BITS: positive
    );
    port (
        i_clk           : in std_logic;
        i_rxPin         : in std_logic;                     -- the external gpio pin we'll sample to receive data
        o_rxActive      : out std_logic;                    -- 1 if this instance is currently in the middle of receiving a frame of data, 0 if idle

        -- AXI read handshake
        o_rdData        : out std_logic_vector(7 downto 0); -- The byte of data we just received. Only valid if o_rdValid is 1.
        o_rdValid       : out std_logic;                    -- 1 if o_rdData contains valid data, 0 otherwise
        i_rdReady       : in std_logic                      -- 1 if our owner is ready to accept a byte of data.
    );
end UartRxBuffered;

architecture RTL of UartRxBuffered is
    signal w_rxRdData   : std_logic_vector(7 downto 0);
    signal w_rxRdValid  : std_logic;
    signal w_rxRdReady  : std_logic;
    
begin
    uart_rx_inst : entity work.UartRx
        generic map(
            CLOCK_HZ    => CLOCK_HZ,
            BAUD        => BAUD
        )
        port map(
            i_clk       => i_clk,
            i_rxPin     => i_rxPin,
            o_rxActive  => o_rxActive,

            -- AXI read handshake
            o_rdData    => w_rxRdData,
            o_rdValid   => w_rxRdValid,
            i_rdReady   => w_rxRdReady
        );
    fifo_rx_inst : entity work.Fifo
        generic map(
            DEPTH_BITS  => BUFFER_SIZE_BITS,
            WIDTH       => 8
        )
        port map(
            i_clk       => i_clk,

            -- AXI write handshake
            i_wrData    => w_rxRdData,
            i_wrValid   => w_rxRdValid,
            o_wrReady   => w_rxRdReady,

            -- AXI read handshake
            o_rdData    => o_rdData,
            o_rdValid   => o_rdValid,
            i_rdReady   => i_rdReady
        );
end RTL;
