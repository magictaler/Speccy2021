----------------------------------------------------------------------------------
-- Originally designed by SYD as part of Speccy2010 project
-- 
-- Code cleanup by Dmitry Pakomenko, 2021
-- 
-- Design Name: digital audio mixer module
-- Module Name: zx_sound_mixer - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as part of sound subsystem
-- to emulate functionality of the standard ZX Spectrum beeper, AY8910 etc
----------------------------------------------------------------------------------


library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity zx_sound_mixer is
  generic (
    g_weight_resolution_bits : integer := 24;
    g_in_audio_resolution_bits : integer := 8;
    g_out_audio_resolution_bits : integer := 16
  );
  port (
    i_clk : in std_logic; 
    i_audio1_ay_a : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);--AY1
    i_audio1_ay_b : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
    i_audio1_ay_c : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
    i_audio2_ay_a : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);--AY2
    i_audio2_ay_b : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
    i_audio2_ay_c : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
    i_weight_audio1_ay_a : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--AY1 - weight
    i_weight_audio1_ay_b : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);-- sum should be <=1
    i_weight_audio1_ay_c : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
    i_weight_audio2_ay_a : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--AY2 - weight
    i_weight_audio2_ay_b : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);-- sum should be <=1
    i_weight_audio2_ay_c : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
    i_audio_aux_1 : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);--COVOX C1
    i_audio_aux_2 : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);--COVOX C2
    i_audio_aux_3 : in std_logic_vector(g_out_audio_resolution_bits - 1 downto 0);--SID
    i_weight_audio_aux_1 : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--COVOX C1
    i_weight_audio_aux_2 : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--COVOX C2
    i_weight_audio_aux_3 : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--SID
    i_audio_beeper : in std_logic;
    i_audio_tape : in std_logic;
    i_weight_audio_beeper : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--beeper
    i_weight_audio_tape : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--tape
    i_ay1_enabled : in std_logic;
    i_ay2_enabled : in std_logic;
    i_aux1_enabled : in std_logic;
    i_aux2_enabled : in std_logic;
    i_aux3_enabled : in std_logic;
    o_audio : out std_logic_vector(g_out_audio_resolution_bits - 1 downto 0)
  );
end;

architecture rtl of zx_sound_mixer is

  type t_array_5xu16_8 is array (0 to 31) of unsigned(g_weight_resolution_bits - 1 downto 0);
  type t_sm_mixer is (s_mixer_step1, s_mixer_step2);
 
  constant c_24b_zeroes : unsigned(g_weight_resolution_bits - 1 downto 0) := (others => '0');
  constant c_48b_zeroes : unsigned(g_weight_resolution_bits * 2 - 1 downto 0) := (others => '0');
  constant c_16b_zeroes : unsigned(g_out_audio_resolution_bits - 1 downto 0) := (others => '0');
  constant c_8b_zeroes : unsigned(g_in_audio_resolution_bits - 1 downto 0) := (others => '0');
  constant c_24b_FF : unsigned(g_weight_resolution_bits - 1 downto 0) := x"0000FF";
  constant c_48b_FF : unsigned(g_weight_resolution_bits * 2 - 1 downto 0) := x"0000000000FF";
  
  constant c_divider_table : t_array_5xu16_8 := (
    x"000000", x"000100", x"000080", x"000055",--00,01,02,03 
    x"000040", x"000033", x"00002a", x"000024",--04,05,06,07 
    x"000020", x"00001c", x"000019", x"000017",--08,09,0a,0b 
    x"000015", x"000013", x"000012", x"000011",--0c,0d,0e,0f 
    x"000010", x"00000f", x"00000e", x"00000d",--10,11,12,13 
    x"00000c", x"00000c", x"00000b", x"00000b",--14,15,16,17 
    x"00000a", x"00000a", x"000009", x"000009",--18,19,1a,1b 
    x"000009", x"000008", x"000008", x"000008" --1c,1d,1e,1f
  );
	 
  signal s_in_ay1 : unsigned(g_weight_resolution_bits * 2 - 1 downto 0);
  signal s_in_ay2 : unsigned(g_weight_resolution_bits * 2 - 1 downto 0);
  signal s_in_aux1 : unsigned(g_weight_resolution_bits * 2 - 1 downto 0);
  signal s_in_aux2 : unsigned(g_weight_resolution_bits * 2 - 1 downto 0);
  signal s_in_aux3 : unsigned(g_weight_resolution_bits * 2 - 1 downto 0);
  signal s_in_beeper : unsigned(g_weight_resolution_bits * 2 - 1 downto 0);
  signal s_in_tape : unsigned(g_weight_resolution_bits * 2 - 1 downto 0);

  signal s_tmp_sum : unsigned(g_weight_resolution_bits - 1 downto 0);
  signal s_audio : std_logic_vector(39 downto 0);

  signal s_weight_ay1 : unsigned(g_weight_resolution_bits - 1 downto 0);
  signal s_weight_ay2 : unsigned(g_weight_resolution_bits - 1 downto 0);
  signal s_weight_aux1 : unsigned(g_weight_resolution_bits - 1 downto 0);
  signal s_weight_aux2 : unsigned(g_weight_resolution_bits - 1 downto 0);
  signal s_weight_aux3 : unsigned(g_weight_resolution_bits - 1 downto 0);
  signal s_weight_beeper : unsigned(g_weight_resolution_bits - 1 downto 0);
  signal s_weight_tape : unsigned(g_weight_resolution_bits - 1 downto 0);

  signal s_weight_sum : unsigned(g_weight_resolution_bits - 1 downto 0);
  signal s_sm_mixer : t_sm_mixer := s_mixer_step1;
	
