-- Code your design here

library IEEE;

use IEEE.std_logic_1164.all;

use IEEE.std_logic_1164.all;

use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity stopwatch is

    port(

    four_bit_anode: out std_logic_vector(3 downto 0);                   --to activate the 4 anodes

    seven_bit_out: out std_logic_vector(6 downto 0):=(others=>'0');     --to activate the 7 cathodes

    clock: in std_logic;                                            

    reset: in std_logic;

    start_continue: in std_logic;

    pause: in std_logic;

    dp: out std_logic                                                   --display pointer

    );

 end stopwatch;

architecture Behavioural of stopwatch is


signal cycle_counter: std_logic_vector(27 downto 0):= (others=>'0');    --to count the number of clock cycles

signal tenthsecond_enable: std_logic;                                   --enable bit to increase tenth-sec counter

signal display_number: std_logic_vector(15 downto 0):= (others=>'0');   --stores four numbers(4 bit each) to be displayed on stopwatch

signal display_bit: std_logic_vector(3 downto 0);                       --number to be displayed on active anode

signal refresh_rate: std_logic_vector(19 downto 0) := (others=>'0');    --count number of clock cycles 

signal anode_refresh: std_logic_vector(1 downto 0):= (others=>'0');     --enable bit to change active anode

signal min: std_logic_vector(3 downto 0):= (others=>'0');               --store minute count

signal tenthsec: std_logic_vector(3 downto 0):= (others=>'0');          --store 1/10 sec count

signal sec: std_logic_vector(7 downto 0):= (others=>'0');               --store second count

signal timeron: std_logic;


begin

-- calculated expression for seven segment display using K-map according to the number to be displayed on LED(display-bit)

process(display_bit, clock) is

begin

if(rising_edge(clock)) then

    -- dp<='0';

    seven_bit_out(6)<=(not display_bit(3) and not display_bit(2) and not display_bit(1) and display_bit(0)) or (display_bit(2) and not display_bit(1) and not display_bit(0));

    seven_bit_out(5)<=( display_bit(2) and not display_bit(1) and display_bit(0)) or (display_bit(2) and display_bit(1) and not display_bit(0));

    seven_bit_out(4)<=(not display_bit(2) and display_bit(1) and not display_bit(0));

    seven_bit_out(3)<=(display_bit(2) and display_bit(1) and display_bit(0)) or (not display_bit(3) and not display_bit(2) and not display_bit(1) and display_bit(0)) or (display_bit(2) and not display_bit(1) and not display_bit(0));

    seven_bit_out(2)<=( display_bit(0)) or ( display_bit(2) and not display_bit(1) );

    seven_bit_out(1)<=(not display_bit(2) and display_bit(1)) or (display_bit(1) and display_bit(0)) or (not display_bit(3) and not display_bit(2) and display_bit(0));

    seven_bit_out(0)<=(not display_bit(3) and not display_bit(2) and not display_bit(1)) or ( display_bit(2) and display_bit(1) and display_bit(0));

end if;

end process;


-- timeron bit is active when stopwatch is turned on (time is being measured)

-- timeron is turned on when start button is pressed and off when pause button is pressed

process(clock, start_continue, reset, pause)

begin

        if(rising_edge(clock)) then

            if(start_continue='1') then

                timeron<='1';

        elsif(pause='1') then

                timeron<='0';

        end if;

    end if;

end process;


-- refresh rate counts clock cycles, which we will use to count time after which we need to display/refresh LEDs on stopwatch

-- for continuous-looking display of LEDs, we need to keep regreshing the bits even in pause mode

process(clock, timeron, reset)

begin

    if (reset='1') then

        refresh_rate<=(others=>'0');

    elsif(rising_edge(clock) ) then

        --if(timeron='1') then

            refresh_rate<=refresh_rate+1;

        --end if;

    end if;

end process;


-- refresh/change active anode after 2^17 clock cycle

anode_refresh <= refresh_rate(19 downto 18);    -- refresh rate


-- turn on anodes in sequence according to anode_refresh

process(anode_refresh,display_number,start_continue,timeron,reset,pause,tenthsecond_enable,refresh_rate,

cycle_counter, display_bit,timeron)

begin

    case anode_refresh is

        when "11"=>

            four_bit_anode <="0111";

            dp<='0';

            display_bit<= display_number(15 downto 12); -- turn on minute LED 

        when "10"=>

            four_bit_anode <="1011";

            dp<='1';

            display_bit<= display_number(11 downto 8);  -- turn on tens digit LED of second

        when "01"=>

            four_bit_anode <="1101";

            dp<='0';

            display_bit<= display_number(7 downto 4);   -- turn on unit digit LED of second

        when "00" =>                

            four_bit_anode <="1110";                    

            dp<='1';

            display_bit<= display_number(3 downto 0);   -- turn on tenth-second LED

        when others =>

        end case;

end process;


-- cycle-counter count number of clock cycles

-- in pause mode, when timeron = 1 

-- we dont want to increase count of time, so cycle-counter is not increased if timeron=1

process(clock, timeron, reset)

begin

    if(reset='1') then

        cycle_counter<= (others=>'0');

    elsif(rising_edge(clock)) then

        if(cycle_counter =x"98967F" ) then -- 9999999 cycles = 98967F

            cycle_counter <= (others => '0');

        elsif(timeron='1') then

            cycle_counter <= cycle_counter + "0000001";

        end if;

    end if;

end process;


tenthsecond_enable<= '1' when cycle_counter = x"98967F" else '0';

-- freq of clock = 100MHz, so 1/10 sec=10^7 clock cycles

-- after 10^7 clock cycles, tenth-sec is increased by 1

-- 9999999 cycles = x"98967F"



process(clock, display_number, timeron, tenthsecond_enable, reset)

begin

        if(reset='1') then

                display_number<=(others=>'0');

        elsif(rising_edge(clock)) then

            if(tenthsecond_enable='1' and timeron='1') then

            display_number<= display_number + x"0001";

            end if;


            if(display_number(3 downto 0)=x"a") then --10

                display_number(7 downto 4) <= display_number(7 downto 4) +"0001";

                display_number(3 downto 0) <= "0000";


            elsif(display_number(7 downto 4)=x"a" and display_number(3 downto 0)=x"0") then --one's of a sec 10

                display_number(11 downto 8) <= display_number(11 downto 8)+ "0001";

                display_number(7 downto 0) <= x"00";


            elsif(display_number(11 downto 8)=x"6" and display_number(7downto 4)=x"0" and display_number(3 downto 0)=x"0") then --200

                display_number(15 downto 12) <= display_number(15 downto 12) + "0001";

                display_number(11 downto 0) <= x"000";

            end if;


            if(display_number(15 downto 12)=x"a" and display_number(11 downto 8)=x"0" and display_number(7 downto 4)=x"0" and display_number(3 downto 0)=x"0") then --3000

                display_number(15 downto 0) <= x"0000";

            end if;

        end if;


tenthsec<= display_number(3 downto 0);

sec<= display_number(11 downto 4);

min<= display_number(15 downto 12);


end process;

end Behavioural;
