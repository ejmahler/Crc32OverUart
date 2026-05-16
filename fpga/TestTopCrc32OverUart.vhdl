library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity TestTopCrc32OverUart is
end TestTopCrc32OverUart;

architecture behave of TestTopCrc32OverUart is
    constant CLOCK_PERIOD     : time := 40 ns;
    constant CYCLES_PER_BIT   : integer := 5;
    constant CLOCK_HZ         : integer := 25_000_000;
    constant BAUD              : integer := CLOCK_HZ / CYCLES_PER_BIT;

    type TestDataArray is array(0 to 31) of std_logic_vector(7 downto 0);
    constant c_testData : TestDataArray := (
        8x"2a",8x"3b",8x"4c",8x"5d",8x"6e",8x"7f",8x"80",8x"91",
        8x"a2",8x"b3",8x"c4",8x"d5",8x"e6",8x"f7",8x"08",8x"19",
        8x"3a",8x"4b",8x"5c",8x"6d",8x"7e",8x"8f",8x"90",8x"a1",
        8x"b2",8x"c3",8x"d4",8x"e5",8x"f6",8x"07",8x"18",8x"29"
    );

    signal r_clk        : std_logic := '0';
    signal w_txPin      : std_logic;
    signal w_rxPin      : std_logic;

    signal w_rxRdData   : std_logic_vector(7 downto 0);
    signal w_rxRdValid  : std_logic;
    signal r_rxRdReady  : std_logic := '0';

    signal r_txWrData   : std_logic_vector(7 downto 0) := "00000000";
    signal r_txWrValid  : std_logic := '0';
    signal w_txWrReady  : std_logic;
begin
    UUT : entity work.TopCrc32OverUart
        generic map(
            BAUD            => BAUD
        )
        port map (
            i_clk           => r_clk,
            i_UART_RX       => w_rxPin,
            o_UART_TX       => w_txPin
        );

    -- instantiate another uart that we'll plug into the top entity's. that way we can feet it bytes instead of having to worry about feeling it individual bits
    inst_uart_tx : entity work.UartTxBuffered
        generic map(
            CLOCK_HZ        => CLOCK_HZ,
            BAUD            => BAUD,
            BUFFER_SIZE_BITS=> 4
        )
        port map (
            i_clk           => r_clk,
            o_txPin         => w_rxPin,
            o_txActive      => open,

            -- AXI write handshake
            i_wrData        => r_txWrData,
            i_wrValid       => r_txWrValid,
            o_wrReady       => open
        );
    inst_uart_rx : entity work.UartRxBuffered
        generic map(
            CLOCK_HZ        => CLOCK_HZ,
            BAUD            => BAUD,
            BUFFER_SIZE_BITS=> 4
        )
        port map (
            i_clk           => r_clk,
            i_rxPin         => w_txPin,
            o_rxActive      => open,

            -- AXI read handshake
            o_rdData        => w_rxRdData,
            o_rdValid       => w_rxRdValid,
            i_rdReady       => r_rxRdReady
        );


    p_CLK_GEN : process is
    begin
        wait for CLOCK_PERIOD/2;
        r_clk <= not r_clk;
    end process p_CLK_GEN; 

    process
    begin
        ------------------------------------------------------------------------
        -- Plug in a new request id and hash 4 bytes
        ------------------------------------------------------------------------
        r_txWrValid <= '1';
        r_txWrData <= c_testData(0);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(1);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(2);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(3);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(4);
        wait for CLOCK_PERIOD;
        r_txWrData <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_txWrData <= 8x"00";
        wait for CLOCK_PERIOD;
        r_txWrValid <= '0';

        -- Wait as much time as the process could feasbily take
        wait for CLOCK_PERIOD * (12 * 10 * CYCLES_PER_BIT + 25);

        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = c_testData(0) severity failure;

        -- Pull data out from the rx buffer. Verify that we got the request id, followed by the hash in little endian order
        r_rxRdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"7b" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"3f" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"fa" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"4e" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '0' severity failure;
        r_rxRdReady <= '0';


        ------------------------------------------------------------------------
        -- Plug in a new request id and hash 8 bytes, including an 0xff, which requires a control code
        ------------------------------------------------------------------------
        r_txWrValid <= '1';
        r_txWrData <= c_testData(5);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(6);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(7);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(8);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(9);
        wait for CLOCK_PERIOD;
        r_txWrData <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_txWrData <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(10);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(11);
        wait for CLOCK_PERIOD;
        r_txWrData <= c_testData(12);
        wait for CLOCK_PERIOD;
        r_txWrData <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_txWrData <= 8x"00";
        wait for CLOCK_PERIOD;
        r_txWrValid <= '0';

        -- Wait as much time as the process could feasbily take
        wait for CLOCK_PERIOD * (17 * 10 * CYCLES_PER_BIT + 25);

        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = c_testData(5) severity failure;

        -- Pull data out from the rx buffer. Verify that we got the request id, followed by the hash in little endian order
        r_rxRdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"27" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"8c" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"43" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"10" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '0' severity failure;
        r_rxRdReady <= '0';

        ------------------------------------------------------------------------
        -- Test an empty hash
        ------------------------------------------------------------------------
        r_txWrValid <= '1';
        r_txWrData <= c_testData(5);
        wait for CLOCK_PERIOD;
        r_txWrData <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_txWrData <= 8x"00";
        wait for CLOCK_PERIOD;
        r_txWrValid <= '0';

        -- Wait as much time as the process could feasbily take
        wait for CLOCK_PERIOD * (8 * 10 * CYCLES_PER_BIT + 25);

        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = c_testData(5) severity failure;

        -- Pull data out from the rx buffer. Verify that we got the request id, followed by the hash in little endian order
        r_rxRdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"00" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"00" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"00" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '1' severity failure;
        assert w_rxRdData = 8x"00" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rxRdValid = '0' severity failure;
        r_rxRdReady <= '0';

        

        report "Test passed: TestTopCrc32OverUart";
        finish;
    end process;
end behave;