begin

  p_sound_mixer : process(i_clk)
  begin
    if i_clk'event and i_clk = '1' then
      case s_sm_mixer is
        when s_mixer_step1 =>
          if i_ay1_enabled = '1' then
            s_weight_ay1 <= unsigned(i_weight_audio1_ay_a) + unsigned(i_weight_audio1_ay_b) + unsigned(i_weight_audio1_ay_c);
            s_in_ay1 <= (c_16b_zeroes & unsigned(i_audio1_ay_a)) * unsigned(i_weight_audio1_ay_a) +
              (c_16b_zeroes & unsigned(i_audio1_ay_b)) * unsigned(i_weight_audio1_ay_b) + 
              (c_16b_zeroes & unsigned(i_audio1_ay_c)) * unsigned(i_weight_audio1_ay_c);
          else
            s_in_ay1 <= c_48b_zeroes;
            s_weight_ay1 <= c_24b_zeroes;
          end if;

          if i_ay2_enabled = '1' then
            s_weight_ay1 <= unsigned(i_weight_audio2_ay_a) + unsigned(i_weight_audio2_ay_b) + unsigned(i_weight_audio2_ay_c);
            s_in_ay2 <= (c_16b_zeroes & unsigned(i_audio2_ay_a)) * unsigned(i_weight_audio2_ay_a) +
              (c_16b_zeroes & unsigned(i_audio2_ay_b)) * unsigned(i_weight_audio2_ay_b) + 
              (c_16b_zeroes & unsigned(i_audio2_ay_c)) * unsigned(i_weight_audio2_ay_c);
          else
            s_in_ay2 <= c_48b_zeroes;
            s_weight_ay2 <= c_24b_zeroes;
          end if;
      
          if i_aux1_enabled = '1' then
            s_weight_aux1 <= unsigned(i_weight_audio_aux_1);
            s_in_aux1 <= (c_16b_zeroes & unsigned(i_audio_aux_1)) * unsigned(i_weight_audio_aux_1);
          else
            s_in_aux1 <= c_48b_zeroes;
            s_weight_aux1 <= c_24b_zeroes;
          end if;
		
          if i_aux2_enabled = '1' then
            s_weight_aux2 <= unsigned(i_weight_audio_aux_2);
            s_in_aux2 <= (c_16b_zeroes & unsigned(i_audio_aux_2)) * unsigned(i_weight_audio_aux_2);
          else
            s_in_aux2 <= c_48b_zeroes;
            s_weight_aux2 <= c_24b_zeroes;
          end if;
		
          if i_aux3_enabled = '1' then
            s_weight_aux3 <= unsigned(i_weight_audio_aux_3);
            s_in_aux3 <= (c_8b_zeroes & unsigned(i_audio_aux_3)) * unsigned(i_weight_audio_aux_3);
          else
            s_in_aux3 <= c_48b_zeroes;
            s_weight_aux3 <= c_24b_zeroes;
          end if;
		
          if i_audio_beeper = '1' then
            s_in_beeper <= c_24b_FF * unsigned(i_weight_audio_beeper);
          else
            s_in_beeper <= c_48b_zeroes;
          end if;
      
          if i_audio_tape = '1' then
            s_in_tape <= c_24b_FF * unsigned(i_weight_audio_tape);
          else
            s_in_tape <= c_48b_zeroes;
          end if;

          s_sm_mixer <= s_mixer_step2;

        when s_mixer_step2 =>
          s_audio <= std_logic_vector(s_tmp_sum(23 downto 8)  *
            unsigned(c_divider_table(to_integer(s_weight_sum(12 downto 8)))));--assuming input signals were all 8 bit only
          s_sm_mixer <= s_mixer_step1;

        when others => 
          s_sm_mixer <= s_mixer_step1;

      end case;
    end if;
  end process;

  s_weight_sum <= c_24b_FF + s_weight_ay1 + s_weight_ay2 + s_weight_aux1 + s_weight_aux2 + s_weight_aux3 + 
    unsigned(i_weight_audio_beeper) + unsigned(i_weight_audio_tape);

  s_tmp_sum <= s_in_ay1(g_weight_resolution_bits - 1 downto 0) + 
    s_in_ay2(g_weight_resolution_bits - 1 downto 0) + 
    s_in_aux1(g_weight_resolution_bits - 1 downto 0) + 
    s_in_aux2(g_weight_resolution_bits - 1 downto 0) + 
    s_in_aux3(g_weight_resolution_bits - 1 downto 0) + 
    s_in_beeper(g_weight_resolution_bits - 1 downto 0) + 
    s_in_tape(g_weight_resolution_bits - 1 downto 0);

  o_audio <= s_audio(g_out_audio_resolution_bits - 1 downto 0);
   
end architecture rtl;
