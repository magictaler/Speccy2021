----------------------------------------------------------------------------------
-- Originally designed by SYD as part of Speccy2010 project
-- 
-- Code cleanup by Dmitry Pakomenko, 2021
-- 
-- Design Name: YM2149 module
-- Module Name: ym2149 - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as part of sound subsystem
-- to emulate functionality of the standard ZX Spectrum beeper, AY8910 etc
----------------------------------------------------------------------------------


library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ym2149 is
  port (
    i_clk : in std_logic;
    i_ena : in std_logic; -- clock i_enable for higher speed operation
    i_reset_l : in std_logic;
    i_sel_l : in std_logic;
  
    i_da : in  std_logic_vector(7 downto 0);
    o_da : out std_logic_vector(7 downto 0);

    i_busctrl_addr : in std_logic;
    i_busctrl_we : in std_logic;
    i_busctrl_re : in std_logic;
    i_ctrl_aymode : in std_logic;
  
    o_audio_a : out std_logic_vector(7 downto 0);
    o_audio_b : out std_logic_vector(7 downto 0);
    o_audio_c : out std_logic_vector(7 downto 0);
  
    o_audio : out std_logic_vector(7 downto 0)
  );
end;

architecture rtl of ym2149 is

  type t_array_16x8 is array (0 to 15) of std_logic_vector(7 downto 0);
  type t_array_3x12 is array (1 to 3) of std_logic_vector(11 downto 0);
  type t_vol_table_type32 is array (0 to 31) of unsigned(7 downto 0);
  type t_vol_table_type16 is array (0 to 15) of unsigned(7 downto 0);

  constant c_vol_table_ay : t_vol_table_type16 := (
		x"00", x"03", x"04", x"06",
		x"0a", x"0f", x"15", x"22", 
		x"28", x"41", x"5b", x"72", 
		x"90", x"b5", x"d7", x"ff" );
		
  constant c_vol_table_ym : t_vol_table_type32 := (
		x"00", x"01", x"01", x"02", x"02", x"03", x"03", x"04",
		x"06", x"07", x"09", x"0a", x"0c", x"0e", x"11", x"13",
		x"17", x"1b", x"20", x"25", x"2c", x"35", x"3e", x"47",
		x"54", x"66", x"77", x"88", x"a1", x"c0", x"e0", x"ff");    

  signal s_cnt_div : unsigned(3 downto 0) := (others => '0');
  signal s_noise_div : std_logic := '0';
  signal s_ena_div : std_logic;
  signal s_ena_div_noise : std_logic;
  signal s_poly17 : std_logic_vector(16 downto 0) := (others => '0');

  -- registers
  signal s_addr : std_logic_vector(7 downto 0);

  signal s_reg : t_array_16x8;
  signal s_env_reset : std_logic;

  signal s_noise_gen_cnt : unsigned(4 downto 0);
  signal s_noise_gen_op : std_logic;
  signal s_tone_gen_cnt : t_array_3x12 := (others => (others => '0'));
  signal s_tone_gen_op : std_logic_vector(3 downto 1) := "000";

  signal s_env_gen_cnt : std_logic_vector(15 downto 0);
  signal s_env_ena : std_logic;
  signal s_env_hold : std_logic;
  signal s_env_inc : std_logic;
  signal s_env_vol : std_logic_vector(4 downto 0);
  
  signal s_channel_A : std_logic_vector(4 downto 0);
  signal s_channel_B : std_logic_vector(4 downto 0);
  signal s_channel_C : std_logic_vector(4 downto 0);

