library ieee;
use ieee.std_logic_1164.all;

entity TopCrc32OverUart is
    generic(
        -- Baud for our UART interface. Only specified here so it's easy to change in tests
        BAUD            : integer := 5_000_000
    );
    port (
        i_Clk           : in std_logic;
        i_UART_RX       : in std_logic;            -- the external gpio pin we'll sample to receive data
        o_UART_TX       : out std_logic := '1';    -- the external gpio pin we'll drive high/low to transmit data

        o_LED_1         : out std_logic;            
        o_LED_2         : out std_logic := '1';

        -- Segment1 is upper digit, Segment2 is lower digit
        o_Segment1_A    : out std_logic;
        o_Segment1_B    : out std_logic;
        o_Segment1_C    : out std_logic;
        o_Segment1_D    : out std_logic;
        o_Segment1_E    : out std_logic;
        o_Segment1_F    : out std_logic;
        o_Segment1_G    : out std_logic;
         
        o_Segment2_A    : out std_logic;
        o_Segment2_B    : out std_logic;
        o_Segment2_C    : out std_logic;
        o_Segment2_D    : out std_logic;
        o_Segment2_E    : out std_logic;
        o_Segment2_F    : out std_logic;
        o_Segment2_G    : out std_logic
    );
end entity TopCrc32OverUart;

architecture RTL of TopCrc32OverUart is
    signal w_rxRdData       : std_logic_vector(7 downto 0);
    signal w_rxRdValid      : std_logic;
    
    signal w_txWrData       : std_logic_vector(7 downto 0);
    signal w_txWrValid      : std_logic;
    signal w_txWrReady      : std_logic;

    signal w_hashByte       : std_logic_vector(7 downto 0);
    signal w_hashByteValid  : std_logic;
    signal w_newHash        : std_logic;
    signal w_hash           : std_logic_vector(31 downto 0);

    signal w_sendCurrentHash: std_logic;
    signal w_requestId      : std_logic_vector(7 downto 0);
begin
    inst_uart_rx : entity work.UartRx
        generic map(
            BAUD            => BAUD
        )
        port map(
            i_clk           => i_Clk,
            i_rxPin         => i_UART_RX,
            o_rxActive      => o_LED_1,

            -- AXI read handshake
            o_rdData        => w_rxRdData,
            o_rdValid       => w_rxRdValid,
            i_rdReady       => '1' -- InputFSM is always ready
        );
    inst_input : entity work.InputFSM
        port map(
            i_clk           => i_Clk,

            i_rxByteValid   => w_rxRdValid,
            i_rxByte        => w_rxRdData,

            o_newHash       => w_newHash,
            o_hashByteValid => w_hashByteValid,
            o_hashByte      => w_hashByte,
            o_sendHash      => w_sendCurrentHash,

            o_requestId     => w_requestId
        );
    inst_crc32 : entity work.ComputeCrc32
        port map(
            i_clk           => i_Clk,
            i_data          => w_hashByte,
            i_dataValid     => w_hashByteValid,
            i_newHash       => w_newHash,
            o_hash          => w_hash
        );
    inst_uart_tx : entity work.UartTxBuffered
        generic map(
            BAUD            => BAUD,
            BUFFER_SIZE_BITS=> 9 -- 9 bits aka 512 elements
        )
        port map(
            i_clk           => i_Clk,
            o_txPin         => o_UART_TX,
            o_txActive      => o_LED_2,

            -- AXI write handshake
            i_wrData        => w_txWrData,
            i_wrValid       => w_txWrValid,
            o_wrReady       => w_txWrReady
        );
    inst_output : entity work.OutputFSM
        port map(
            i_clk           => i_Clk,

            i_sendCurrentHash   => w_sendCurrentHash,
            i_currentRequestId  => w_requestId,
            i_currentHash       => w_hash,

            -- AXI read handshake
            o_rdData            => w_txWrData,
            o_rdValid           => w_txWrValid,
            i_rdReady           => w_txWrReady
        );
    inst_sevensegment_tens : entity work.SevenSegmentHex
        port map (
            i_digit       => w_requestId(7 downto 4),
            o_Segment_A   => o_Segment1_A,
            o_Segment_B   => o_Segment1_B,
            o_Segment_C   => o_Segment1_C,
            o_Segment_D   => o_Segment1_D,
            o_Segment_E   => o_Segment1_E,
            o_Segment_F   => o_Segment1_F,
            o_Segment_G   => o_Segment1_G
        );
    inst_sevensegment_ones : entity work.SevenSegmentHex
        port map (
            i_digit       => w_requestId(3 downto 0),
            o_Segment_A   => o_Segment2_A,
            o_Segment_B   => o_Segment2_B,
            o_Segment_C   => o_Segment2_C,
            o_Segment_D   => o_Segment2_D,
            o_Segment_E   => o_Segment2_E,
            o_Segment_F   => o_Segment2_F,
            o_Segment_G   => o_Segment2_G
        );
end RTL;
