library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity game is
    port(clk100:in std_logic;
        BRight,BLeft,BFire,SStart,SReset:in std_logic;
        hsync,vsync:out std_logic;
        anode_activate:out std_logic_vector(3 downto 0);
        led:out std_logic_vector(6 downto 0);
        red:out std_logic_vector(3 downto 0);
        blue:out std_logic_vector(3 downto 0);
        green:out std_logic_vector(3 downto 0)
);       
end game;

architecture Behavioral of game is
component vga_sync is
port(clk100: in std_logic;
      hsync, vsync: out std_logic;
      col,row:out unsigned(9 downto 0);
      video_on:buffer std_logic
);
end component;

component seven_segment is
port(clk100:in std_logic;
     displayed_number:in std_logic_vector(1 downto 0);
     anode_activate:out std_logic_vector(3 downto 0);
     led:out std_logic_vector(6 downto 0));
end component;

signal game_start:std_logic:='0';
signal game_playing:std_logic;
signal game_over:std_logic:='0';
signal game_lost:std_logic:='0';

signal ship_x:unsigned(9 downto 0):=to_unsigned(320,10);
signal fire:std_logic;
signal enemy_right:std_logic:='1';
signal enemy_left:std_logic:='0';
signal collide1:std_logic;
signal collide2:std_logic;
signal collide3:std_logic;
signal crash1:std_logic:='0';
signal crash2:std_logic:='0';
signal crash3:std_logic:='0';

signal enemy1_x:unsigned(9 downto 0):=to_unsigned(320,10);
signal enemy1_y:unsigned(9 downto 0):=to_unsigned(40,10);
signal enemy1_dead:std_logic:='0';

signal enemy2_x:unsigned(9 downto 0):=to_unsigned(470,10);
signal enemy2_y:unsigned(9 downto 0):=to_unsigned(40,10);
signal enemy2_dead:std_logic:='0';

signal enemy3_x:unsigned(9 downto 0):=to_unsigned(170,10);
signal enemy3_y:unsigned(9 downto 0):=to_unsigned(40,10);
signal enemy3_dead:std_logic:='0';

signal ammo_x:unsigned(9 downto 0):=to_unsigned(700,10);
signal ammo_y:unsigned(9 downto 0):=to_unsigned(415,10);

signal col:unsigned(9 downto 0);
signal row:unsigned(9 downto 0);
signal h,v:std_logic;
signal active:std_logic;

signal clock_refresher:unsigned(25 downto 0);
signal clk1:std_logic;
signal clk2:std_logic;
signal clk3:std_logic;

signal enemy1_show:std_logic;
signal enemy2_show:std_logic;
signal enemy3_show:std_logic;
signal ship_show:std_logic;
signal ammo_show:std_logic;
signal show:std_logic;
signal score:std_logic_vector(1 downto 0);

signal anode:std_logic_vector(3 downto 0);
signal wled:std_logic_vector(6 downto 0);

signal r:std_logic_vector(3 downto 0);
signal b:std_logic_vector(3 downto 0);
signal g:std_logic_vector(3 downto 0);
signal game_over_screen:std_logic;
signal game_lost_screen:std_logic;
signal entry_screen:std_logic;

begin

stage1:vga_sync port map(clk100,h,v,col,row,active);
ssdisplay:seven_segment port map(clk100,score,anode,wled);

process(clk100)
begin
    if rising_edge(clk100) then
        clock_refresher <= clock_refresher + 1;
    end if;
end process;
clk1 <= clock_refresher(17);
clk2 <= clock_refresher(22);
clk3 <= clock_refresher(21);
------------------------------------------
--states
process(SStart,clk100)
begin
    if rising_edge(clk100) and SStart = '1' then
        game_start <= '1';
    end if;
end process;

game_lost <= crash1 or crash2 or crash3;

game_over <= enemy1_dead and enemy2_dead and enemy3_dead;
------------------------------------------
--ship
process(clk1)
begin
    if rising_edge(clk1) and game_start = '1' and game_over = '0' and game_lost = '0' then
        if SReset = '0' then
            if (ship_x <= to_unsigned(640,10)) or (ship_x >= to_unsigned(10,10)) then
                if BRight='1' and BLeft='0' then
                    ship_x <= ship_x + 1;
                elsif Bright='0' and BLeft='1' then
                    ship_x <= ship_x - 1;
                end if;
            else
                ship_x <= (others => '0');
            end if; 
         elsif SReset = '1' then 
            ship_x <= to_unsigned(320,10);
         end if;
    end if;
