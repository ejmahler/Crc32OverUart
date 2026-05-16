library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity TestOutputFSM is
end TestOutputFSM;

architecture behave of TestOutputFSM is

    constant CLOCK_PERIOD       : time := 40 ns;

    signal r_clk                : std_logic := '0';
    signal r_sendCurrentHash    : std_logic := '0';
    signal r_requestId          : std_logic_vector(7 downto 0) := 8x"00";
    signal r_currentHash        : std_logic_vector(31 downto 0) := 32x"00000000";

    signal w_rdData             : std_logic_vector(7 downto 0);
    signal w_rdValid            : std_logic;
    signal r_rdReady            : std_logic := '0';

begin
    UUT : entity work.OutputFSM
        port map (
            i_clk               => r_clk,

            i_sendCurrentHash   => r_sendCurrentHash,
            i_currentRequestId  => r_requestId,
            i_currentHash       => r_currentHash,

            -- AXI read handshake
            o_rdData            => w_rdData,
            o_rdValid           => w_rdValid,
            i_rdReady           => r_rdReady
        );

    p_CLK_GEN : process is
    begin
        wait for CLOCK_PERIOD/2;
        r_clk <= not r_clk;
    end process p_CLK_GEN; 

    process
    begin
        wait for CLOCK_PERIOD;
        -- Set up a request id and fake hash, and verify that they are serialized properly
        r_rdReady <= '1';
        r_requestId <= 8x"75";
        r_currentHash <= 32x"abcdef01";
        r_sendCurrentHash <= '1';
        assert w_rdValid = '0' severity failure;
        wait for CLOCK_PERIOD;
        r_sendCurrentHash <= '0';

        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"75" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"01" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"ef" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"cd" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"ab" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure;

        -- Verify that if i_sendCurrentHash is triggered in the middle of an existing serialization, it ignores it and continues the existing process
        r_requestId <= 8x"86";
        r_currentHash <= 32x"bcdef012";
        r_sendCurrentHash <= '1';
        wait for CLOCK_PERIOD;
        r_sendCurrentHash <= '0';

        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"86" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"12" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"f0" severity failure;
        r_sendCurrentHash <= '1';
        wait for CLOCK_PERIOD;
        r_sendCurrentHash <= '0';
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"de" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"bc" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure;

        -- Verify that the serialzation does not make progress when r_rdReady is 0
        r_rdReady <= '0';
        r_requestId <= 8x"99";
        r_currentHash <= 32x"3456789a";
        r_sendCurrentHash <= '1';
        wait for CLOCK_PERIOD;
        r_sendCurrentHash <= '0';

        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"99" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"99" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"99" severity failure;

        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"9a" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"9a" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"9a" severity failure;

        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"78" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"78" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"78" severity failure;

        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"56" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"56" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"56" severity failure;

        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"34" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"34" severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = 8x"34" severity failure;


        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure;

        report "Test passed: TestOutputFSM";
        finish;
    end process;
end behave;
