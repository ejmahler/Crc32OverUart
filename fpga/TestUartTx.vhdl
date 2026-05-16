library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity TestUartTx is
end TestUartTx;

architecture behave of TestUartTx is
    constant CLOCK_PERIOD   : time := 40 ns;
    constant CYCLES_PER_BIT : positive := 5;
    constant CLOCK_HZ       : positive := 25_000_000;
    constant BAUD           : positive := CLOCK_HZ / CYCLES_PER_BIT;

    signal r_clk        : std_logic := '0';
    signal w_txActive   : std_logic;
    signal w_txPin      : std_logic;

    signal r_wrData     : std_logic_vector(7 downto 0) := "00000000";
    signal r_wrValid    : std_logic := '0';
    signal w_wrReady    : std_logic;
begin
    UUT : entity work.UartTx
        generic map (
            CLOCK_HZ    => CLOCK_HZ,
            BAUD        => BAUD
        )
        port map (
            i_clk       => r_clk,
            o_txPin     => w_txPin,
            o_txActive  => w_txActive,

            -- AXI write handshake
            i_wrData    => r_wrData,
            i_wrValid   => r_wrValid,
            o_wrReady   => w_wrReady
        );

    p_CLK_GEN : process is
    begin
        wait for CLOCK_PERIOD/2;
        r_clk <= not r_clk;
    end process p_CLK_GEN; 

    process
    begin
        wait for CLOCK_PERIOD;
        -- Test the happy path of the uart transmitter. Set the byte "01001011" and the byte valid bit, and verify that it writes out that byte with the correct timing
        assert w_txActive = '0' severity failure;
        assert w_wrReady = '1' severity failure;
        r_wrData <= "01001011";
        r_wrValid <= '1';
        wait for CLOCK_PERIOD;
        assert w_txActive = '1' severity failure;
        assert w_wrReady = '0' severity failure;
        r_wrValid <= '0';
        wait for CLOCK_PERIOD;
        assert w_txActive = '1' severity failure;
        assert w_wrReady = '0' severity failure;

        -- Delay for half a bit so that we can sample halfway through each bit, and verify that the start bit is set
        wait for CYCLES_PER_BIT / 2 * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;

        -- Listen for the transmitter to transmit each of the bits, LSB first
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;

        -- It should be done transmitting the message, now wait for the stop bit
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;

        -- Delay for another half a bit and verify that it's signaling that it's no longer active
        wait for CYCLES_PER_BIT / 2 * CLOCK_PERIOD;
        assert w_txActive = '0' severity failure;
        assert w_wrReady = '1' severity failure;


        -- Another happy path byte
        r_wrData <= "11100001";
        r_wrValid <= '1';
        wait for CLOCK_PERIOD;
        assert w_txActive = '1' severity failure;
        assert w_wrReady = '0' severity failure;
        r_wrValid <= '0';
        wait for CLOCK_PERIOD;
        assert w_txActive = '1' severity failure;
        assert w_wrReady = '0' severity failure;

        -- Delay for half a bit so that we can sample halfway through each bit, and verify that the start bit is set
        wait for CYCLES_PER_BIT / 2 * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;

        -- Listen for the transmitter to transmit each of the bits, LSB first
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;

        -- It should be done transmitting the message, now wait for the stop bit
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;

        -- Delay for another half a bit and verify that it's signaling ready for the next tx byte
        wait for CYCLES_PER_BIT / 2 * CLOCK_PERIOD;
        assert w_txActive = '0' severity failure;
        assert w_wrReady = '1' severity failure;



        -- Wait halfway into what would be the next byte if the transmitter obliviously kept transmitting,
        -- to verify that the transmitter is actually responding to us and not just operating on its own schedule
        wait for CYCLES_PER_BIT * 3 * CLOCK_PERIOD;
        assert w_txActive = '0' severity failure;
        assert w_wrReady = '1' severity failure;
        r_wrData <= "00110010";
        r_wrValid <= '1';
        wait for CLOCK_PERIOD;
        assert w_txActive = '1' severity failure;
        assert w_wrReady = '0' severity failure;
        r_wrValid <= '0';
        wait for CLOCK_PERIOD;
        assert w_txActive = '1' severity failure;
        assert w_wrReady = '0' severity failure;

        -- Delay for half a bit so that we can sample halfway through each bit, and verify that the start bit is set
        wait for CYCLES_PER_BIT / 2 * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;

        -- Listen for the transmitter to transmit each of the bits, LSB first
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '0' severity failure;

        -- It should be done transmitting the message, now wait for the stop bit
        wait for CYCLES_PER_BIT * CLOCK_PERIOD;
        assert w_txPin = '1' severity failure;

        -- Delay for another half a bit and verify that it's signaling ready for the next tx byte
        wait for CYCLES_PER_BIT / 2 * CLOCK_PERIOD;
        assert w_txActive = '0' severity failure;
        assert w_wrReady = '1' severity failure;



        report "Test passed: TestUartTx";
        finish;
    end process;
end behave;