library ieee;
use ieee.std_logic_1164.all;

-- InputFSM takes a stream of bytes, presumably from uart or etc, and deserialzes them into semantically meaningful inputs for the program.
--  - Messages are expected to start with a 1-byte request ID. THe request ID doesn't mean anything within this program, but we will pair output hahes with the input request IDs to disanbiguate multiple requests in flight
--  - Messages then contain an arbitrary number of bytes to be hashed
--  - All bytes are valid except 0xff, which is a control code. The byte following 0xff will specify a comand to the FSM
--      - If the byte following 0xff is 0x00, the message has ended and we will trigger the OutputFSM to send back the computed hash
--      - If the byte following 0xff is 0xff, the latter will be added to the hash instead of being interpreted as a control code, and will continue adding subsequent bytes to the hash
--  - There is a timeout of 2.6ms. If in the middle of receiving a message we go that long without receving a new byte, we'll cancel the current message and begin waiting for a new message.
entity InputFSM is
    port (
        i_clk           : in std_logic;

        i_rxByteValid   : in std_logic;    -- 1 if i_rxByte contains a valid byte of data from the rx buffer
        i_rxByte        : in std_logic_vector(7 downto 0); 

        o_newHash       : out std_logic := '0'; -- 1 if our hasher should begin a new hash
        o_hashByteValid : out std_logic := '0'; -- 1 if o_hashByte contains a valid byte of data that should be added to the hash
        o_hashByte      : out std_logic_vector(7 downto 0) := "00000000";
        o_sendHash      : out std_logic := '0'; -- 1 if the current hash is done and should be sent back over uart

        o_requestId     : out std_logic_vector(7 downto 0) := "00000000" -- the current request id
    );
end;

architecture only of InputFSM is
    type InputState is (NewHash, NextByte, ControlCode);
    signal r_state : InputState := NewHash;

    -- Incrementing counter. Start at 0 and ticks up. When it hits 65535, we time out the current request and reset.
    -- At 25mhz, this will count for about 2.6ms, so our timeout is 2.6 ms. This is suitable for high baud rates, 
    -- but for a low baud rate like 4800, it takes 2ms to receive every byte, so there isn't much difference between a valid next byte and a timeout
    signal r_timer : natural range 0 to 65535;
begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- Only pulse the new hash, hash byte, and send hash bits for one cycle
            if o_newHash = '1' then
                o_newHash <= '0';
            end if;
            if o_hashByteValid = '1' then
                o_hashByteValid <= '0';
            end if;
            if o_sendHash = '1' then
                o_sendHash <= '0';
            end if;

            case r_state is
                when NewHash =>
                    -- We're waiting for a new stream to begin. If we have a byte of data from rx, interpret it as a new request id
                    if i_rxByteValid = '1' then
                        o_requestId <= i_rxByte;
                        o_newHash <= '1';
                        r_state <= NextByte;
                        r_timer <= 0;
                    end if;

                when NextByte =>
                    -- We're in the middle of an existing hash and we just got a new byte of data
                    if i_rxByteValid = '1' and i_rxByte = 8x"FF" then
                        -- We have the next byte of our hash, but it's a control code. Switch to the control code state.
                        r_state <= ControlCode;
                        r_timer <= 0;
                    elsif i_rxByteValid = '1' then
                        -- We have the next byte of our hash, and it's a normal data byte
                        o_hashByteValid <= '1';
                        o_hashByte <= i_rxByte;
                        r_timer <= 0;
                    elsif r_timer = 65535 then
                        -- If the timer hits 255, we've timed out. Cancel this transmission and go back to the new hash state
                        r_state <= NewHash;
                        o_requestId <= (others => '0'); -- Zero out the request ID so that our 7 segment display shoes zeroes
                    else
                        r_timer <= r_timer + 1;
                    end if;    

                when ControlCode =>
                    -- We're in the middle of an existing hash and a control code has been entered. We're waiting for the next byte to see what control code it is
                    if i_rxByteValid = '1' and i_rxByte = 8x"00" then
                        -- Control code 0 == end hash
                        o_sendHash <= '1';
                        r_state <= NewHash;
                        r_timer <= 0;
                    elsif i_rxByteValid = '1' then
                        -- Any other control code just means to output the byte we just received as if it was a normal data byte.
                        -- It's intended to only be used with 8x"FF", but there's no reason to throw an error in other cases
                        o_hashByteValid <= '1';
                        o_hashByte <= i_rxByte;
                        r_state <= NextByte;
                        r_timer <= 0;
                    elsif r_timer = 65535 then
                        -- If the timer hits 255, we've timed out. Cancel this transmission and go back to the new hash state
                        r_state <= NewHash;
                        o_requestId <= (others => '0'); -- Zero out the request ID so that our 7 segment display shoes zeroes
                    else
                        r_timer <= r_timer + 1;
                    end if;    
            end case;
        end if;
    end process;
end only;