end process;
------------------------------------------------
--ammo
process(clk1,fire)
begin
    if rising_edge(clk1) and game_start = '1' and game_over = '0' and game_lost = '0' then
        if SReset = '0' then
            if fire = '1' then
                ammo_y <= ammo_y - 1;
            elsif fire = '0' then
                ammo_y <= to_unsigned(415,10);
            end if;
        elsif SReset = '1' then
            ammo_y <= to_unsigned(415,10);
        end if;
    end if;
end process;

process(BFire)
begin
    if game_start = '1' and game_over = '0' and game_lost = '0' then
        if SReset = '0' then 
            if BFire='1' or ammo_y /= to_unsigned(415,10) then
                    if to_integer(ammo_y)<=415 and to_integer(ammo_y)>0 and collide1 = '0' and collide2 = '0' and collide3 = '0' then
                        fire <= '1';
                    else
                        fire <= '0';
                    end if;
            elsif (BFire='0' and ammo_y = to_unsigned(415,10)) or (collide1 = '1') or (collide2 = '1') or (collide3 = '1')  then
                    ammo_x <= ship_x;
                    fire <= '0';
            end if;
        elsif SReset = '1' then
            ammo_x <= ship_x;
            fire <= '0';
        end if;
    end if;
end process;

------------------------------
--enemies
process(clk2)
begin
    if rising_edge(clk2) then
        if game_start = '1' and game_over = '0' then
            if SReset = '0' then
                if enemy1_dead = '0' then
                    if to_integer(enemy1_y) <= 415 then 
                        enemy1_y <= enemy1_y + 1;
                    else
                        crash1 <= '1';
                    end if;
                else
                    enemy1_y <= to_unsigned(500,10);
                end if;
            elsif SReset = '1' then
                enemy1_y <= to_unsigned(40,10);
                crash1 <= '0';
            end if;
        end if;
    end if;
end process;

process(clk2)
begin
    if rising_edge(clk2) then
        if game_start = '1' and game_over = '0' then
            if SReset = '0' then
                if enemy2_dead = '0' then
                    if to_integer(enemy2_y) <= 415 then 
                        enemy2_y <= enemy2_y + 1;
                    else
                        crash2 <= '1';
                    end if;
                else
                    enemy2_y <= to_unsigned(500,10);
                end if;
            elsif SReset = '1' then
                enemy2_y <= to_unsigned(40,10);
                crash2 <= '0';
            end if;
        end if;
    end if;
end process;

process(clk2)
begin
    if rising_edge(clk2) then
        if game_start = '1' and game_over = '0' then
            if SReset = '0' then
                if enemy3_dead = '0' then
                    if to_integer(enemy3_y) <= 415 then 
                        enemy3_y <= enemy3_y + 1;
                    else
                        crash3 <= '1';
                    end if;
                else
                    enemy3_y <= to_unsigned(500,10);
                end if;
            elsif SReset = '1' then
                enemy3_y <= to_unsigned(40,10);
                crash3 <= '0';
            end if;
        end if;
    end if;
end process;

process(clk100)
begin
    if rising_edge(clk100) then
        if to_integer(enemy1_x) = 607 or to_integer(enemy2_x) = 607 or to_integer(enemy3_x) = 607 then
            enemy_right <= '0';
            enemy_left <= '1';
        elsif to_integer(enemy1_x) = 33 or to_integer(enemy2_x) = 33 or to_integer(enemy3_x) = 33 then
            enemy_right <= '1';
            enemy_left <= '0';
        end if;
    end if;
end process;

process(clk3)
begin
    if rising_edge(clk3) and game_start = '1' and game_over = '0' and game_lost = '0' then
        if SReset = '0' then
            if enemy1_dead = '0' then
                if enemy_right = '1' then
                    enemy1_x <= enemy1_x + 1;
                elsif enemy_left = '1' then
                    enemy1_x <= enemy1_x -1;
                end if;
             else
                enemy1_x <= to_unsigned(700,10);
             end if;
        elsif SReset = '1' then
            enemy1_x <= to_unsigned(320,10);
        end if;
    end if;
end process;

process(clk3)
begin
    if rising_edge(clk3) and game_start = '1' and game_over = '0' and game_lost = '0' then
        if SReset = '0' then
            if enemy2_dead = '0' then
                if enemy_right = '1' then
                    enemy2_x <= enemy2_x + 1;
                elsif enemy_left = '1' then
                    enemy2_x <= enemy2_x -1;
                end if;
             else
                enemy2_x <= to_unsigned(700,10);
             end if;
        elsif SReset = '1' then
            enemy2_x <= to_unsigned(420,10);
        end if;
    end if;
