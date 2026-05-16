library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity TestFifo is
end TestFifo;

architecture behave of TestFifo is

    type TestDataArray is array(0 to 31) of std_logic_vector(7 downto 0);
    constant c_testData : TestDataArray := (
        8x"2a",8x"3b",8x"4c",8x"5d",8x"6e",8x"7f",8x"80",8x"91",
        8x"a2",8x"b3",8x"c4",8x"d5",8x"e6",8x"f7",8x"08",8x"19",
        8x"3a",8x"4b",8x"5c",8x"6d",8x"7e",8x"8f",8x"90",8x"a1",
        8x"b2",8x"c3",8x"d4",8x"e5",8x"f6",8x"07",8x"18",8x"29"
    );

    constant CLOCK_PERIOD   : time := 40 ns;

    signal r_clk            : std_logic := '0';

    signal r_wrData         : std_logic_vector(7 downto 0) := (others => '0');
    signal r_wrValid        : std_logic := '0';
    signal w_wrReady        : std_logic;

    signal w_rdData         : std_logic_vector(7 downto 0);
    signal w_rdValid        : std_logic;
    signal r_rdReady        : std_logic := '0';
begin
    UUT : entity work.Fifo
        generic map (
            DEPTH_BITS  => 3,
            WIDTH       => 8
        )
        port map (
            i_clk       => r_clk,

            -- AXI write handshake
            i_wrData    => r_wrData,
            i_wrValid   => r_wrValid,
            o_wrReady   => w_wrReady,

            -- AXI read handshake
            o_rdData    => w_rdData,
            o_rdValid   => w_rdValid,
            i_rdReady   => r_rdReady
        );

    p_CLK_GEN : process is
    begin
        wait for CLOCK_PERIOD/2;
        r_clk <= not r_clk;
    end process p_CLK_GEN; 

    process
    begin
        wait for CLOCK_PERIOD;

        -- Verify that the fifo starts with no valid read, and ready to write
        assert w_rdValid = '0' severity failure;
        assert w_wrReady = '1' severity failure;

        wait for CLOCK_PERIOD;
        assert w_rdValid = '0' severity failure;
        assert w_wrReady = '1' severity failure;

        -- Push a byte and verify that we're no longer empty
        r_wrValid <= '1';
        r_wrData <= c_testData(0);

        wait for CLOCK_PERIOD;

        -- Verify that we can still write another byte, but that a read is ready
        assert w_rdValid = '1' severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdData = c_testData(0) severity failure;

        -- Leave the byte inside the fifo and verify that everything is stable
        r_wrValid <= '0';

        wait for CLOCK_PERIOD;
        assert w_rdValid = '1' severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdData = c_testData(0) severity failure;

        -- Pop the byte and verify that we become empty
        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        r_rdReady <= '0';

        assert w_rdValid = '0' severity failure;
        assert w_wrReady = '1' severity failure;




        -- Now push 2 bytes and then pop them. Verify that they come out in the right order.
        r_wrValid <= '1';
        r_wrData <= c_testData(1);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(1) severity failure;

        r_wrData <= c_testData(2);
        wait for CLOCK_PERIOD;
        r_wrValid <= '0';

        assert w_rdData = c_testData(1) severity failure;
        assert w_wrReady = '1' severity failure;

        r_rdReady <= '1';
        wait for CLOCK_PERIOD;

        assert w_rdData = c_testData(2) severity failure;

        wait for CLOCK_PERIOD;
        r_rdReady <= '0';
        assert w_rdValid = '0' severity failure;


        -- Fill up the queue and verify that it reports itself full
        r_wrValid <= '1';
        r_wrData <= c_testData(3);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(3) severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(4);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(3) severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(5);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(3) severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(6);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(3) severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(7);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(3) severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_wrReady = '1' severity failure;
        r_wrData <= c_testData(8);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(3) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrData <= c_testData(9);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(3) severity failure;
        assert w_wrReady = '0' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrValid <= '0';

        -- Pop them back out. Verify on the way back down that it doesn't empty until the end, and all the bytes are correct
        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(4) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(5) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(6) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(7) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(8) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(9) severity failure;
        wait for CLOCK_PERIOD;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '0' severity failure;
        r_rdReady <= '0';


        -- Now we're going to go past full and verify that the new bytes we attempt to push once full get ignored
        r_wrValid <= '1';
        r_wrData <= c_testData(11);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(12);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(13);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(14);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(15);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(16);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(17);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(18);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(19);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrData <= c_testData(20);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(11) severity failure;
        r_wrValid <= '0';
        assert w_wrReady = '0' severity failure;
        assert w_rdValid = '1' severity failure;

        -- Now when we pop an element, we should get 13 instead of 11, because 11 and 12 should have been dropped
        r_rdReady <= '1';

        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(12) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(13) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(14) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(15) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(16) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(17) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '0' severity failure;
        r_rdReady <= '0';


        -- We haven't tested any interleaved pops and pushes yet, try that
        r_wrValid <= '1';
        r_wrData <= c_testData(21);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(21) severity failure;
        r_wrData <= c_testData(22);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(21) severity failure;
        r_wrData <= c_testData(23);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(21) severity failure;
        r_wrValid <= '0';

        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(22) severity failure;
        r_rdReady <= '0';

        r_wrValid <= '1';
        r_wrData <= c_testData(24);
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(22) severity failure;
        r_wrData <= c_testData(25);
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(22) severity failure;
        r_wrData <= c_testData(26);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(22) severity failure;
        r_wrValid <= '0';


        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(23) severity failure;
        r_rdReady <= '0';


        r_wrValid <= '1';
        r_wrData <= c_testData(27);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(23) severity failure;
        r_wrData <= c_testData(28);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(23) severity failure;
        r_wrData <= c_testData(29);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(23) severity failure;
        r_wrValid <= '0';

        -- We should have 7 elements right now, making us full
        assert w_wrReady = '0' severity failure;
        assert w_rdValid = '1' severity failure;

        r_rdReady <= '1';
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(24) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(25) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(26) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(27) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(28) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(29) severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '0' severity failure;
        r_rdReady <= '0';


        -- We haven't tried pushing and popping in the same cycle yet. Verify that it handles it properly when nearly empty
        r_wrValid <= '1';
        r_wrData <= c_testData(30);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(30) severity failure;
        r_rdReady <= '1';
        r_wrData <= c_testData(31);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(31) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrData <= c_testData(0);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(0) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrData <= c_testData(1);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(1) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrValid <= '0';
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '0' severity failure;
        r_rdReady <= '0';


        -- Now verify that it handles same-cycle push/pop correctly when nearly full
        r_wrValid <= '1';
        r_wrData <= c_testData(2);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(2) severity failure;
        r_wrData <= c_testData(3);
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(2) severity failure;
        r_wrData <= c_testData(4);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(2) severity failure;
        r_wrData <= c_testData(5);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(2) severity failure;
        r_wrData <= c_testData(6);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(2) severity failure;
        r_wrData <= c_testData(7);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(2) severity failure;
        r_rdReady <= '1';
        r_wrData <= c_testData(8);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(3) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrData <= c_testData(9);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(4) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrData <= c_testData(10);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(5) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrValid <= '0';
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(6) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(7) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(8) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(9) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(10) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '0' severity failure;
        r_rdReady <= '0';



        -- Final boss: Verify that it handles same-cycle push/pop correctly when completely full, IE it delays the push for a cycle
        r_wrValid <= '1';
        r_wrData <= c_testData(13);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(13) severity failure;
        r_wrData <= c_testData(14);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(13) severity failure;
        r_wrData <= c_testData(15);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(13) severity failure;
        r_wrData <= c_testData(16);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(13) severity failure;
        r_wrData <= c_testData(17);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(13) severity failure;
        r_wrData <= c_testData(18);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(13) severity failure;
        r_wrData <= c_testData(19);
        wait for CLOCK_PERIOD;
        assert w_wrReady = '0' severity failure;
        assert w_rdValid = '1' severity failure;
        assert w_rdData = c_testData(13) severity failure;
        r_rdReady <= '1';
        r_wrData <= c_testData(20);
        -- Because we're full, this 20 will be dropped, as you can see from the pops below. Elements canot be simultaneously pushed and poppd while full.
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(14) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrData <= c_testData(21);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(15) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrData <= c_testData(22);
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(16) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        r_wrValid <= '0';
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(17) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(18) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(19) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(21) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_rdData = c_testData(22) severity failure;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '1' severity failure;
        wait for CLOCK_PERIOD;
        assert w_wrReady = '1' severity failure;
        assert w_rdValid = '0' severity failure;


        report "Test passed: TestFifo";
        finish;
    end process;
end behave;
