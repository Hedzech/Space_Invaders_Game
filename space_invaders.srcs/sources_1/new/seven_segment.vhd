library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity seven_segment is
port(clk100:in std_logic;
     displayed_number:in std_logic_vector(1 downto 0);
     anode_activate:out std_logic_vector(3 downto 0);
     led:out std_logic_vector(6 downto 0));
end seven_segment;

architecture Behavioral of seven_segment is

signal clk_counter:unsigned(19 downto 0):=(others => '0');
signal active:unsigned(1 downto 0);
signal number:unsigned(15 downto 0):=(others => '0');
signal display:std_logic_vector(1 downto 0);
begin

process(clk100)
begin
    if rising_edge(clk100) then
        clk_counter <= clk_counter + 1;
    end if;
end process;
active <= clk_counter(19 downto 18);

process(active)
begin
    case active is
        when "00" => 
        display <= "00";
        anode_activate <= "0111";
        when "01" =>
        display <= "00";
        anode_activate <= "1011";
        when "10" => 
        display <= "00";
        anode_activate <= "1101";
        when others => 
        display <= displayed_number;
        anode_activate <= "1110";
    end case;
end process;



process(display)
begin
    case display is
        when "00" => led <= "0000001";     
        when "01" => led <= "1001111"; 
        when "10" => led <= "0010010"; 
        when "11" => led <= "0000110";
    end case;
end process;
end Behavioral;