end process;

process(clk3)
begin
    if rising_edge(clk3) and game_start = '1' and game_over = '0' and game_lost = '0' then
        if SReset = '0' then
            if enemy3_dead = '0' then
                if enemy_right = '1' then
                    enemy3_x <= enemy3_x + 1;
                elsif enemy_left = '1' then
                    enemy3_x <= enemy3_x -1;
                end if;
             else
                enemy3_x <= to_unsigned(700,10);
             end if;
        elsif SReset = '1' then
            enemy3_x <= to_unsigned(220,10);
        end if;
    end if;
end process;


------------------------------
--collision
process(clk100)
begin
    if rising_edge(clk100) then 
        if game_start = '1' and game_over = '0' and SReset = '0' and game_lost = '0' then
            if (to_integer(ammo_y) + 3 = to_integer(enemy1_y) - 16 and to_integer(enemy1_y)/=40 ) or
            (to_integer(ammo_y) + 3 = to_integer(enemy2_y) - 16 and to_integer(enemy2_y)/=40 ) or
            (to_integer(ammo_y) + 3 = to_integer(enemy3_y) - 16 and to_integer(enemy3_y)/=40 ) then
                if (to_integer(ammo_x) + 3 <= to_integer(enemy1_x) + 22) and 
                (to_integer(ammo_x) - 3 >= to_integer(enemy1_x) - 22) and 
                fire = '1' then
                    collide1 <= '1';
                    enemy1_dead <= '1';
                elsif (to_integer(ammo_x) + 3 <= to_integer(enemy2_x) + 22) and 
                (to_integer(ammo_x) - 3 >= to_integer(enemy2_x) - 22) and 
                fire = '1' then
                    collide2 <= '1';
                    enemy2_dead <= '1';
                elsif (to_integer(ammo_x) + 3 <= to_integer(enemy3_x) + 22) and 
                (to_integer(ammo_x) - 3 >= to_integer(enemy3_x) - 22) and 
                fire = '1' then
                    collide3 <= '1';
                    enemy3_dead <= '1';
                else
                    collide1 <= '0';
                    collide2 <= '0';
                    collide3 <= '0';
                end if;
             end if;
        elsif SReset = '1' then
            collide1 <= '0';
            collide2 <= '0';
            collide3 <= '0';
            enemy1_dead <= '0';
            enemy2_dead <= '0';
            enemy3_dead <= '0';
        end if;
    end if;
end process;
-------------------------------
---score
score(1) <= (enemy1_dead and enemy2_dead) or (enemy1_dead and enemy3_dead) or (enemy2_dead and enemy3_dead);
score(0) <= enemy1_dead xor enemy2_dead xor enemy3_dead;

-------------------------------
---ship
process(col,row,clk100)
begin
    if rising_edge(clk100) then
        if(to_integer(col)<=640 and to_integer(col)>= 0  and to_integer(row)<=480 and to_integer(row)>= 0) then
            ----ship
            if to_integer(row) <= 435 and to_integer(row) >= 425 then
                if to_integer(col) >= to_integer(ship_x)-20 and to_integer(col) <= to_integer(ship_x)+20 then
                    ship_show <= '1';
                else
                    ship_show <= '0';
                end if; 
            elsif to_integer(row) <= 425 and to_integer(row) >= 415 then
                if to_integer(col) >= to_integer(ship_x)-5 and to_integer(col) <= to_integer(ship_x)+5 then
                    ship_show <= '1';
                else
                    ship_show <= '0';
                end if;
            end if;
        else
            ship_show <= '0';
        end if;
    end if;
end process;
---ammo
process(col,row,clk100)
begin  
    if rising_edge(clk100) then
        if(to_integer(col)<=640 and to_integer(col)>= 0  and to_integer(row)<=480 and to_integer(row)>= 0) then
            if to_integer(ammo_y) + 3 >= to_integer(row) and to_integer(ammo_y) - 3 <= to_integer(row) then
                if to_integer(ammo_x) - 3 <= to_integer(col) and to_integer(ammo_x) + 3 >= to_integer(col) then
                    ammo_show <= '1';
                else
                    ammo_show <= '0';
                end if;
            end if;
        else
            ammo_show <= '0';
        end if;
    end if;