begin
  
  process(i_clk)
  begin
    if i_clk'event and i_clk = '1' then
      if (i_reset_l = '0') then
        s_addr <= (others => '0');
      elsif  i_busctrl_addr = '1' then -- yuk
        s_addr <= i_da;
      end if;
    end if;
  end process;

  process(i_clk)
  begin
    if i_clk'event and i_clk = '1' then
      if i_reset_l = '0' then
        s_reg <= (others => (others => '0'));
	s_reg(7) <= x"ff";
      elsif i_busctrl_we = '1' then
        case s_addr(3 downto 0) is
          when x"0" => s_reg(0)  <= i_da;
          when x"1" => s_reg(1)  <= i_da;
          when x"2" => s_reg(2)  <= i_da;
          when x"3" => s_reg(3)  <= i_da;
          when x"4" => s_reg(4)  <= i_da;
          when x"5" => s_reg(5)  <= i_da;
          when x"6" => s_reg(6)  <= i_da;
          when x"7" => s_reg(7)  <= i_da;
          when x"8" => s_reg(8)  <= i_da;
          when x"9" => s_reg(9)  <= i_da;
          when x"A" => s_reg(10) <= i_da;
          when x"B" => s_reg(11) <= i_da;
          when x"C" => s_reg(12) <= i_da;
          when x"D" => s_reg(13) <= i_da;
          when x"E" => s_reg(14) <= i_da;
          when x"F" => s_reg(15) <= i_da;
          when others => null;
        end case;
      end if;
      s_env_reset <= '0';
      if i_busctrl_we = '1' and s_addr(3 downto 0) = x"D" then
        s_env_reset <= '1';
      end if;
    end if;
  end process;

  process(i_clk)
  begin
    if i_clk'event and i_clk = '1' then
      o_da <= (others => '0'); -- 'X'
      if (i_busctrl_re = '1') then -- not necessary, but useful for putting 'X's in the simulator
        case s_addr(3 downto 0) is
          when x"0" => o_da <= s_reg(0) ;
          when x"1" => o_da <= "0000" & s_reg(1)(3 downto 0) ;
          when x"2" => o_da <= s_reg(2) ;
          when x"3" => o_da <= "0000" & s_reg(3)(3 downto 0) ;
          when x"4" => o_da <= s_reg(4) ;
          when x"5" => o_da <= "0000" & s_reg(5)(3 downto 0) ;
          when x"6" => o_da <= "000"  & s_reg(6)(4 downto 0) ;
          when x"7" => o_da <= s_reg(7) ;
          when x"8" => o_da <= "000"  & s_reg(8)(4 downto 0) ;
          when x"9" => o_da <= "000"  & s_reg(9)(4 downto 0) ;
          when x"A" => o_da <= "000"  & s_reg(10)(4 downto 0) ;
          when x"B" => o_da <= s_reg(11);
          when x"C" => o_da <= s_reg(12);
          when x"D" => o_da <= "0000" & s_reg(13)(3 downto 0);
          when x"E" => 
            if (s_reg(7)(6) = '0') then -- input
              o_da <= x"00";
            else
              o_da <= s_reg(14); -- read output reg
            end if;
          when x"F" => 
            if (s_reg(7)(7) = '0') then
              o_da <= x"00";
            else
              o_da <= s_reg(15);
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;


  process(i_clk,i_ena)
  begin
    if i_clk'event and i_clk = '1' and i_ena = '1' then
      s_ena_div <= '0';
      s_ena_div_noise <= '0';
      if (s_cnt_div = "0000") then
        s_cnt_div <= (not i_sel_l) & "111";
        s_ena_div <= '1';

        s_noise_div <= not s_noise_div;
        if (s_noise_div = '1') then
          s_ena_div_noise <= '1';
        end if;
      else
        s_cnt_div <= s_cnt_div - "1";
      end if;
    end if;
  end process;  


  process(i_clk)
    variable v_noise_gen_comp : unsigned(4 downto 0);
    variable v_poly17_zero : std_logic;
  begin
    if i_clk'event and i_clk = '1' then
      if (s_reg(6)(4 downto 0) = "00000") then
        v_noise_gen_comp := "00000";
      else
        v_noise_gen_comp := unsigned( s_reg(6)(4 downto 0) ) - 1;
      end if;
      v_poly17_zero := '0';
      if (s_poly17 = "00000000000000000") then v_poly17_zero := '1'; end if;
      if (i_ena = '1') then
        if (s_ena_div_noise = '1') then -- divider i_ena
          if (s_noise_gen_cnt >= v_noise_gen_comp) then
            s_noise_gen_cnt <= "00000";
            s_poly17 <= (s_poly17(0) xor s_poly17(2) xor v_poly17_zero) & s_poly17(16 downto 1);
          else
            s_noise_gen_cnt <= s_noise_gen_cnt + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  s_noise_gen_op <= s_poly17(0);

  process(i_clk)
    variable v_tone_gen_freq : t_array_3x12;
    variable v_tone_gen_comp : t_array_3x12;
  begin
    if i_clk'event and i_clk = '1' then
      -- looks like real chips count up - we need to get the Exact behaviour ..
      v_tone_gen_freq(1) := s_reg(1)(3 downto 0) & s_reg(0);
      v_tone_gen_freq(2) := s_reg(3)(3 downto 0) & s_reg(2);
      v_tone_gen_freq(3) := s_reg(5)(3 downto 0) & s_reg(4);
		
      -- period 0 = period 1
      for i in 1 to 3 loop
        if (v_tone_gen_freq(i) = x"000") then
          v_tone_gen_comp(i) := x"000";
        else
          v_tone_gen_comp(i) := std_logic_vector(unsigned(v_tone_gen_freq(i)) - 1);
        end if;
      end loop;

      if (i_ena = '1') then
        for i in 1 to 3 loop
          if (s_ena_div = '1') then -- divider i_ena
            if (s_tone_gen_cnt(i) >= v_tone_gen_comp(i)) then
              s_tone_gen_cnt(i) <= x"000";
              s_tone_gen_op(i) <= not s_tone_gen_op(i);
            else
              s_tone_gen_cnt(i) <= std_logic_vector(unsigned(s_tone_gen_cnt(i)) + 1);
            end if;
          end if;
        end loop;
      end if;
    end if;
  end process;


  process(i_clk)
    variable v_env_gen_freq : std_logic_vector(15 downto 0);
    variable v_env_gen_comp : std_logic_vector(15 downto 0);
  begin
    if i_clk'event and i_clk = '1' then
      v_env_gen_freq := s_reg(12) & s_reg(11);
      -- envelope freqs 1 and 0 are the same.
      if (v_env_gen_freq = x"0000") then
        v_env_gen_comp := x"0000";
      else
        v_env_gen_comp := std_logic_vector(unsigned(v_env_gen_freq) - 1);
      end if;
      if (i_ena = '1') then
        s_env_ena <= '0';
        if (s_ena_div = '1') then -- divider i_ena
          if (s_env_gen_cnt >= v_env_gen_comp) then
            s_env_gen_cnt <= x"0000";
            s_env_ena <= '1';
          else
            s_env_gen_cnt <= std_logic_vector(unsigned(s_env_gen_cnt) + 1);
          end if;
        end if;
      end if;
    end if;
  end process;
  

  process(i_clk)
    variable v_is_bot    : boolean;
    variable v_is_bot_p1 : boolean;
    variable v_is_top_m1 : boolean;
    variable v_is_top    : boolean;
  begin
    -- envelope shapes
    -- C AtAlH
    -- 0 0 x x  \___
    --
    -- 0 1 x x  /___
    --
    -- 1 0 0 0  \\\\
    --
    -- 1 0 0 1  \___
    --
    -- 1 0 1 0  \/\/
    --           ___
    -- 1 0 1 1  \
    --
    -- 1 1 0 0  ////
    --           ___
    -- 1 1 0 1  /
    --
    -- 1 1 1 0  /\/\
    --
    -- 1 1 1 1  /___
    if i_clk'event and i_clk = '1' then
      if s_env_reset = '1' then
        -- load initial state
        if (s_reg(13)(2) = '0') then -- attack
          s_env_vol <= "11111";
          s_env_inc <= '0'; -- -1
        else
          s_env_vol <= "00000";
          s_env_inc <= '1'; -- +1
        end if;
        s_env_hold <= '0';
      else
        v_is_bot := (s_env_vol = "00000");
        v_is_bot_p1 := (s_env_vol = "00001");
        v_is_top_m1 := (s_env_vol = "11110");
        v_is_top := (s_env_vol = "11111");
        
        if (i_ena = '1') then
          if (s_env_ena = '1') then
            if (s_env_hold = '0') then
              if (s_env_inc = '1') then
                s_env_vol <= std_logic_vector( unsigned( s_env_vol ) + "00001");
              else
                s_env_vol <= std_logic_vector( unsigned( s_env_vol ) + "11111");
              end if;
            end if;

            -- envelope shape control.
            if (s_reg(13)(3) = '0') then
              if (s_env_inc = '0') then -- down
                if v_is_bot_p1 then s_env_hold <= '1'; end if;
              else
                if v_is_top then s_env_hold <= '1'; end if;
              end if;
            else
              if (s_reg(13)(0) = '1') then -- hold = 1
                if (s_env_inc = '0') then -- down
                  if (s_reg(13)(1) = '1') then -- alt
                    if v_is_bot then s_env_hold <= '1'; end if;
                  else
                    if v_is_bot_p1 then s_env_hold <= '1'; end if;
                  end if;
                else
                  if (s_reg(13)(1) = '1') then -- alt
                    if v_is_top then s_env_hold <= '1'; end if;
                  else
                    if v_is_top_m1 then s_env_hold <= '1'; end if;
                  end if;
                end if;
              elsif (s_reg(13)(1) = '1') then -- alternate
                if (s_env_inc = '0') then -- down
                  if v_is_bot_p1 then s_env_hold <= '1'; end if;
                  if v_is_bot then s_env_hold <= '0'; s_env_inc <= '1'; end if;
                else
                  if v_is_top_m1 then s_env_hold <= '1'; end if;
                  if v_is_top then s_env_hold <= '0'; s_env_inc <= '0'; end if;
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;
   end if;
  end process;
  

  process(i_clk)
    variable v_chan_mixed : std_logic_vector(2 downto 0);
  begin
    if i_clk'event and i_clk = '1' then
      if (i_ena = '1') then
        v_chan_mixed(0) := (s_reg(7)(0) or s_tone_gen_op(1)) and (s_reg(7)(3) or s_noise_gen_op);
        v_chan_mixed(1) := (s_reg(7)(1) or s_tone_gen_op(2)) and (s_reg(7)(4) or s_noise_gen_op);
        v_chan_mixed(2) := (s_reg(7)(2) or s_tone_gen_op(3)) and (s_reg(7)(5) or s_noise_gen_op);

        s_channel_A <= "00000";
        s_channel_B <= "00000";
        s_channel_C <= "00000";
      
        if (v_chan_mixed(0) = '1') then
          if (s_reg(8)(4) = '0') then
            s_channel_A <= s_reg(8)(3 downto 0) & "1";
          else
            s_channel_A <= s_env_vol(4 downto 0);
          end if;
        end if;

        if (v_chan_mixed(1) = '1') then
          if (s_reg(9)(4) = '0') then
            s_channel_B <= s_reg(9)(3 downto 0) & "1";
          else
            s_channel_B <= s_env_vol(4 downto 0);
          end if;
        end if;

        if (v_chan_mixed(2) = '1') then
          if (s_reg(10)(4) = '0') then
            s_channel_C <= s_reg(10)(3 downto 0) & "1";
          else
            s_channel_C <= s_env_vol(4 downto 0);
          end if;
        end if;
      end if;
    end if;    
  end process;
  
  process(i_clk)
    variable v_out_audio_mixed : unsigned(9 downto 0);
  begin
    if i_clk'event and i_clk = '1' then
      if i_reset_l = '0' then
        o_audio <= x"00";
        o_audio_a <= x"00";
        o_audio_b <= x"00";
        o_audio_c <= x"00";
      else
        if(i_ctrl_aymode = '0') then
          v_out_audio_mixed := ("00" & c_vol_table_ym(to_integer(unsigned(s_channel_A)))) + 
            ("00" & c_vol_table_ym(to_integer(unsigned(s_channel_B)))) + 
            ("00" & c_vol_table_ym(to_integer(unsigned(s_channel_C))));
          o_audio  <= std_logic_vector(v_out_audio_mixed(9 downto 2));
          o_audio_a <= std_logic_vector(c_vol_table_ym(to_integer(unsigned(s_channel_A))));
          o_audio_b <= std_logic_vector(c_vol_table_ym(to_integer(unsigned(s_channel_B))));
          o_audio_c <= std_logic_vector(c_vol_table_ym(to_integer(unsigned(s_channel_C))));
        else
          v_out_audio_mixed := ("00" & c_vol_table_ay(to_integer(unsigned(s_channel_A(4 downto 1))))) + 
            ("00" & c_vol_table_ay(to_integer(unsigned(s_channel_B(4 downto 1))))) + 
            ("00" & c_vol_table_ay(to_integer(unsigned(s_channel_C(4 downto 1)))));
            o_audio <= std_logic_vector(v_out_audio_mixed(9 downto 2));
            o_audio_a <= std_logic_vector(c_vol_table_ay(to_integer(unsigned(s_channel_A(4 downto 1)))));
            o_audio_b <= std_logic_vector(c_vol_table_ay(to_integer(unsigned(s_channel_B(4 downto 1)))));
            o_audio_c <= std_logic_vector(c_vol_table_ay(to_integer(unsigned(s_channel_C(4 downto 1)))));
        end if;
      end if;
    end if;
  end process;
  
end architecture rtl;
