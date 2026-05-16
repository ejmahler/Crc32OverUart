library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity TestUartBuffered is
end TestUartBuffered;

architecture behave of TestUartBuffered is
    constant CLOCK_PERIOD   : time := 40 ns;
    constant CYCLES_PER_BIT : integer := 5;
    constant CLOCK_HZ       : integer := 25_000_000;
    constant BAUD           : integer := CLOCK_HZ / CYCLES_PER_BIT;

    type TestDataArray is array(0 to 31) of std_logic_vector(7 downto 0);
    constant c_testData : TestDataArray := (
        8x"2a",8x"3b",8x"4c",8x"5d",8x"6e",8x"7f",8x"80",8x"91",
        8x"a2",8x"b3",8x"c4",8x"d5",8x"e6",8x"f7",8x"08",8x"19",
        8x"3a",8x"4b",8x"5c",8x"6d",8x"7e",8x"8f",8x"90",8x"a1",
        8x"b2",8x"c3",8x"d4",8x"e5",8x"f6",8x"07",8x"18",8x"29"
    );

    signal r_clk        : std_logic := '0';
    signal w_txPin      : std_logic;

    signal r_wrData     : std_logic_vector(7 downto 0) := "00000000";
    signal r_wrValid    : std_logic := '0';
    signal w_wrReady    : std_logic;

    signal w_rdData     : std_logic_vector(7 downto 0);
    signal w_rdValid    : std_logic;
    signal r_rdReady    : std_logic := '0';

