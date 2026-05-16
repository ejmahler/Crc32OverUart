library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity TestUartRx is
end TestUartRx;

architecture behave of TestUartRx is
    constant CLOCK_PERIOD       : time := 40 ns;
    constant CYCLES_PER_BIT     : positive := 5;
    constant CLOCK_HZ           : positive := 25_000_000;
    constant BAUD               : positive := CLOCK_HZ / CYCLES_PER_BIT;

    signal r_clk                : std_logic := '0';
    signal r_rxPin              : std_logic := '0'; -- rx pin is expected to be high when idle
    signal w_rxActive           : std_logic := '0';

    signal w_rdData             : std_logic_vector(7 downto 0);
    signal w_rdValid            : std_logic := '0';

    -- These following two registers, along with a process to control them, let us assert that the rx receiver did or did not mark a byte valid within a time window, without having to get the exact cycle timing perfect
    signal r_rxByteWasValid     : std_logic := '0';
    signal r_bufferedRxByte     : std_logic_vector(7 downto 0) := "00000000";
    signal r_clearByteWasValid  : std_logic := '0';
begin
    UUT : entity work.UartRx
        generic map (
            CLOCK_HZ    => CLOCK_HZ,
            BAUD        => BAUD
        )
        port map (
            i_clk       => r_clk,
            i_rxPin     => r_rxPin,
            o_rxActive  => w_rxActive,

            -- AXI read handshake
            o_rdData    => w_rdData,
            o_rdValid   => w_rdValid,
            i_rdReady   => '1'
        );

    p_CLK_GEN : process is
    begin
        wait for CLOCK_PERIOD/2;
        r_clk <= not r_clk;
    end process p_CLK_GEN; 

    -- Simple process to track when the uart receiver maks outputs valid, and to buffer the outbut byte, so that we don't have to author the test to check it at exactly the right cycle
    p_rxByteWasValid : process(r_clk) is
    begin
        if rising_edge(r_clk) then
            if w_rdValid = '1' then
                r_rxByteWasValid <= '1';
                r_bufferedRxByte <= w_rdData;
            elsif r_clearByteWasValid = '1' then
                r_rxByteWasValid <= '0';
            end if;

            -- Also verify that w_rdValid is 1 for exactly one cycle
            if r_rxByteWasValid = '1' then
                assert w_rdValid = '0' severity failure;
            end if;
        end if;
    end process p_rxByteWasValid; 

    process
    begin
        wait for CLOCK_PERIOD;

        -- The rx pin is starting out 0. Verify that rx doesn't become active. Internally, it should be in the dead state
        assert w_rxActive = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_rxActive = '0' severity failure;

        -- Now set the line high, which should put it in the idle state
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_rxActive = '0' severity failure;


        -- First, test the happy path of the uart receiver. Set the start bit (ie set r_rxPin low) and then set each of the data bits, each with the appropriate delay
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Now transmit each of the bits of our message. We're transmitting the byte '01001011', LSB first
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- We're done transmitting the message, now we transmit the stop bit, ie just set the line high
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Verify that the rx byte was marked fresh, and it contains the byte we expect
        assert r_rxByteWasValid = '1' severity failure;
        assert r_bufferedRxByte = "01001011" severity failure;
        r_clearByteWasValid <= '1';
        wait for CLOCK_PERIOD;
        r_clearByteWasValid <= '0';
        assert r_rxByteWasValid = '0' severity failure;




        -- Test another happy path byte, to make sure we can receive several bytes
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Now transmit each of the bits of our message. We're transmitting the byte '11001100', LSB first
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- We're done transmitting the message, now we transmit the stop bit, ie just set the line high
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Verify that the rx byte was marked fresh, and it contains the byte we expect
        assert r_rxByteWasValid = '1' severity failure;
        assert r_bufferedRxByte = "11001100" severity failure;
        r_clearByteWasValid <= '1';
        wait for CLOCK_PERIOD;
        r_clearByteWasValid <= '0';
        assert r_rxByteWasValid = '0' severity failure;



        -- One more happy path byte, this time with a large delay before the start byte, to ensure that w're responsive to the actual signals we get, and not just rigid timing
        wait for CLOCK_PERIOD * CYCLES_PER_BIT * 1147;

        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Now transmit each of the bits of our message. We're transmitting the byte '01101001', LSB first
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- We're done transmitting the message, now we transmit the stop bit, ie just set the line high
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Verify that the rx byte was marked fresh, and it contains the byte we expect
        assert r_rxByteWasValid = '1' severity failure;
        assert r_bufferedRxByte = "01101001" severity failure;
        r_clearByteWasValid <= '1';
        wait for CLOCK_PERIOD;
        r_clearByteWasValid <= '0';
        assert r_rxByteWasValid = '0' severity failure;



        -- Stress test: Set the start bit, then quickly unset it. The system should not attempt to keep reading that byte.
        -- If we wait halfway through the byte and then start a real byte, the system should only report the correct byte if it ignored the false start
        r_rxPin <= '0';
        wait for CLOCK_PERIOD * 3;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD * 4;

        -- Now transmit the start bit, followed by the byte '11110000'. Since the first several bytes are low, the system won't be able to reproduce it if it was reading the period of high rxPin above as actual data
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- We're done transmitting the message, now we transmit the stop bit, ie just set the line high
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Verify that the rx byte was marked fresh, and it contains the byte we expect
        assert r_rxByteWasValid = '1' severity failure;
        assert r_bufferedRxByte = "11110000" severity failure;
        r_clearByteWasValid <= '1';
        wait for CLOCK_PERIOD;
        r_clearByteWasValid <= '0';
        assert r_rxByteWasValid = '0' severity failure;



        -- Stress test: Fail to set the stop bit. This should cause two things: 
        --         First, the frame should be dropped
        --        Second, the system should enter a "dead" state where it exits the normal byte receipt loop until it sees the rx pin high
        r_rxPin <= '0';
        wait for CLOCK_PERIOD * 3;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD * 4;

        -- Now transmit the start bit, followed by the byte '01010101'
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- We're done transmitting the message. Normally we would transmit the stop bit (Ie rx pin high) but we're intentionally skipping that, leaving it low
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Verify that the rx byte was not marked fresh
        assert r_rxByteWasValid = '0' severity failure;





        -- The system should not interpret this continued low state as a start bit, and should instead interpret it as the line being dead. 
        -- To test this, we can wait halfway into what would be the next byte if the system just obliviously started receiving another byte
        -- Then start transmitting an actual byte. It will get a garbage byte or nothing if it starts reading at the wrong time
        wait for CYCLES_PER_BIT * CLOCK_PERIOD * 4;
        r_rxPin <= '1';
        wait for CLOCK_PERIOD;



        -- Now transmit a byte, starting with the start bit. Transmit the byte 00001111. Because the first several bits are high, the system
        -- wont' be able to reproduce that if it's been interpreting the rx pin low as valid data
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        r_rxPin <= '0';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- We're done transmitting the message, now we transmit the stop bit, ie just set the line high
        r_rxPin <= '1';
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;

        -- Verify that the rx byte was marked fresh, and it contains the byte we expect
        assert r_rxByteWasValid = '1' severity failure;
        assert r_bufferedRxByte = "00001111" severity failure;
        r_clearByteWasValid <= '1';
        wait for CLOCK_PERIOD;
        r_clearByteWasValid <= '0';
        assert r_rxByteWasValid = '0' severity failure;

        report "Test passed: TestUartRx";
        finish;
    end process;
end behave;