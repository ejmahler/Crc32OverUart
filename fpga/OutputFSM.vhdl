library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OutputFSM takes semantically meaningful structured data (request id and crc32 hash) and serializes it into a stream of bytes, presumably to be sent off-device through uart or etc
-- If the output pin is backed up (due to e.g. the tx buffer being full), OutputFSM will gracefully degrade by dropping entire outputs (As opposed to the worse degradation of individual bytes being dropped from outputs)
entity OutputFSM is
    port (
        i_clk               : in std_logic;

        i_sendCurrentHash   : in std_logic;    -- 1 if we should kick off the process of transmitting the current hash and request id off over our uart line. We'll save a snapshot of the current request id and hash, and carry out the logic internally of serializing
        i_currentRequestId  : in std_logic_vector(7 downto 0);
        i_currentHash       : in std_logic_vector(31 downto 0);

        -- AXI read handshake
        o_rdData            : out std_logic_vector(7 downto 0);
        o_rdValid           : out std_logic;
        i_rdReady           : in std_logic
    );
end;

architecture only of OutputFSM is
    -- Contains whatever's left of the data we need to serialize
    signal r_remainingData : std_logic_vector(31 downto 0);

    -- How many bytes we have left to serialize
    signal r_remainingDataCount : integer range 0 to 5;

begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if r_remainingDataCount /= 0 then
                if i_rdReady = '1' then
                    -- The target we're writing to accepted our previous byte, so send another one if we have any others to send
                    o_rdData <= r_remainingData(7 downto 0);
                    r_remainingDataCount <= r_remainingDataCount - 1;
                    r_remainingData <= "00000000" & r_remainingData(31 downto 8);
                end if;
            elsif i_sendCurrentHash = '1' then
                -- We were asked to initiate a serialization. Pipe the request id straight to the output, and save the current hash to be serialized over the next few cycles
                o_rdData <= i_currentRequestId;
                r_remainingData <= i_currentHash;
                r_remainingDataCount <= 5;
            end if;
        end if;
    end process;

    o_rdValid <= '1' when r_remainingDataCount /= 0 else '0';
end only;