end process;
---enemy1
process(col,row,clk100)
begin
    if rising_edge(clk100) then
        if(to_integer(col)<=640 and to_integer(col)>= 0  and to_integer(row)<=480 and to_integer(row)>= 0) and enemy1_dead = '0' then
                if(to_integer(row) < to_integer(enemy1_y) + 16 and to_integer(row) > to_integer(enemy1_y) - 16) then
                    if (to_integer(row) <= to_integer(enemy1_y) + 16 and to_integer(row) > to_integer(enemy1_y) + 12) then
                        if (to_integer(col) >= to_integer(enemy1_x) - 22 and to_integer(col) < to_integer(enemy1_x) - 18) or
                           (to_integer(col) >= to_integer(enemy1_x) - 10 and to_integer(col) < to_integer(enemy1_x) - 2)  or
                           (to_integer(col) > to_integer(enemy1_x) + 2 and to_integer(col) <= to_integer(enemy1_x) + 10)  or
                           (to_integer(col) > to_integer(enemy1_x) + 18 and to_integer(col) <= to_integer(enemy1_x) + 22) then
                            enemy1_show <= '1';
                        else
                            enemy1_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy1_y) + 12 and to_integer(row) > to_integer(enemy1_y) + 8) then
                        if (to_integer(col) >= to_integer(enemy1_x) - 22 and to_integer(col) < to_integer(enemy1_x) - 18) or
                           (to_integer(col) >= to_integer(enemy1_x) - 14 and to_integer(col) < to_integer(enemy1_x) - 10)  or
                           (to_integer(col) > to_integer(enemy1_x) + 10 and to_integer(col) <= to_integer(enemy1_x) + 14)  or
                           (to_integer(col) > to_integer(enemy1_x) + 18 and to_integer(col) <= to_integer(enemy1_x) + 22) then
                            enemy1_show <= '1';
                        else
                            enemy1_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy1_y) + 8 and to_integer(row) > to_integer(enemy1_y) + 4) then
                        if (to_integer(col) >= to_integer(enemy1_x) - 22 and to_integer(col) < to_integer(enemy1_x) - 18) or
                           (to_integer(col) >= to_integer(enemy1_x) - 14 and to_integer(col) <= to_integer(enemy1_x) + 14)  or
                           (to_integer(col) > to_integer(enemy1_x) + 18 and to_integer(col) <= to_integer(enemy1_x) + 22) then
                            enemy1_show <= '1';
                        else
                            enemy1_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy1_y) + 4 and to_integer(row) > to_integer(enemy1_y)) then
                        if (to_integer(col) >= to_integer(enemy1_x) - 22 and to_integer(col) <= to_integer(enemy1_x) + 22) then
                            enemy1_show <= '1';
                        else
                            enemy1_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy1_y) and to_integer(row) > to_integer(enemy1_y) - 4) then
                        if (to_integer(col) >= to_integer(enemy1_x) - 18 and to_integer(col) < to_integer(enemy1_x) - 10) or
                           (to_integer(col) >= to_integer(enemy1_x) - 6 and to_integer(col) < to_integer(enemy1_x) + 6)  or
                           (to_integer(col) > to_integer(enemy1_x) + 10 and to_integer(col) <= to_integer(enemy1_x) + 18)  then
                            enemy1_show <= '1';
                        else
                            enemy1_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy1_y) - 4 and to_integer(row) > to_integer(enemy1_y) - 8) then
                        if (to_integer(col) >= to_integer(enemy1_x) - 14 and to_integer(col) <= to_integer(enemy1_x) + 14) then
                            enemy1_show <= '1';
                        else
                            enemy1_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy1_y) - 8 and to_integer(row) > to_integer(enemy1_y) - 12) then
                        if (to_integer(col) >= to_integer(enemy1_x) - 10 and to_integer(col) < to_integer(enemy1_x) - 6) or
                           (to_integer(col) > to_integer(enemy1_x) + 6 and to_integer(col) <= to_integer(enemy1_x) + 10) then
                            enemy1_show <= '1';
                        else
                            enemy1_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy1_y) - 12 and to_integer(row) > to_integer(enemy1_y) - 16) then
                        if (to_integer(col) >= to_integer(enemy1_x) - 14 and to_integer(col) < to_integer(enemy1_x) - 10) or
                           (to_integer(col) > to_integer(enemy1_x) + 10 and to_integer(col) <= to_integer(enemy1_x) + 14) then
                            enemy1_show <= '1';
                        else
                            enemy1_show <= '0';
                        end if; 
                    end if;
                end if;
        else
            enemy1_show <= '0';
        end if;
    end if;
