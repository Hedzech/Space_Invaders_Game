library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity vga_sync is
   port(
      clk100: in std_logic;
      hsync, vsync: out std_logic;
      col,row:out unsigned(9 downto 0);
      video_on:buffer std_logic
);
end vga_sync;

architecture arch of vga_sync is

constant video_width: integer:=640; 
constant h_front_porch: integer:=16 ; 
constant h_back_porch: integer:=48 ; 
constant h_retrace: integer:=96 ; 
constant video_length: integer:=480; 
constant v_front_porch: integer:=10;  
constant v_back_porch: integer:=33;  
constant v_retrace: integer:=2;  

signal mod2_reg, mod2_next: std_logic;

signal row_previous, row_next: unsigned(9 downto 0);
signal col_previous, col_next: unsigned(9 downto 0);

signal v_sync_previous, h_sync_previous: std_logic;
signal v_sync_next, h_sync_next: std_logic;

signal h_end, v_end, pixel_tick: std_logic;
signal clock_refresher:unsigned(1 downto 0);
signal clk50:std_logic;

begin

process(clk100)
begin 
if rising_edge(clk100) then
    clock_refresher <= clock_refresher +1;
end if;
end process;

clk50 <= clock_refresher(0);

process (clk50)
begin
  if rising_edge(clk50) then
     mod2_reg <= mod2_next;
     row_previous <= row_next;
     col_previous <= col_next;
     v_sync_previous <= v_sync_next;
     h_sync_previous <= h_sync_next;
  end if;
end process;

mod2_next <= not mod2_reg;

pixel_tick <= '1' when mod2_reg='1' else '0';

h_end <= 
  '1' when col_previous=(video_width+h_front_porch+h_back_porch+h_retrace-1) else
  '0';
v_end <=  
  '1' when row_previous=(video_length+v_front_porch+v_back_porch+v_retrace-1) else 
  '0';

process (col_previous,h_end,pixel_tick)
begin
  if pixel_tick='1' then 
     if h_end='1' then
        col_next <= (others=>'0');
     else
        col_next <= col_previous + 1;
     end if;
  else
     col_next <= col_previous;
  end if;
end process;

process (row_previous,h_end,v_end,pixel_tick)
begin
  if pixel_tick='1' and h_end='1' then
     if (v_end='1') then
        row_next <= (others=>'0');
     else
        row_next <= row_previous + 1;
     end if;
  else
     row_next <= row_previous;
  end if;
end process;

h_sync_next <=
  '1' when (col_previous>=(video_width+h_front_porch))           
       and (col_previous<=(video_width+h_front_porch+h_retrace-1)) else 
  '0';
v_sync_next <=
  '1' when (row_previous>=(video_length+v_front_porch))           
       and (row_previous<=(video_length+v_front_porch+v_retrace-1)) else 
  '0';
  
video_on <=
  '1' when (col_previous<video_width) and (row_previous<video_length) else
  '0';

hsync <= h_sync_previous;
vsync <= v_sync_previous;
col <= col_previous;
row <= row_previous;
end arch;
