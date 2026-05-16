library ieee;
use ieee.std_logic_1164.all;

entity SevenSegmentHex is
    port(
        i_digit     : in std_logic_vector(3 downto 0);
        o_Segment_A : out std_logic;
        o_Segment_B : out std_logic;
        o_Segment_C : out std_logic;
        o_Segment_D : out std_logic;
        o_Segment_E : out std_logic;
        o_Segment_F : out std_logic;
        o_Segment_G : out std_logic
    );
end entity SevenSegmentHex;

architecture RTL of SevenSegmentHex is
begin
    process(i_digit)
        variable v_bitMask : std_logic_vector(6 downto 0);
    begin
        case i_digit is
            when "0000" =>
                v_bitMask := "1111110";
            when "0001" =>
                v_bitMask := "0110000";
            when "0010" =>
                v_bitMask := "1101101";
            when "0011" =>
                v_bitMask := "1111001";
            when "0100" =>
                v_bitMask := "0110011";
            when "0101" =>
                v_bitMask := "1011011";
            when "0110" =>
                v_bitMask := "1011111";
            when "0111" =>
                v_bitMask := "1110000";
            when "1000" =>
                v_bitMask := "1111111";
            when "1001" =>
                v_bitMask := "1111011";
            when "1010" =>
                v_bitMask := "1110111";
            when "1011" =>
                v_bitMask := "0011111";
            when "1100" =>
                v_bitMask := "1001110";
            when "1101" =>
                v_bitMask := "0111101";
            when "1110" =>
                v_bitMask := "1001111";
            when "1111" => 
                v_bitMask := "1000111";
            when others => 
                v_bitMask := (others => '0');
        end case;
        o_Segment_A <= not(v_bitMask(6));
        o_Segment_B <= not(v_bitMask(5));
        o_Segment_C <= not(v_bitMask(4));
        o_Segment_D <= not(v_bitMask(3));
        o_Segment_E <= not(v_bitMask(2));
        o_Segment_F <= not(v_bitMask(1));
        o_Segment_G <= not(v_bitMask(0));
    end process;
end architecture RTL;