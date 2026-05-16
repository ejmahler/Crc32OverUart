library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Fifo is
    generic(
        -- Depth will be 2**DEPTH_BITS, and the fifo will store 2**DEPTH_BITS - 1 elements
        DEPTH_BITS  : positive;

        -- Number of bits per entry
        WIDTH       : positive
    );
    port (
        i_clk       : in std_logic;

        -- AXI write handshake
        i_wrData    : in std_logic_vector(WIDTH-1 downto 0);    -- The element our owner wants to push onto the fifo. Only actually pushed when both i_wrData = '1' and o_wrReady = '1'
        i_wrValid   : in std_logic;                             -- 1 when i_wrData contains valid data to write to the fifo.
        o_wrReady   : out std_logic;                            -- When 1, we are ready for data to be pushed into the queue

        -- AXI read handshake
        o_rdData    : out std_logic_vector(WIDTH-1 downto 0);   -- The current element at the head of the queue. Only valid if o_rdValid is 1. Popped if both i_rdReady = '1' and o_rdValid = '1'
        o_rdValid   : out std_logic;                            -- 1 if o_rdData contains valid data, 0 otherwise
        i_rdReady   : in std_logic                              -- 1 instructs this instance to pop the head element off the queue.
    );
end Fifo;

architecture RTL of Fifo is
    constant DEPTH : positive := 2**DEPTH_BITS;

    type FifoStorage is array(0 to DEPTH - 1) of std_logic_vector(WIDTH-1 downto 0);
    signal r_storage : FifoStorage;
    attribute syn_ramstyle : string;
    attribute syn_ramstyle of r_storage : signal is "no_rw_check, blockram";

    -- Points to the oldest element
    signal r_tailIndex : unsigned(DEPTH_BITS-1 downto 0) := (others => '0');

    -- Points to the next free element. ie r_headIndex - 1 is the most recently pushed value
    signal r_headIndex : unsigned(DEPTH_BITS-1 downto 0) := (others => '0');
begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            -- Just unconditionally write. If our handshake isn't satisfied, the cell we're writing to will be overwritten when it eventually is satisfied.
            r_storage(to_integer(r_headIndex)) <= i_wrData;
            if i_wrValid = '1' and o_wrReady = '1' then
                r_headIndex <= r_headIndex + 1;
            end if;
            if o_rdValid = '1' and i_rdReady = '1' then
                r_tailIndex <= r_tailIndex + 1;
            end if;
          end if;
    end process;

    -- We're ready for a write whenever we're non-full
    o_wrReady <= '0' when (r_headIndex - r_tailIndex) = DEPTH - 1 else '1';

    -- The read is valid whenever we're non-empty
    o_rdValid <= '0' when (r_headIndex - r_tailIndex) = 0 else '1';

    -- Unconditionally read from storage, even if it's not valid
    o_rdData <= r_storage(to_integer(r_tailIndex));
end RTL;
