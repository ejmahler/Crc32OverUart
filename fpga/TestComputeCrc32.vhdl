library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity TestComputeCrc32 is
end TestComputeCrc32;

architecture behave of TestComputeCrc32 is

    constant CLOCK_PERIOD  : time := 40 ns;

    signal r_clk            : std_logic := '0';
    signal r_data           : std_logic_vector(7 downto 0) := (others => '0');
    signal r_data_valid     : std_logic := '0';
    signal r_new_hash       : std_logic := '0';
    signal w_hash           : std_logic_vector(31 downto 0);
begin
    UUT : entity work.ComputeCrc32
        port map (
            i_clk           => r_clk,
            i_data          => r_data,
            i_dataValid     => r_data_valid,
            i_newHash       => r_new_hash,
            o_hash          => w_hash
        );

    p_CLK_GEN : process is
    begin
        wait for CLOCK_PERIOD/2;
        r_clk <= not r_clk;
    end process p_CLK_GEN; 

    process
    begin
        -- Verify that the hash doesn't change if we don't set the data valid bit
        r_data <= 8x"aa";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"00000000" severity failure;
        r_data <= 8x"bb";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"00000000" severity failure;

        -- Set data valid so that we acutally compute a crc32 hash of 0xbb
        r_data_valid <= '1';
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"79E18AA3" severity failure;

        -- Verify again that the hash doesn't change if we don't set the data valid bit
        r_data_valid <= '0';
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"79E18AA3" severity failure;

        wait for CLOCK_PERIOD;
        assert w_hash = 32x"79E18AA3" severity failure;

        -- Set the data bit true again, but don't change the data, and verify that we keep building on the old hash, rather than starting a new one
        r_data_valid <= '1';
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"C8832D7B" severity failure;

        -- Start a new hash and verify that it actually is a new hash, vs continuing the old one
        r_new_hash <= '1';
        r_data <= 8x"bb";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"79E18AA3" severity failure;

        -- Test some other single-byte hashes
        r_data <= 8x"00";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"527D5351" severity failure;

        r_data <= 8x"3f";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"3C8D26C4" severity failure;

        r_data <= 8x"f1";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"5378BF27" severity failure;

        -- Test a 10-byte hash, one byte at a time, building from the 0xf1 hash we just started
        r_new_hash <= '0';
        r_data <= 8x"21";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"748FCC06" severity failure;

        r_data <= 8x"ee";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"3BE02C48" severity failure;

        r_data <= 8x"78";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"62A5FACC" severity failure;

        r_data <= 8x"00";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"DCD11FBF" severity failure;

        r_data <= 8x"92";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"CD344043" severity failure;

        r_data <= 8x"92";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"730805B9" severity failure;

        r_data <= 8x"ff";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"35D4A100" severity failure;

        r_data <= 8x"43";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"006369B8" severity failure;

        r_data <= 8x"ae";
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"648210BF" severity failure;

        -- Verify that if we pass new hash without new data, it zeroes out the hash
        r_new_hash <= '1';
        r_data_valid <= '0';
        wait for CLOCK_PERIOD;
        assert w_hash = 32x"00000000" severity failure;

        report "Test passed: TestComputeCrc32";
        finish;
    end process;
end behave;
