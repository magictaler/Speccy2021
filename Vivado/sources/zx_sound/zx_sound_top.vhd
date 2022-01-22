----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 10/27/2021 10:15:00 PM
-- Design Name: ZX Spectrum sound subsystem
-- Module Name: zx_sound_top - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as part of sound subsystem
-- to emulate functionality of the standard ZX Spectrum beeper, AY8910 etc
-- 
-- Dependencies: no
-- 
-- Revision:
-- Revision 0.02 - Fully functional emulation of ZX Spectrum's sound
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity zx_sound_top is
  generic (
    g_weight_resolution_bits : integer := 24;
    g_in_audio_resolution_bits : integer := 8;
    g_out_audio_resolution_bits : integer := 16
  );
  port (
    i_clk : in std_logic; 
    i_resetn : in std_logic; 
    -- AY
    i_reset_l : in std_logic;
    i_ena : in std_logic;
    i_da : in std_logic_vector(7 downto 0);
    o_da : out std_logic_vector(7 downto 0);
    i_busctrl_addr : in std_logic;
    i_busctrl_we : in std_logic;
    i_busctrl_re : in std_logic;
    i_ctrl_aymode : in std_logic;
 
    i_audio_beeper : in std_logic;
    i_audio_tape : in std_logic;
	 
    i_weight_audio_beeper : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--beeper
    i_weight_audio_tape : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);--tape
	 
    o_audio_pwm : out std_logic
  );
end;

architecture rtl of zx_sound_top is

  type  t_array_3x24   is array (0 to 2) of unsigned( 23 downto 0);
  type  t_weight_array is array (0 to 3, 0 to 1) of t_array_3x24;

  signal s_audio : std_logic_vector(15 downto 0);
  signal s_audio_ay_a : std_logic_vector(7 downto 0);
  signal s_audio_ay_b : std_logic_vector(7 downto 0);
  signal s_audio_ay_c : std_logic_vector(7 downto 0);
  signal s_ay_mode : unsigned(7 downto 0) := x"03";
  signal s_weight_ay : t_array_3x24;

  -- A B C (L)  A B C (R)
  constant s_weigth_ym_table : t_weight_array := (
    ((x"000000",x"000000",x"000000"),(x"000000",x"000000",x"000000")),
    ((x"000092",x"000007",x"000066"),(x"000007",x"000092",x"000066")),
    ((x"000092",x"000066",x"000007"),(x"000007",x"000066",x"000092")),
    ((x"000055",x"000055",x"000055"),(x"000055",x"000055",x"000055")));


  component zx_sound_mixer
    generic (
      g_weight_resolution_bits : integer := 24;
      g_in_audio_resolution_bits : integer := 8;
      g_out_audio_resolution_bits : integer := 16
    );
    port (
      i_clk : in std_logic; 
      i_audio1_ay_a : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
      i_audio1_ay_b : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
      i_audio1_ay_c : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
      i_audio2_ay_a : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
      i_audio2_ay_b : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
      i_audio2_ay_c : in std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
      i_weight_audio1_ay_a : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_weight_audio1_ay_b : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_weight_audio1_ay_c : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_weight_audio2_ay_a : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_weight_audio2_ay_b : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_weight_audio2_ay_c : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_audio_aux_1 : in  std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
      i_audio_aux_2 : in  std_logic_vector(g_in_audio_resolution_bits - 1 downto 0);
      i_audio_aux_3 : in  std_logic_vector(g_out_audio_resolution_bits - 1 downto 0);
      i_weight_audio_aux_1 : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_weight_audio_aux_2 : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_weight_audio_aux_3 : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_audio_beeper : in std_logic;
      i_audio_tape : in std_logic;
      i_weight_audio_beeper : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_weight_audio_tape : in std_logic_vector(g_weight_resolution_bits - 1 downto 0);
      i_ay1_enabled : in std_logic;
      i_ay2_enabled : in std_logic;
      i_aux1_enabled : in std_logic;
      i_aux2_enabled : in std_logic;
      i_aux3_enabled : in std_logic;
      o_audio : out std_logic_vector(g_out_audio_resolution_bits - 1 downto 0)
    );
  end component;

  component ym2149
    port (
      i_clk : in std_logic;
      i_ena : in std_logic;
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
  end component;

  component pwm
    generic (
      g_data_width : integer := 8
    );
    port ( 
      i_clk : in std_logic;
      i_resetn : in std_logic;
      i_pwm_val : in std_logic_vector(g_data_width - 1 downto 0);
      o_pwm : out std_logic
    );
  end component;


begin

  i_zx_sound_mixer : zx_sound_mixer
    port map (
      i_clk => i_clk,
      i_audio1_ay_a => s_audio_ay_a,
      i_audio1_ay_b => s_audio_ay_b,
      i_audio1_ay_c => s_audio_ay_c,
      i_audio2_ay_a => (others => '0'),
      i_audio2_ay_b => (others => '0'),
      i_audio2_ay_c => (others => '0'),
      i_weight_audio1_ay_a => std_logic_vector(s_weight_ay(0)),
      i_weight_audio1_ay_b => std_logic_vector(s_weight_ay(1)),
      i_weight_audio1_ay_c => std_logic_vector(s_weight_ay(2)),
      i_weight_audio2_ay_a => (others => '0'),
      i_weight_audio2_ay_b => (others => '0'),
      i_weight_audio2_ay_c => (others => '0'),
      i_audio_aux_1 => (others => '0'),
      i_audio_aux_2 => (others => '0'),
      i_audio_aux_3 => (others => '0'),
      i_weight_audio_aux_1 => (others => '0'),
      i_weight_audio_aux_2 => (others => '0'),
      i_weight_audio_aux_3 => (others => '0'),
      i_audio_beeper => i_audio_beeper,
      i_audio_tape => i_audio_tape,
      i_weight_audio_beeper => i_weight_audio_beeper,
      i_weight_audio_tape => i_weight_audio_tape,
      i_ay1_enabled => '1',
      i_ay2_enabled => '0',
      i_aux1_enabled => '0',
      i_aux2_enabled => '0',
      i_aux3_enabled => '0',
      o_audio => s_audio
    );

  i_ym2149 : ym2149
    port map (
      i_clk => i_clk,
      i_ena => i_ena,
      i_reset_l => i_reset_l,
      i_sel_l => '1',
      i_da => i_da,
      o_da => o_da,
      i_busctrl_addr => i_busctrl_addr,
      i_busctrl_we => i_busctrl_we,
      i_busctrl_re => i_busctrl_re,
      i_ctrl_aymode => i_ctrl_aymode,
      o_audio_a => s_audio_ay_a,
      o_audio_b => s_audio_ay_b,
      o_audio_c => s_audio_ay_c,
      o_audio => open
    );

  i_pwm : pwm
    port map (
      i_clk => i_clk,
      i_resetn => i_resetn,
      i_pwm_val => s_audio(15 downto 8),
      o_pwm => o_audio_pwm
    );

  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if i_ctrl_aymode = '0' then
        s_weight_ay <= s_weigth_ym_table(to_integer(s_ay_mode), 0);
      else
        s_weight_ay <= s_weigth_ym_table(to_integer(s_ay_mode), 0);
      end if;
   end if;
  end process;

end architecture rtl;
