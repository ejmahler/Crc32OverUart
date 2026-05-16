library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ComputeCrc32 is
    port (
        i_clk       : in std_logic;
        i_data      : in std_logic_vector(7 downto 0);
        i_dataValid : in std_logic; -- set to 1 to add the given data to the hash, 0 to leave the hash untouched
        i_newHash   : in std_logic; -- set to 1 and we'll start a new hash, 0 to continue the previous hash
        o_hash      : out std_logic_vector(31 downto 0)
    );
end ComputeCrc32;

architecture RTL of ComputeCrc32 is
    -- Polynomial: 0x1EDC6F41, slicing by 4 bits instead of the usual 8 bits
    type CrcTable is array(0 to 15) of std_logic_vector(31 downto 0);
    constant crc_table0 : CrcTable := (
        32x"00000000", 32x"105ec76f", 32x"20bd8ede", 32x"30e349b1", 32x"417b1dbc", 32x"5125dad3", 32x"61c69362", 32x"7198540d",
        32x"82f63b78", 32x"92a8fc17", 32x"a24bb5a6", 32x"b21572c9", 32x"c38d26c4", 32x"d3d3e1ab", 32x"e330a81a", 32x"f36e6f75"
    );
    constant crc_table1 : CrcTable := (
        32x"00000000", 32x"f26b8303", 32x"e13b70f7", 32x"1350f3f4", 32x"c79a971f", 32x"35f1141c", 32x"26a1e7e8", 32x"d4ca64eb",
        32x"8ad958cf", 32x"78b2dbcc", 32x"6be22838", 32x"9989ab3b", 32x"4d43cfd0", 32x"bf284cd3", 32x"ac78bf27", 32x"5e133c24"
    );
    signal r_state: std_logic_vector(31 downto 0) := 32x"ffffffff";

begin
    process(i_clk)
        variable v_startState : std_logic_vector(31 downto 0);
        variable v_mutatedState : std_logic_vector(7 downto 0);
    begin
        if rising_edge(i_clk) then
            if i_dataValid = '1' then
                -- If a new hash was requested, use a blank state as our start state
                if i_newHash = '1' then
                    v_startState := 32x"ffffffff";
                else
                    v_startState := r_state;
                end if;

                v_mutatedState := v_startState(7 downto 0) xor i_data;

                r_state <= (8x"00" & v_startState(31 downto 8)) 
                    xor crc_table0(to_integer(unsigned(v_mutatedState(7 downto 4)))) 
                    xor crc_table1(to_integer(unsigned(v_mutatedState(3 downto 0))));
            elsif i_newHash = '1' then
                r_state <= 32x"ffffffff";
            end if;
        end if;
    end process;

    o_hash <= not r_state;
end RTL;