end process;
---enemy2
process(col,row,clk100)
begin
    if rising_edge(clk100) then
        if(to_integer(col)<=640 and to_integer(col)>= 0  and to_integer(row)<=480 and to_integer(row)>= 0) and enemy2_dead = '0' then
                if(to_integer(row) < to_integer(enemy2_y) + 16 and to_integer(row) > to_integer(enemy2_y) - 16) then
                    if (to_integer(row) <= to_integer(enemy2_y) + 16 and to_integer(row) > to_integer(enemy2_y) + 12) then
                        if (to_integer(col) >= to_integer(enemy2_x) - 22 and to_integer(col) < to_integer(enemy2_x) - 18) or
                           (to_integer(col) >= to_integer(enemy2_x) - 10 and to_integer(col) < to_integer(enemy2_x) - 2)  or
                           (to_integer(col) > to_integer(enemy2_x) + 2 and to_integer(col) <= to_integer(enemy2_x) + 10)  or
                           (to_integer(col) > to_integer(enemy2_x) + 18 and to_integer(col) <= to_integer(enemy2_x) + 22) then
                            enemy2_show <= '1';
                        else
                            enemy2_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy2_y) + 12 and to_integer(row) > to_integer(enemy2_y) + 8) then
                        if (to_integer(col) >= to_integer(enemy2_x) - 22 and to_integer(col) < to_integer(enemy2_x) - 18) or
                           (to_integer(col) >= to_integer(enemy2_x) - 14 and to_integer(col) < to_integer(enemy2_x) - 10)  or
                           (to_integer(col) > to_integer(enemy2_x) + 10 and to_integer(col) <= to_integer(enemy2_x) + 14)  or
                           (to_integer(col) > to_integer(enemy2_x) + 18 and to_integer(col) <= to_integer(enemy2_x) + 22) then
                            enemy2_show <= '1';
                        else
                            enemy2_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy2_y) + 8 and to_integer(row) > to_integer(enemy2_y) + 4) then
                        if (to_integer(col) >= to_integer(enemy2_x) - 22 and to_integer(col) < to_integer(enemy2_x) - 18) or
                           (to_integer(col) >= to_integer(enemy2_x) - 14 and to_integer(col) <= to_integer(enemy2_x) + 14)  or
                           (to_integer(col) > to_integer(enemy2_x) + 18 and to_integer(col) <= to_integer(enemy2_x) + 22) then
                            enemy2_show <= '1';
                        else
                            enemy2_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy2_y) + 4 and to_integer(row) > to_integer(enemy2_y)) then
                        if (to_integer(col) >= to_integer(enemy2_x) - 22 and to_integer(col) <= to_integer(enemy2_x) + 22) then
                            enemy2_show <= '1';
                        else
                            enemy2_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy2_y) and to_integer(row) > to_integer(enemy2_y) - 4) then
                        if (to_integer(col) >= to_integer(enemy2_x) - 18 and to_integer(col) < to_integer(enemy2_x) - 10) or
                           (to_integer(col) >= to_integer(enemy2_x) - 6 and to_integer(col) < to_integer(enemy2_x) + 6)  or
                           (to_integer(col) > to_integer(enemy2_x) + 10 and to_integer(col) <= to_integer(enemy2_x) + 18)  then
                            enemy2_show <= '1';
                        else
                            enemy2_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy2_y) - 4 and to_integer(row) > to_integer(enemy2_y) - 8) then
                        if (to_integer(col) >= to_integer(enemy2_x) - 14 and to_integer(col) <= to_integer(enemy2_x) + 14) then
                            enemy2_show <= '1';
                        else
                            enemy2_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy2_y) - 8 and to_integer(row) > to_integer(enemy2_y) - 12) then
                        if (to_integer(col) >= to_integer(enemy2_x) - 10 and to_integer(col) < to_integer(enemy2_x) - 6) or
                           (to_integer(col) > to_integer(enemy2_x) + 6 and to_integer(col) <= to_integer(enemy2_x) + 10) then
                            enemy2_show <= '1';
                        else
                            enemy2_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy2_y) - 12 and to_integer(row) > to_integer(enemy2_y) - 16) then
                        if (to_integer(col) >= to_integer(enemy2_x) - 14 and to_integer(col) < to_integer(enemy2_x) - 10) or
                           (to_integer(col) > to_integer(enemy2_x) + 10 and to_integer(col) <= to_integer(enemy2_x) + 14) then
                            enemy2_show <= '1';
                        else
                            enemy2_show <= '0';
                        end if; 
                    end if;
                end if;
        else
            enemy2_show <= '0';
        end if;
    end if;
