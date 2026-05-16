library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity TestInputFSM is
end TestInputFSM;

architecture behave of TestInputFSM is

    constant CLOCK_PERIOD   : time := 40 ns;

    signal r_clk            : std_logic := '0';

    signal r_rxByteValid    : std_logic := '0';
    signal r_rxByte         : std_logic_vector(7 downto 0) := "00000000";

    signal w_newHash        : std_logic;
    signal w_hashByteValid  : std_logic;
    signal w_hashByte       : std_logic_vector(7 downto 0);
    signal w_sendHash       : std_logic := '0';

    signal w_requestId      : std_logic_vector(7 downto 0) := 8x"00";

begin
    UUT : entity work.InputFSM
        port map (
            i_clk            => r_clk,

            i_rxByteValid    => r_rxByteValid,
            i_rxByte         => r_rxByte,

            o_newHash        => w_newHash,
            o_hashByteValid  => w_hashByteValid,
            o_hashByte       => w_hashByte,
            o_sendHash       => w_sendHash,

            o_requestId      => w_requestId
        );

    p_CLK_GEN : process is
    begin
        wait for CLOCK_PERIOD/2;
        r_clk <= not r_clk;
    end process p_CLK_GEN; 

    process
    begin
        assert w_sendHash = '0' severity failure;

        -- Send in a byte and verify that it's interpreted as a request id, and a new hash
        r_rxByteValid <= '1';
        r_rxByte <= 8x"52";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '1' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_sendHash = '0' severity failure;

        -- verify that the new hash bit only lasts for one cycle
        wait for CLOCK_PERIOD;
        assert w_newHash = '0' severity failure;

        -- Send in a few data bytes and verify that it gets emitted as a hash byte.
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ab";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"ab" severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;

        r_rxByteValid <= '1';
        r_rxByte <= 8x"4c";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"4c" severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;

        r_rxByteValid <= '1';
        r_rxByte <= 8x"00";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"00" severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;


        -- Send in a control code and verify that a hash byte doesn't get emitted (yet)
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;

        -- Send in 0xff as the second character of the control code and verify that it gets emitted as a hash character
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"ff" severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;


        -- Send another 0xff 0xff sequence

        -- Send in a control code and verify that a hash byte doesn't get emitted (yet)
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;

        -- Send in 0xff as the second character of the control code and verify that it gets emitted as a hash character
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"ff" severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;

        -- Send in the control code to end the hash. Verify that it doesn't get emitted as a hash character, and the bit to send the hash is emitted
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;

        r_rxByteValid <= '1';
        r_rxByte <= 8x"00";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_sendHash = '0' severity failure;


        -- Send in a new request id and verify that we start a new hash
        r_rxByteValid <= '1';
        r_rxByte <= 8x"77";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '1' severity failure;
        assert w_requestId = 8x"77" severity failure;
        assert w_sendHash = '0' severity failure;


        -- Verify that it works if the very first character of a hash is an end-hash control character
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"77" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;
        wait for CLOCK_PERIOD;

        r_rxByteValid <= '1';
        r_rxByte <= 8x"00";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"77" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_sendHash = '0' severity failure;


        ------------------------------------------------------------------------
        -- We've been testing the whole thing with a clock cycle gap between every event, now run the test without that gap
        ------------------------------------------------------------------------


        -- Send in a byte and verify that it's interpreted as a request id, and a new hash
        r_rxByteValid <= '1';
        r_rxByte <= 8x"52";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '1' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_sendHash = '0' severity failure;

        -- Send in a few data bytes and verify that it gets emitted as a hash byte.
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ab";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"ab" severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByteValid <= '1';
        r_rxByte <= 8x"4c";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"4c" severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByteValid <= '1';
        r_rxByte <= 8x"00";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"00" severity failure;
        assert w_sendHash = '0' severity failure;


        -- Send in a control code and verify that a hash byte doesn't get emitted (yet)
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        -- Send in 0xff as the second character of the control code and verify that it gets emitted as a hash character
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"ff" severity failure;
        assert w_sendHash = '0' severity failure;


        -- Send another 0xff 0xff sequence

        -- Send in a control code and verify that a hash byte doesn't get emitted (yet)
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        -- Send in 0xff as the second character of the control code and verify that it gets emitted as a hash character
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"ff" severity failure;
        assert w_sendHash = '0' severity failure;

        -- Send in the control code to end the hash. Verify that it doesn't get emitted as a hash character, and the bit to send the hash is emitted
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByteValid <= '1';
        r_rxByte <= 8x"00";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"52" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_sendHash = '0' severity failure;


        -- Send in a new request id and verify that we start a new hash
        r_rxByteValid <= '1';
        r_rxByte <= 8x"77";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '1' severity failure;
        assert w_requestId = 8x"77" severity failure;
        assert w_sendHash = '0' severity failure;


        -- Verify that it works if the very first character of a hash is an end-hash control character
        r_rxByteValid <= '1';
        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"77" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByteValid <= '1';
        r_rxByte <= 8x"00";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"77" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_sendHash = '0' severity failure;



        ------------------------------------------------------------------------
        -- Verify our timeout functionality. We have a timeout branch both for a normal byte and in the middle of acontrol code, so test both
        ------------------------------------------------------------------------

        -- Send 2 bytes and then stop and let it time out
        r_rxByteValid <= '1';
        r_rxByte <= 8x"99";
        wait for CLOCK_PERIOD;

        assert w_newHash = '1' severity failure;
        assert w_requestId = 8x"99" severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByte <= 8x"ab";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"99" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"ab" severity failure;
        assert w_sendHash = '0' severity failure;

        -- Wait until just before the timeout
        wait for CLOCK_PERIOD * 65535;
        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"99" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        -- Now wait one more cycle and verify that the request id zeroes out
        wait for CLOCK_PERIOD;
        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"00" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        -- Do an entire cycle of computing a hash to verify that the state machine was left in a valid state
        r_rxByteValid <= '1';
        r_rxByte <= 8x"e9";
        wait for CLOCK_PERIOD;

        assert w_newHash = '1' severity failure;
        assert w_requestId = 8x"e9" severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByte <= 8x"aa";
        wait for CLOCK_PERIOD;

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"e9" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"aa" severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"e9" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByte <= 8x"00";
        wait for CLOCK_PERIOD;

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"e9" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '1' severity failure;




        -- Now execute the same test as above, but leave the state machine hanging on a control code instead of a normal byte
        r_rxByteValid <= '1';
        r_rxByte <= 8x"11";
        wait for CLOCK_PERIOD;

        assert w_newHash = '1' severity failure;
        assert w_requestId = 8x"11" severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;
        r_rxByteValid <= '0';

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"11" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        -- Wait until just before the timeout
        wait for CLOCK_PERIOD * 65535;
        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"11" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        -- Now wait one more cycle and verify that the request id zeroes out
        wait for CLOCK_PERIOD;
        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"00" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        -- Do an entire cycle of computing a hash to verify that the state machine was left in a valid state
        r_rxByteValid <= '1';
        r_rxByte <= 8x"2e";
        wait for CLOCK_PERIOD;

        assert w_newHash = '1' severity failure;
        assert w_requestId = 8x"2e" severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByte <= 8x"72";
        wait for CLOCK_PERIOD;

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"2e" severity failure;
        assert w_hashByteValid = '1' severity failure;
        assert w_hashByte = 8x"72" severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByte <= 8x"ff";
        wait for CLOCK_PERIOD;

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"2e" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '0' severity failure;

        r_rxByte <= 8x"00";
        wait for CLOCK_PERIOD;

        assert w_newHash = '0' severity failure;
        assert w_requestId = 8x"2e" severity failure;
        assert w_hashByteValid = '0' severity failure;
        assert w_sendHash = '1' severity failure;



        report "Test passed: TestInputFSM";
        finish;
    end process;
end behave;
