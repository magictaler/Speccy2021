----------------------------------------------------------------------------------
-- Inspired by Speccy2010 project
-- 
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 10/02/2021 11:00:00 PM
-- Design Name: ZX Spectrum Board
-- Module Name: zx_main_top - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This is a top level of the ZX Spectrum emulator
-- 
-- Dependencies: 
-- 
-- Revision:
-- 
-- Revision 0.02 - Fully functional 48/128K configuration without Betadisk and
--   without original ULA timings so proper border effects are not there yet
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zx_main_top is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_resetn : in std_logic;
      i_aclk : in std_logic;

      o_zx_bus_address : out std_logic_vector(23 downto 0);
      i_zx_bus_data : in std_logic_vector(7 downto 0);
      o_zx_bus_data : out std_logic_vector(7 downto 0);
      o_zx_bus_mem_wr : out std_logic;
      o_zx_bus_mem_req : out std_logic;
      i_zx_bus_mem_ack : in std_logic;

      i_wr_en : in std_logic;    
      i_rd_en : in std_logic;    
      i_register_data_out : in std_logic_vector(31 downto 0);
      i_zx_control_en : in std_logic;
      o_zx_control : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_zx_keyboard_1_en : in std_logic;
      i_zx_keyboard_2_en : in std_logic;
      i_zx_io_ports_en : in std_logic;
      o_zx_io_ports : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_zx_tape_fifo_en : in std_logic;
      o_zx_tape_fifo : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      o_border_color : out std_logic_vector(2 downto 0);
      o_border_stb : out std_logic;
      i_new_frame_int : in std_logic;
      i_ula_attr : in std_logic_vector(7 downto 0);
      o_aud_pwm : out std_logic;
      o_aud_sd : out std_logic;
      o_shadow_vram : out std_logic
    );

end zx_main_top;