end process;
---enemy3
process(col,row,clk100)
begin
    if rising_edge(clk100) then
        if(to_integer(col)<=640 and to_integer(col)>= 0  and to_integer(row)<=480 and to_integer(row)>= 0) and enemy3_dead = '0'then
                if(to_integer(row) < to_integer(enemy3_y) + 16 and to_integer(row) > to_integer(enemy3_y) - 16) then
                    if (to_integer(row) <= to_integer(enemy3_y) + 16 and to_integer(row) > to_integer(enemy3_y) + 12) then
                        if (to_integer(col) >= to_integer(enemy3_x) - 22 and to_integer(col) < to_integer(enemy3_x) - 18) or
                           (to_integer(col) >= to_integer(enemy3_x) - 10 and to_integer(col) < to_integer(enemy3_x) - 2)  or
                           (to_integer(col) > to_integer(enemy3_x) + 2 and to_integer(col) <= to_integer(enemy3_x) + 10)  or
                           (to_integer(col) > to_integer(enemy3_x) + 18 and to_integer(col) <= to_integer(enemy3_x) + 22) then
                            enemy3_show <= '1';
                        else
                            enemy3_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy3_y) + 12 and to_integer(row) > to_integer(enemy3_y) + 8) then
                        if (to_integer(col) >= to_integer(enemy3_x) - 22 and to_integer(col) < to_integer(enemy3_x) - 18) or
                           (to_integer(col) >= to_integer(enemy3_x) - 14 and to_integer(col) < to_integer(enemy3_x) - 10)  or
                           (to_integer(col) > to_integer(enemy3_x) + 10 and to_integer(col) <= to_integer(enemy3_x) + 14)  or
                           (to_integer(col) > to_integer(enemy3_x) + 18 and to_integer(col) <= to_integer(enemy3_x) + 22) then
                            enemy3_show <= '1';
                        else
                            enemy3_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy3_y) + 8 and to_integer(row) > to_integer(enemy3_y) + 4) then
                        if (to_integer(col) >= to_integer(enemy3_x) - 22 and to_integer(col) < to_integer(enemy3_x) - 18) or
                           (to_integer(col) >= to_integer(enemy3_x) - 14 and to_integer(col) <= to_integer(enemy3_x) + 14)  or
                           (to_integer(col) > to_integer(enemy3_x) + 18 and to_integer(col) <= to_integer(enemy3_x) + 22) then
                            enemy3_show <= '1';
                        else
                            enemy3_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy3_y) + 4 and to_integer(row) > to_integer(enemy3_y)) then
                        if (to_integer(col) >= to_integer(enemy3_x) - 22 and to_integer(col) <= to_integer(enemy3_x) + 22) then
                            enemy3_show <= '1';
                        else
                            enemy3_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy3_y) and to_integer(row) > to_integer(enemy3_y) - 4) then
                        if (to_integer(col) >= to_integer(enemy3_x) - 18 and to_integer(col) < to_integer(enemy3_x) - 10) or
                           (to_integer(col) >= to_integer(enemy3_x) - 6 and to_integer(col) < to_integer(enemy3_x) + 6)  or
                           (to_integer(col) > to_integer(enemy3_x) + 10 and to_integer(col) <= to_integer(enemy3_x) + 18)  then
                            enemy3_show <= '1';
                        else
                            enemy3_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy3_y) - 4 and to_integer(row) > to_integer(enemy3_y) - 8) then
                        if (to_integer(col) >= to_integer(enemy3_x) - 14 and to_integer(col) <= to_integer(enemy3_x) + 14) then
                            enemy3_show <= '1';
                        else
                            enemy3_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy3_y) - 8 and to_integer(row) > to_integer(enemy3_y) - 12) then
                        if (to_integer(col) >= to_integer(enemy3_x) - 10 and to_integer(col) < to_integer(enemy3_x) - 6) or
                           (to_integer(col) > to_integer(enemy3_x) + 6 and to_integer(col) <= to_integer(enemy3_x) + 10) then
                            enemy3_show <= '1';
                        else
                            enemy3_show <= '0';
                        end if;
                    elsif (to_integer(row) <= to_integer(enemy3_y) - 12 and to_integer(row) > to_integer(enemy3_y) - 16) then
                        if (to_integer(col) >= to_integer(enemy3_x) - 14 and to_integer(col) < to_integer(enemy3_x) - 10) or
                           (to_integer(col) > to_integer(enemy3_x) + 10 and to_integer(col) <= to_integer(enemy3_x) + 14) then
                            enemy3_show <= '1';
                        else
                            enemy3_show <= '0';
                        end if; 
                    end if;
                end if;
        else
            enemy3_show <= '0';
        end if;
    end if;