begin
    UUT_TX : entity work.UartTxBuffered
        generic map(
            CLOCK_HZ        => CLOCK_HZ,
            BAUD            => BAUD,
            BUFFER_SIZE_BITS=> 3
        )
        port map (
            i_clk           => r_clk,
            o_txPin         => w_txPin,
            o_txActive      => open,

            -- AXI write handshake
            i_wrData        => r_wrData,
            i_wrValid       => r_wrValid,
            o_wrReady       => w_wrReady
        );
    UUT_RX : entity work.UartRxBuffered
        generic map(
            CLOCK_HZ        => CLOCK_HZ,
            BAUD            => BAUD,
            BUFFER_SIZE_BITS=> 3
        )
        port map (
            i_clk           => r_clk,
            i_rxPin         => w_txPin,
            o_rxActive      => open,

            -- AXI read handshake
            o_rdData        => w_rdData,
            o_rdValid       => w_rdValid,
            i_rdReady       => r_rdReady
        );

    p_CLK_GEN : process is
    begin
        wait for CLOCK_PERIOD/2;
        r_clk <= not r_clk;
    end process p_CLK_GEN; 

    process
    begin
        wait for CLOCK_PERIOD;

        -- We already thoroughly tested the uart tx, uart rx, and fifo, so all we need to do here is test that everything is wired up correctly
        -- To do that, we can just connect the tx serial out pin directly to the rx serial in pin, put bytes in one side, and verify that they come out the other side
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(0);
        r_wrValid <= '1';
        wait for CLOCK_PERIOD;
        r_wrValid <= '0';
        assert w_wrReady = '1' severity failure; -- there should still be plenty of room in the buffer

        -- Wait for the byte to be transmitted. clock_period * (bits * cycles_per_bit + propagation_delay_wiggle_room) 
        wait for CLOCK_PERIOD * (10 * CYCLES_PER_BIT + 10);

        -- Verify that the rx side reports a byte ready
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(0) severity failure;

        -- Request a byte from rx and verify that we get what we expect, and that it clears out the w_rxHasByte flag
        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '0' severity failure;


        -- Test another happy path single byte
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(1);
        r_wrValid <= '1';
        wait for CLOCK_PERIOD;
        r_wrValid <= '0';
        assert w_wrReady = '1' severity failure; -- there should still be plenty of room in the buffer

        -- Wait for the byte to be transmitted. clock_period * (bits * cycles_per_bit + propagation_delay_wiggle_room) 
        wait for CLOCK_PERIOD * (10 * CYCLES_PER_BIT + 10);

        -- Verify that the rx side reports a byte ready
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(1) severity failure;

        -- Request a byte from rx and verify that we get what we expect, and that it clears out the w_rxHasByte flag
        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '0' severity failure;



        -- Test filling up the tx buffer and verifying that it all gets sent. Note that we're sending 8 bytes here, even though the buffer size is 7.
        -- We expect that the UartTxBuffered instance will have begun transmitting by then, which entails popping an element from the buffer
        r_wrValid <= '1';
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(2);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(3);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(4);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(5);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(6);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(7);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(8);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(9);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure; -- It should finally be full after 9 pushes
        r_wrValid <= '0';

        -- If we wait for all the data to be transmitted, one of the bytes wil lbe dropped. We'll test the dropping functionality in a moment, but for now we don't want anything to drop
        -- So wait for ~half of the data to be transmitted. clock_period * (bytes * bits_per_byte * cycles_per_bit + propagation_delay_wiggle_room) 
        wait for CLOCK_PERIOD * (4 * 10 * CYCLES_PER_BIT + 20);

        -- Verify that the rx side reports a byte ready
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(2) severity failure;

        -- Pop a byte and verify that it's the first one we submitted
        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(3) severity failure;

        -- Now that we've made room, wait for the rest of the time. clock_period * (bytes * bits_per_byte * cycles_per_bit + propagation_delay_wiggle_room) 
        wait for CLOCK_PERIOD * (5 * 10 * CYCLES_PER_BIT + 0);

        -- Pop the rest of the bytes out of the rx buffer and verify them
        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(4) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(5) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(6) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(7) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(8) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(9) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure; -- all bytes have been popped
        r_rdReady <= '0';




        -- Test filling up the tx buffer overfull and verifying that the newest items we try to add to the tx buffer get dropped
        r_wrValid <= '1';
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(11);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(12);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(13);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(14);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(15);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(16);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(17);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(18);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        r_wrData <= c_testData(19);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        r_wrData <= c_testData(20);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        r_wrData <= c_testData(21);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        r_wrValid <= '0';

        -- If we just let everything transmit, it'll overfill the rx buffer.
        -- We'll test the rx buffer dropping functionality in a moment, but for now we don't want anything to drop
        -- So wait for ~half of the data to be transmitted. clock_period * (bytes * bits_per_byte * cycles_per_bit + propagation_delay_wiggle_room) 
        wait for CLOCK_PERIOD * (4 * 10 * CYCLES_PER_BIT + 20);

        -- Verify that the rx side reports a byte ready
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;

        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(12) severity failure;

        -- Now that we've made room, wait for the rest of the time. clock_period * (bytes * bits_per_byte * cycles_per_bit + propagation_delay_wiggle_room) 
        wait for CLOCK_PERIOD * (5 * 10 * CYCLES_PER_BIT + 0);

        -- Pop the rest of the bytes out of the rx buffer and verify that items # 12 and #13 were dropped, and the rest were transmitted
        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(13) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(14) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(15) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(16) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(17) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(18) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure; -- all bytes have been popped
        r_rdReady <= '0';

        


        -- Test filling up the rx buffer overfull and verifying that the newest in the rx buffer get dropped
        r_wrValid <= '1';
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(22);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(23);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(24);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(25);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(26);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(27);
        wait for CLOCK_PERIOD;
        r_wrValid <= '0';


        -- Wait for everything we've transmitted so far to go through
        -- clock_period * (bytes * bits_per_byte * cycles_per_bit + propagation_delay_wiggle_room) 
        wait for CLOCK_PERIOD * (6 * 10 * CYCLES_PER_BIT + 20);

        -- Now submit the rest
        r_wrValid <= '1';
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(28);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(29);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(30);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(31);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(0);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        r_wrValid <= '0';



        -- Wait for the rest to go through
        -- So wait the data we submitted so far to be transmitted. clock_period * (bytes * bits_per_byte * cycles_per_bit + propagation_delay_wiggle_room) 
        wait for CLOCK_PERIOD * (5 * 10 * CYCLES_PER_BIT + 20);


        -- Verify that the rx side reports a byte ready
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(22) severity failure;

        -- Pop all bytes out of the rx buffer and verify that items 22-24 were dropped
        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(23) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(24) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(25) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(26) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(27) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure; -- there should still be bytes available
        assert w_rdData = c_testData(28) severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure; -- all bytes have been popped
        r_rdReady <= '0';



        report "Test passed: TestUartBuffered";
        finish;
    end process;
end behave;