architecture rtl of zx_main_top is

  constant c_speaker_bit : integer range 0 to 7 := 4;
  constant c_weight_audio_beeper : std_logic_vector(23 downto 0) := x"000055";
  constant c_weight_audio_tape : std_logic_vector(23 downto 0) := x"000020";
  
  signal s_zx_bus_mem_wr : std_logic;
  signal s_zx_bus_mem_req : std_logic;
  
  -- Z80 signals  
  signal s_cpu_clk_en : std_logic;
  signal s_cpu_reset : std_logic := '0';
  signal s_reset : std_logic;
  signal s_cpu_int : std_logic;
  signal s_cpu_nmi : std_logic;
  signal s_cpu_m1 : std_logic;
  signal s_cpu_mreq : std_logic;
  signal s_cpu_iorq : std_logic;
  signal s_cpu_rd : std_logic;
  signal s_cpu_wr : std_logic;
  signal s_cpu_rfsh : std_logic;
  signal s_cpu_a : std_logic_vector(15 downto 0);
  signal s_cpu_dout : std_logic_vector(7 downto 0);
  signal s_cpu_din : std_logic_vector(7 downto 0);
  signal s_cpu_save_pc : std_logic_vector(15 downto 0);
  signal s_cpu_save_int : std_logic_vector(7 downto 0);
  signal s_cpu_restore_pc : std_logic_vector(15 downto 0);
  signal s_cpu_restore_int  : std_logic_vector(7 downto 0);		
  signal s_cpu_restore_pc_n : std_logic := '1';
  
  signal s_clk7m : std_logic;
  signal s_clk35m : std_logic;
  signal s_clk_ay : std_logic;
  signal s_cpu_mem_wait : std_logic := '0';
  signal s_cpu_wait : std_logic;
  signal s_cpu_halt_req : std_logic := '1';
  signal s_cpu_halt_ack : std_logic := '1';

  -- AY signals
  signal s_ay_rd : std_logic;
  signal s_ay_wr : std_logic;
  signal s_ay_addr : std_logic;
  signal s_ay_ym_mode : std_logic := '1';
  signal s_ay_dout : std_logic_vector(7 downto 0);
  signal s_ay_din : std_logic_vector(7 downto 0);
  signal s_selected_ay2 : std_logic;
  signal s_turbo_sound : std_logic := '0';
                            
  -- Registers
  constant c_control_reg_cpu_halt_bit               : integer range 0 to 31 := 0;
  constant c_control_reg_cpu_restore_pc_n_bit       : integer range 0 to 31 := 1;
  constant c_control_reg_cpu_one_cycle_wait_req_bit : integer range 0 to 31 := 2;
  constant c_control_reg_cpu_reset_bit              : integer range 0 to 31 := 3;
  constant c_control_reg_magic_button_bit           : integer range 0 to 31 := 4;
  constant c_control_reg_cpu_trace_req_bit          : integer range 0 to 31 := 5;
  constant c_control_reg_trdos_flag_bit             : integer range 0 to 31 := 6;
  constant c_control_reg_trdos_wait_bit             : integer range 0 to 31 := 7;
  constant c_control_reg_cpu_pc_lsb_bit             : integer range 0 to 31 := 8;
  constant c_control_reg_cpu_pc_msb_bit             : integer range 0 to 31 := 23;
  constant c_control_reg_cpu_int_lsb_bit            : integer range 0 to 31 := 24;
  constant c_control_reg_cpu_int_msb_bit            : integer range 0 to 31 := 31;
  
  constant c_fe_port_msb_bit      : integer range 0 to 31 := 7;
  constant c_fe_port_lsb_bit      : integer range 0 to 31 := 0;
  constant c_7ffd_port_msb_bit     : integer range 0 to 31 := 15;
  constant c_7ffd_port_lsb_bit     : integer range 0 to 31 := 8;
  constant c_1ffd_port_msb_bit     : integer range 0 to 31 := 23;
  constant c_1ffd_port_lsb_bit     : integer range 0 to 31 := 16;
  constant c_tape_fifo_msb_bit     : integer range 0 to 31 := 15;
  constant c_tape_fifo_lsb_bit     : integer range 0 to 31 := 0;
  constant c_tape_fifo_empty_bit   : integer range 0 to 31 := 31;
  constant c_tape_fifo_full_bit    : integer range 0 to 31 := 30;
  
  -- ZX I/O ports
  signal s_spec_port_fe : std_logic_vector(7 downto 0);
  signal s_border_color : std_logic_vector(2 downto 0) := (others => '1');
  signal s_border_stb : std_logic := '0';
  signal s_speaker : std_logic;
  signal s_tape_in : std_logic;
  signal s_keyboard_1 : std_logic_vector(19 downto 0) := (others => '1');
  signal s_keyboard_2 : std_logic_vector(19 downto 0) := (others => '1');
  signal s_spec_port_7ffd : std_logic_vector(7 downto 0);
  signal s_spec_port_1ffd : std_logic_vector(7 downto 0); -- Scorpion
  
  signal s_ram_page: std_logic_vector(7 downto 0);

  -- TAPE FIFO
  signal s_tape_fifo_din : std_logic_vector(15 downto 0);
  signal s_tape_fifo_dout : std_logic_vector(15 downto 0);
  signal s_tape_fifo_wr_en : std_logic := '0';
  signal s_tape_fifo_empty : std_logic := '0';
  signal s_tape_fifo_full : std_logic := '0';
  signal s_tape_fifo_rd_en : std_logic := '0';
  signal s_tape_fifo_underflow : std_logic := '0';
  signal s_tape_fifo_overflow : std_logic := '0';


  component fifo_1024_16
    port ( 
      clk : in std_logic;
      rst : in std_logic;
      din : in std_logic_vector(15 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(15 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      underflow : out std_logic
    );
  end component;

  
begin

  i_tape_fifo : fifo_1024_16
    port map (
      clk => i_aclk,
      rst => not i_resetn,
      din => s_tape_fifo_din,
      wr_en => s_tape_fifo_wr_en,
      rd_en => s_tape_fifo_rd_en,
      dout => s_tape_fifo_dout,
      full => s_tape_fifo_full,
      overflow => s_tape_fifo_overflow,
      empty => s_tape_fifo_empty,
      underflow => s_tape_fifo_underflow
    );


  i_z80 : entity work.t80se
    port map(
      RESET_n => not (s_cpu_reset or s_reset),
      CLK_n   => i_aclk,
      CLKEN   => s_cpu_clk_en,
      WAIT_n  => '1',
      INT_n   => s_cpu_int,
      NMI_n   => s_cpu_nmi,
      BUSRQ_n => '1',
      M1_n    => s_cpu_m1,
      MREQ_n  => s_cpu_mreq,
      IORQ_n  => s_cpu_iorq,
      RD_n    => s_cpu_rd,
      WR_n    => s_cpu_wr,
      RFSH_n  => s_cpu_rfsh,
      HALT_n  => open,
      BUSAK_n => open,
      A       => s_cpu_a,
      DO      => s_cpu_dout,
      DI      => s_cpu_din,
		
      SavePC => s_cpu_save_pc,
      SaveINT => s_cpu_save_int,
      RestorePC => s_cpu_restore_pc,
      RestoreINT => s_cpu_restore_int,
			
      RestorePC_n => s_cpu_restore_pc_n
    );				

  s_reset <= not i_resetn;
  o_zx_bus_mem_req <= s_zx_bus_mem_req;
  o_zx_bus_mem_wr <= s_zx_bus_mem_wr;

  -- Temporary pulled high as not used in simplified implementation
  s_cpu_nmi <= '1';

  i_zx_sound : entity work.zx_sound_top
    port map(
      i_clk => i_aclk,
      i_resetn => i_resetn,
      i_audio_beeper => s_speaker,
      i_weight_audio_beeper => c_weight_audio_beeper,
      i_audio_tape => s_tape_in,
      i_weight_audio_tape => c_weight_audio_tape,

      -- AY
      i_reset_l => not (s_cpu_reset or s_reset),
      i_ena => s_clk_ay and not s_cpu_halt_req,
      i_da => s_ay_din,
      o_da => s_ay_dout, 
      i_busctrl_addr => s_ay_addr,
      i_busctrl_we => s_ay_wr,
      i_busctrl_re => s_ay_rd,
      i_ctrl_aymode => s_ay_ym_mode,

      o_audio_pwm => o_aud_pwm
    );

  s_ay_din <= s_cpu_dout;


  -- 'End of video frame' interrupt logic
  p_int_generator : process(i_aclk)
  begin
    if rising_edge(i_aclk) then
      if (i_resetn = '0') then
        s_cpu_int <= '1';
      else
        if (i_new_frame_int = '1') then
          s_cpu_int <= '0'; 
        end if;
       if (s_cpu_iorq = '0') and (s_cpu_m1 = '0') then
         -- interrupt acknowledgement
         s_cpu_int <= '1';
       end if;
      end if;
    end if;
  end process;


  -- Tape loader emulation
  p_tape_in : process(i_aclk)
    variable v_tape_counter : unsigned(14 downto 0) := (others => '0');
    variable v_tape_pulse : std_logic := '1';
  begin
    if rising_edge(i_aclk) then
      if v_tape_counter > 0 then 
        if v_tape_pulse = '1' then
          if s_clk35m = '1' and s_cpu_halt_ack = '0' and s_cpu_mem_wait = '0' then
            v_tape_counter := v_tape_counter - 1;
            if v_tape_counter = 0 then
              s_tape_in <= not s_tape_in;
            end if;
          end if;
        else
          if s_clk35m = '1' then
            v_tape_counter := v_tape_counter - 1;
            if v_tape_counter = 0 then
              s_tape_in <= '0';
            end if;
          end if;				
        end if;
      end if;

      s_tape_fifo_rd_en <= '0';
      if v_tape_counter = 0 then
        if s_tape_fifo_empty = '0' then
          v_tape_counter := unsigned(s_tape_fifo_dout(14 downto 0));
          v_tape_pulse := s_tape_fifo_dout(15);
          s_tape_fifo_rd_en <= '1';
        else
          v_tape_counter := (others => '1');
          v_tape_pulse := '0';
        end if;
      end if;
    end if;
  end process;


  -- manipulate clock enable in such a way that it makes Z80
  -- work as if it is clocked at much lower rate
  p_clk_en_generator : process(i_aclk)
    variable v_div_counter7 : unsigned(15 downto 0) := x"0000";
    variable v_mul_counter7 : unsigned(7 downto 0) := x"00";
    variable v_freq_div : integer;
  begin
    if rising_edge(i_aclk) then
      -- count 10 times faster so it makes the frequency 1428.57132 MHz
      v_div_counter7 := v_div_counter7 + 10;
      s_clk7m <= '0';
      s_clk35m <= '0';
      s_clk_ay <= '0';
      -- now divider makes it 1428.57132 MHz / 204 = 7.002800 Mhz
      v_freq_div := 204;
			
      if v_div_counter7 >= v_freq_div then
        v_div_counter7 := v_div_counter7 - v_freq_div;
        v_mul_counter7 := v_mul_counter7 + 1;
        s_clk7m <= '1';
        if v_mul_counter7(0) = '0' then
          s_clk35m <= '1';
        end if;
        if v_mul_counter7(1 downto 0) = "00" then
          s_clk_ay <= '1';
        end if;
      end if;
    end if;
  end process;    


  -- Generates HALT ACK
  p_halt_ack_generator : process(i_aclk)
    variable v_cpu_save_int7_prev : std_logic := '0';
  begin
    if rising_edge(i_aclk) then
      -- Just a stub for now
      if (s_cpu_mem_wait = '0') and (s_cpu_halt_req = '1') and 
         (s_cpu_halt_ack = '0') and (s_cpu_save_int(7) = '0') and 
         (v_cpu_save_int7_prev  = '1') then
        s_cpu_halt_ack <= '1';
      end if;
      v_cpu_save_int7_prev := s_cpu_save_int(7);
      if (s_cpu_halt_ack = '1') and (s_cpu_halt_req = '0') then
        s_cpu_halt_ack <= '0';
      end if;
    end if;
  end process;    


  -- Main ZX Spectrum state machine. 
  -- Specifies memory and IO ports configuration
  p_zx_main_fsm : process(i_aclk)
    variable v_cpu_wr_vec : std_logic_vector(1 downto 0);
    variable v_cpu_rd_vec : std_logic_vector(1 downto 0);		
  begin
    if rising_edge(i_aclk) then

      if (i_resetn = '0') then
        s_cpu_reset <= '0';
        s_cpu_halt_req <= '0';
        s_spec_port_1ffd <= x"00";
        s_spec_port_7ffd <= x"00";
        s_spec_port_fe <= x"00";
        s_cpu_restore_pc <= x"0000";
        s_cpu_restore_int <= x"00";
        s_cpu_restore_pc_n <= '0';
        s_keyboard_1 <= (others => '1');
        s_keyboard_2 <= (others => '1');
        s_tape_fifo_wr_en <= '0';
        s_selected_ay2 <= '0';
      else
        s_tape_fifo_wr_en <= '0';
        if i_wr_en = '1' then
          if i_zx_control_en = '1' then
            s_cpu_halt_req <= i_register_data_out(c_control_reg_cpu_halt_bit);
            s_cpu_reset <= i_register_data_out(c_control_reg_cpu_reset_bit);
            s_cpu_restore_pc <= i_register_data_out(c_control_reg_cpu_pc_msb_bit downto c_control_reg_cpu_pc_lsb_bit);
            s_cpu_restore_int <= i_register_data_out(c_control_reg_cpu_int_msb_bit downto c_control_reg_cpu_int_lsb_bit);
            s_cpu_restore_pc_n <= i_register_data_out(c_control_reg_cpu_restore_pc_n_bit);
          elsif i_zx_keyboard_1_en = '1' then
            s_keyboard_1 <= i_register_data_out(19 downto 0);
          elsif i_zx_keyboard_2_en = '1' then
            s_keyboard_2 <= i_register_data_out(19 downto 0);
          elsif i_zx_io_ports_en = '1' then
            s_spec_port_1ffd <= i_register_data_out(c_1ffd_port_msb_bit downto c_1ffd_port_lsb_bit);
            s_spec_port_7ffd <= i_register_data_out(c_7ffd_port_msb_bit downto c_7ffd_port_lsb_bit);
            s_spec_port_fe <= i_register_data_out(c_fe_port_msb_bit downto c_fe_port_lsb_bit);
          elsif i_zx_tape_fifo_en = '1' then
            s_tape_fifo_din <= i_register_data_out(c_tape_fifo_msb_bit downto c_tape_fifo_lsb_bit);
            s_tape_fifo_wr_en <= '1';
          end if;
        end if;

        if i_rd_en = '1' then
           o_zx_io_ports <= x"00" & s_spec_port_1ffd & s_spec_port_7ffd & s_spec_port_fe;
           o_zx_control <= s_cpu_halt_req & "00" & s_cpu_reset & "0000" & s_cpu_save_pc & s_cpu_save_int;
           o_zx_tape_fifo <= s_tape_fifo_empty & s_tape_fifo_full & s_tape_fifo_overflow & s_tape_fifo_underflow & x"0000000";
        end if;
      end if;

      v_cpu_wr_vec := v_cpu_wr_vec(0) & s_cpu_wr;
      v_cpu_rd_vec := v_cpu_rd_vec(0) & s_cpu_rd;

      if s_cpu_wr /= '0' then
        s_ay_addr <= '0';
        s_ay_wr <= '0';
      end if;

      if s_cpu_rd /= '0' then
        s_cpu_din <= (others => '1');
        s_ay_rd <= '0';
      elsif (s_ay_rd = '1') then
        -- keep the data bus up to date 
        -- while read operation is active
        s_cpu_din <= s_ay_dout;
      end if;

      s_border_stb <= '0';
      if v_cpu_wr_vec = "10" then
        if s_cpu_mreq = '0' then
          -- Writing to memory
          o_zx_bus_address <= "00" & s_ram_page & s_cpu_a(13 downto 0);
          o_zx_bus_data <= s_cpu_dout;
          s_zx_bus_mem_wr <= '1';
          s_zx_bus_mem_req <= '1';
          s_cpu_mem_wait <= '1';
        elsif s_cpu_iorq = '0' and s_cpu_m1 = '1' then
          -- Writing to IO ports
          if s_cpu_a(7 downto 0) = x"FE" then
            s_spec_port_fe <= s_cpu_dout;
            s_border_color <= s_cpu_dout(2 downto 0);
            s_border_stb <= '1';
            s_speaker <= s_cpu_dout(c_speaker_bit);
          elsif s_cpu_a(15 downto 14) = "11" and s_cpu_a(1 downto 0) = "01" then --ayMode /= AY_MODE_NONE and 
            s_ay_addr <= '1';
            if s_cpu_dout = x"FE" then 
              s_selected_ay2 <= '1';
            elsif s_cpu_dout = x"FF" then
              s_selected_ay2 <= '0';
            end if;
          elsif s_cpu_a(15 downto 14) = "10" and s_cpu_a(1 downto 0) = "01" then --ayMode /= AY_MODE_NONE and 
            if s_turbo_sound = '1' and s_selected_ay2 = '1' then
              -- no second AY as of now
            else
              s_ay_wr <= '1';
            end if;	
          elsif s_cpu_a(15) = '0' and s_cpu_a(7 downto 0) = x"fd" and s_spec_port_7ffd(5) = '0' then
            s_spec_port_7ffd <= s_cpu_dout;
          end if;
        end if;
      end if;
 
      if v_cpu_rd_vec = "10" then
        if s_cpu_mreq = '0' then
          -- Reading from memory
          o_zx_bus_address <= "00" & s_ram_page & s_cpu_a(13 downto 0);
          s_zx_bus_mem_wr <= '0';
          s_zx_bus_mem_req <= '1';
          s_cpu_mem_wait <= '1';
        elsif s_cpu_iorq = '0' and s_cpu_m1 = '1' then
          -- Reading from IO ports
          if s_cpu_a(7 downto 0) = x"FE" then
            if s_cpu_a(8) = '0' then
              s_cpu_din <= '1' & s_tape_in & '1' & s_keyboard_1(19 downto 15);
            elsif s_cpu_a(9) = '0' then
              s_cpu_din <= '1' & s_tape_in & '1' & s_keyboard_1(14 downto 10);
            elsif s_cpu_a(10) = '0' then
              s_cpu_din <= '1' & s_tape_in & '1' & s_keyboard_1(9 downto 5);
            elsif s_cpu_a(11) = '0' then
              s_cpu_din <= '1' & s_tape_in & '1' & s_keyboard_1(4 downto 0);

            elsif s_cpu_a(12) = '0' then
              s_cpu_din <= '1' & s_tape_in & '1' & s_keyboard_2(19 downto 15);
            elsif s_cpu_a(13) = '0' then
              s_cpu_din <= '1' & s_tape_in & '1' & s_keyboard_2(14 downto 10);
            elsif s_cpu_a(14) = '0' then
              s_cpu_din <= '1' & s_tape_in & '1' & s_keyboard_2(9 downto 5);
            elsif s_cpu_a(15) = '0' then
              s_cpu_din <= '1' & s_tape_in & '1' & s_keyboard_2(4 downto 0);
            else
              s_cpu_din <= (others => '1');
            end if;
          elsif s_cpu_a(7 downto 0) = x"1F" then
            -- kempston joystick
            s_cpu_din <= (others => '1');
          elsif s_cpu_a(15 downto 14) = "11" and s_cpu_a(1 downto 0) = "01" then --ayMode /= AY_MODE_NONE and 
            -- AY-3-8910
            if s_turbo_sound = '1' and s_selected_ay2 = '1' then
              --
            else
              s_ay_rd <= '1';
            end if;							
          elsif s_cpu_a(7 downto 0) = x"FF" then
            s_cpu_din <= i_ula_attr;
          end if;
        end if;
      end if;

      if (s_zx_bus_mem_req = '1') and (i_zx_bus_mem_ack = '1') then
        -- Handle memory read response
        if (s_zx_bus_mem_wr = '0') then
          s_cpu_din <= i_zx_bus_data;
        end if;
        s_zx_bus_mem_req <= '0';
        s_zx_bus_mem_wr <= '0';
        s_cpu_mem_wait <= '0';
      end if;			

    end if;
  end process;  
  
  s_cpu_wait <= s_cpu_mem_wait or s_cpu_halt_ack;
  s_cpu_clk_en <= s_clk35m and not s_cpu_wait;

  -- Border color and strobe signals for the videocontroller
  o_border_color <= s_border_color;
  o_border_stb <= s_border_stb;

  -- Reserve first 4 x 16K pages (64K) for ROM emulation 
  -- so real Spectrum RAM would start from the 5-th page.
  -- As of now, only 2 x 16K pages are emulated as ROM
  s_ram_page <= "0000000" & s_spec_port_7ffd(4) when s_cpu_a(15 downto 14) = "00" else
    "00001001" when s_cpu_a(15 downto 14) = "01" else
    "00000110" when s_cpu_a(15 downto 14) = "10" else
    std_logic_vector(unsigned("00000" & s_spec_port_7ffd(2 downto 0)) + 4);

  -- When asserted activates shadow videopage ('page 7' in 128K notation)
  o_shadow_vram <= s_spec_port_7ffd(3);

  -- ARTY Z7 hardware specific: enable audio output
  o_aud_sd <= '1';
  
end architecture;