end process;   
---------------------------------------
---entry_screen
process(col,row,clk100)
begin
    if rising_edge(clk100) then
        if(to_integer(col)<=640 and to_integer(col)>= 0  and to_integer(row)<=480 and to_integer(row)>= 0) then
            ----ship
            if(to_integer(row) < 240 + 160 and to_integer(row) > 240 - 160) then
                    if (to_integer(row) <= 240 + 160 and to_integer(row) > 240 + 120) then
                        if (to_integer(col) >= 320 - 220 and to_integer(col) < 320 - 180) or
                           (to_integer(col) >= 320 - 100 and to_integer(col) < 320 - 20)  or
                           (to_integer(col) > 320 + 20 and to_integer(col) <= 320 + 100)  or
                           (to_integer(col) > 320 + 180 and to_integer(col) <= 320 + 220) then
                            entry_screen <= '1';
                        else
                            entry_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 + 120 and to_integer(row) > 240 + 80) then
                        if (to_integer(col) >= 320 - 220 and to_integer(col) < 320 - 180) or
                           (to_integer(col) >= 320 - 140 and to_integer(col) < 320 - 100)  or
                           (to_integer(col) > 320 + 100 and to_integer(col) <= 320 + 140)  or
                           (to_integer(col) > 320 + 180 and to_integer(col) <= 320 + 220) then
                            entry_screen <= '1';
                        else
                            entry_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 + 80 and to_integer(row) > 240 + 40) then
                        if (to_integer(col) >= 320 - 220 and to_integer(col) < 320 - 180) or
                           (to_integer(col) >= 320 - 140 and to_integer(col) <= 320 + 140)  or
                           (to_integer(col) > 320 + 180 and to_integer(col) <= 320 + 220) then
                            entry_screen <= '1';
                        else
                            entry_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 + 40 and to_integer(row) > 240) then
                        if (to_integer(col) >= 320 - 220 and to_integer(col) <= 320 + 220) then
                            entry_screen <= '1';
                        else
                            entry_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 and to_integer(row) > 240 - 40) then
                        if (to_integer(col) >= 320 - 180 and to_integer(col) < 320 - 100) or
                           (to_integer(col) >= 320 - 60 and to_integer(col) < 320 + 60)  or
                           (to_integer(col) > 320 + 100 and to_integer(col) <= 320 + 180)  then
                            entry_screen <= '1';
                        else
                            entry_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 - 40 and to_integer(row) > 240 - 80) then
                        if (to_integer(col) >= 320 - 140 and to_integer(col) <= 320 + 140) then
                            entry_screen <= '1';
                        else
                            entry_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 - 80 and to_integer(row) > 240 - 120) then
                        if (to_integer(col) >= 320 - 100 and to_integer(col) < 320 - 60) or
                           (to_integer(col) > 320 + 60 and to_integer(col) <= 320 + 100) then
                            entry_screen <= '1';
                        else
                            entry_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 - 120 and to_integer(row) > 240 - 160) then
                        if (to_integer(col) >= 320 - 140 and to_integer(col) < 320 - 100) or
                           (to_integer(col) > 320 + 100 and to_integer(col) <= 320 + 140) then
                            entry_screen <= '1';
                        else
                            entry_screen <= '0';
                        end if; 
                    end if;
            end if;
        else
            entry_screen <= '0';
        end if;
    end if;
end process;
---game_over='1'
process(col,row,clk100)
begin
    if rising_edge(clk100) then
        if(to_integer(col)<=640 and to_integer(col)>= 0  and to_integer(row)<=480 and to_integer(row)>= 0) then
            if to_integer(row) <= 320 and to_integer(row) >= 240 then
                if to_integer(col) >= 160 and to_integer(col) <= 480 then
                    game_over_screen <= '1';
                else
                    game_over_screen <= '0';
                end if; 
            elsif to_integer(row) <= 240 and to_integer(row) >= 180 then
                if to_integer(col) >= 260 and to_integer(col) <= 380 then
                    game_over_screen <= '1';
                else
                    game_over_screen <= '0';
                end if;
            elsif to_integer(row) <= 180 and to_integer(row) >= 160 then
                if to_integer(col) >= 300 and to_integer(col) <= 340 then
                    game_over_screen <= '1';
                else
                    game_over_screen <= '0';
                end if;
            end if;
        else
            game_over_screen <= '0';
        end if;
    end if;
end process;
---game_lost='1'
process(col,row,clk100)
begin
    if rising_edge(clk100) then
        if(to_integer(col)<=640 and to_integer(col)>= 0  and to_integer(row)<=480 and to_integer(row)>= 0) then
                if(to_integer(row) < 240 + 160 and to_integer(row) > 240 - 160) then
                    if (to_integer(row) <= 240 + 160 and to_integer(row) > 240 + 120) then
                        if (to_integer(col) >= 320 - 220 and to_integer(col) < 320 - 180) or
                           (to_integer(col) >= 320 - 100 and to_integer(col) < 320 - 20)  or
                           (to_integer(col) > 320 + 20 and to_integer(col) <= 320 + 100)  or
                           (to_integer(col) > 320 + 180 and to_integer(col) <= 320 + 220) then
                            game_lost_screen <= '1';
                        else
                            game_lost_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 + 120 and to_integer(row) > 240 + 80) then
                        if (to_integer(col) >= 320 - 220 and to_integer(col) < 320 - 180) or
                           (to_integer(col) >= 320 - 140 and to_integer(col) < 320 - 100)  or
                           (to_integer(col) > 320 + 100 and to_integer(col) <= 320 + 140)  or
                           (to_integer(col) > 320 + 180 and to_integer(col) <= 320 + 220) then
                            game_lost_screen <= '1';
                        else
                            game_lost_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 + 80 and to_integer(row) > 240 + 40) then
                        if (to_integer(col) >= 320 - 220 and to_integer(col) < 320 - 180) or
                           (to_integer(col) >= 320 - 140 and to_integer(col) <= 320 + 140)  or
                           (to_integer(col) > 320 + 180 and to_integer(col) <= 320 + 220) then
                            game_lost_screen <= '1';
                        else
                            game_lost_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 + 40 and to_integer(row) > 240) then
                        if (to_integer(col) >= 320 - 220 and to_integer(col) <= 320 + 220) then
                            game_lost_screen <= '1';
                        else
                            game_lost_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 and to_integer(row) > 240 - 40) then
                        if (to_integer(col) >= 320 - 180 and to_integer(col) < 320 - 100) or
                           (to_integer(col) >= 320 - 60 and to_integer(col) < 320 + 60)  or
                           (to_integer(col) > 320 + 100 and to_integer(col) <= 320 + 180)  then
                            game_lost_screen <= '1';
                        else
                            game_lost_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 - 40 and to_integer(row) > 240 - 80) then
                        if (to_integer(col) >= 320 - 140 and to_integer(col) <= 320 + 140) then
                            game_lost_screen <= '1';
                        else
                            game_lost_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 - 80 and to_integer(row) > 240 - 120) then
                        if (to_integer(col) >= 320 - 100 and to_integer(col) < 320 - 60) or
                           (to_integer(col) > 320 + 60 and to_integer(col) <= 320 + 100) then
                            game_lost_screen <= '1';
                        else
                            game_lost_screen <= '0';
                        end if;
                    elsif (to_integer(row) <= 240 - 120 and to_integer(row) > 240 - 160) then
                        if (to_integer(col) >= 320 - 140 and to_integer(col) < 320 - 100) or
                           (to_integer(col) > 320 + 100 and to_integer(col) <= 320 + 140) then
                            game_lost_screen <= '1';
                        else
                            game_lost_screen <= '0';
                        end if; 
                    end if;
                end if;
        else
            game_lost_screen <= '0';
        end if;
    end if;
end process;   
-----------------------------------------------
process(game_over,game_lost,game_start)
begin
    if game_start = '0' then
        show <= entry_screen;
    elsif game_over = '0' and game_lost = '0' then
        show <= ship_show or ammo_show or enemy1_show or enemy2_show or enemy3_show; 
    elsif game_over = '1' then
        show <= game_over_screen;
    elsif game_lost = '1' then
        show <= game_lost_screen;    
   end if;
end process;
red <= (active & active & active & active ) and (show & show & show & show ) and ((not game_over) & (not game_over) & (not game_over) & (not game_over));
blue <= (active & active & active & active ) and (show & show & show & show ) and ((not game_lost) & (not game_lost) & (not game_lost) & (not game_lost));
green <= (active & active & active & active ) and (show & show & show & show ) and ((not game_over) & (not game_over) & (not game_over) & (not game_over)) and ((not game_lost) & (not game_lost) & (not game_lost) & (not game_lost))and ((game_start) & (game_start) & (game_start) & (game_start));

hsync <= h;
vsync <= v;

anode_activate <= anode;
led <= wled;

end Behavioral;
