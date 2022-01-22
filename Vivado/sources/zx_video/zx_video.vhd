----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 07/24/2021 09:55:52 PM
-- Design Name: ZX Spectrum Videocontroller 
-- Module Name: zx_video - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as a drop in replacement for
-- the standard AXI Video Direct Memory Access IP Core from Xilinx to emulate
-- functionality of the standard ZX Spectrum video controller
-- 
-- Dependencies: fifo_512_64, zx_ctrl
-- 
-- Revision:
-- Revision 0.02 - Fully functional emulation of ZX Spectrum's video controller
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zx_video is
    generic (
      g_max_hor_resolution_bits : integer := 11;
      g_color_component_width : integer := 8;
      g_axi_data_width : integer := 64;
      g_axi_addr_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_max_h_screen_res : integer := 1920;
      g_max_v_screen_res : integer := 1280
    );
    port ( 
      i_axi_resetn : in std_logic;
      i_axis_mm2s_aclk : in std_logic;
      i_axi_lite_aclk : in std_logic;
      -- memory to stream video interface
      i_axis_mm2s_tready : in std_logic;
      o_axis_mm2s_tdata : out std_logic_vector(g_color_component_width * 3 - 1 downto 0);
      o_axis_mm2s_tlast : out std_logic;
      o_axis_mm2s_tuser : out std_logic;
      o_axis_mm2s_tvalid : out std_logic;
      -- AXI
      o_axi_mm2s_araddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_mm2s_arburst : out std_logic_vector(1 downto 0);
      o_axi_mm2s_arcache : out std_logic_vector(3 downto 0);
      o_axi_mm2s_arlen : out std_logic_vector(7 downto 0);
      o_axi_mm2s_arprot : out std_logic_vector(2 downto 0);
      i_axi_mm2s_arready : in std_logic;
      o_axi_mm2s_arsize : out std_logic_vector(2 downto 0);
      o_axi_mm2s_arvalid : out std_logic;
      i_axi_mm2s_rdata : in std_logic_vector(g_axi_data_width - 1 downto 0);
      i_axi_mm2s_rlast : in std_logic;
      o_axi_mm2s_rready : out std_logic;
      i_axi_mm2s_rresp : in std_logic_vector(1 downto 0);
      i_axi_mm2s_rvalid : in std_logic;
      -- Registers
      i_rd_en : in std_logic;
      i_wr_en : in std_logic;
      i_register_data_out : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_active_size : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_active_size_en : in std_logic;
      o_border_size : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_border_size_en : in std_logic;
      o_zx_aux_attr : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_zx_aux_attr_en : in std_logic;
      o_zx_border_color : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_zx_border_color_en : in std_logic;
      o_zx_bitmap_addr : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_zx_bitmap_addr_en : in std_logic;
      o_zx_color_addr : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_zx_color_addr_en : in std_logic;
      o_status : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_status_en : in std_logic;
      o_control : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_control_en : in std_logic;
      o_error : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_error_en : in std_logic;
      o_irq : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_irq_en : in std_logic;

      i_border_color : in std_logic_vector(2 downto 0);
      i_border_stb : in std_logic;
      o_new_frame_int : out std_logic;
      o_ula_attr : out std_logic_vector(7 downto 0);
      i_shadow_vram : in std_logic
    );
    
end zx_video;

architecture rtl of zx_video is

  -- Videostream generator
  type t_sm_videostream is (s_vs_idle, s_vs_streaming, s_vs_eol);
  type t_sm_color_gen is (s_cg_idle, s_cg_test_pattern, s_cg_top_border, s_cg_left_border, s_cg_active_pixel_area, s_cg_right_border, s_cg_bottom_border);
  -- Registers
  type t_sm_reg_copy_over is (s_rc_idle, s_rc_copy, s_rc_end);

  -- Videostream generator  
  constant c_horizontal_resolution        : integer range 640 to g_max_h_screen_res := 1280;
  constant c_vertical_resolution          : integer range 480 to g_max_v_screen_res := 720;
  constant c_zx_spec_h_resolution         : integer range 0 to 257 := 256;
  constant c_zx_spec_v_resolution         : integer range 0 to 193 := 192;
  constant c_zx_spec_scaling_factor       : integer range 0 to 7 := 3;
  constant c_zx_spec_border_color         : integer range 0 to 7 := 0;
  constant c_zx_spec_h_border_size        : integer range 0 to 960 := (c_horizontal_resolution - (c_zx_spec_h_resolution * c_zx_spec_scaling_factor)) / 2;
  constant c_zx_spec_v_border_size        : integer range 0 to 640 := (c_vertical_resolution - (c_zx_spec_v_resolution * c_zx_spec_scaling_factor)) / 2;
  constant c_byte_max_brightness_val      : std_logic_vector(g_color_component_width - 1 downto 0) := x"FF";
  constant c_byte_half_brightness_val     : std_logic_vector(g_color_component_width - 1 downto 0) := x"D8"; -- around 85% from 0xFF as per ZX Spectrum documenation
  constant c_byte_min_val                 : std_logic_vector(g_color_component_width - 1 downto 0) := (others => '0');
  -- Test pattern
  constant c_color_bar_scan_lines         : integer   := 256;
  constant c_horiz_ramp_scan_lines        : integer   := 320;
  -- AMBA specific (DMA)
  constant c_axi_arsize                   : integer range 0 to 7 := 3; -- burst size. '3' means 8 bytes per transfer
  constant c_axi_arlen                    : integer range 0 to 7 := 3; -- burst length. '3' means 4 transfers in a burst
  constant c_axi_arburst                  : integer range 0 to 3 := 1; -- burst type. '1' means incrementing
  constant c_axi_ram_bitmap_data_address  : integer := 134217728; -- default address of the ZX Spectrum bitmap memory
  constant c_axi_ram_color_attr_address   : integer := 134223872; -- default address of the ZX Spectrum color attribute data
  constant c_shadow_vram_page_offset      : integer := 32768; -- offset between vram address in bank 5 and bank 7 for 128K model
  -- Pixel address space
  constant c_zx_pixel_data_per_scan_line  : integer range 0 to 33 := c_zx_spec_h_resolution / 8;
  constant c_zx_pixel_address_space       : integer range 0 to 6145 := c_zx_pixel_data_per_scan_line * c_zx_spec_v_resolution;
  -- Color attr address space
  constant c_zx_color_attr_per_scan_line  : integer range 0 to 33 := c_zx_spec_h_resolution / 8;
  constant c_zx_color_attr_brightness_bit : integer range 0 to 7 := 6;
  constant c_zx_color_attr_flash_bit      : integer range 0 to 7 := 7;
  -- Registers
  constant c_control_reg_sw_enable_bit    : integer range 0 to 31 := 0;
  constant c_control_reg_update_bit       : integer range 0 to 31 := 1;
  constant c_control_reg_bypass_bit       : integer range 0 to 31 := 4;
  constant c_control_reg_test_patt_bit    : integer range 0 to 31 := 5;
  constant c_control_reg_latch_brd_clr_bit: integer range 0 to 31 := 30;
  constant c_control_reg_sw_reset_bit     : integer range 0 to 31 := 31;
  constant c_control_reg_default : std_logic_vector(g_axi_lite_data_width - 1 downto 0) := x"00000011";
  constant c_hor_active_size_msb_bit      : integer range 0 to 31 := 15;
  constant c_hor_active_size_lsb_bit      : integer range 0 to 31 := 0;
  constant c_ver_active_size_msb_bit      : integer range 0 to 31 := 31;
  constant c_ver_active_size_lsb_bit      : integer range 0 to 31 := 16;
  constant c_hor_border_size_msb_bit      : integer range 0 to 31 := 15;
  constant c_hor_border_size_lsb_bit      : integer range 0 to 31 := 0;
  constant c_ver_border_size_msb_bit      : integer range 0 to 31 := 31;
  constant c_ver_border_size_lsb_bit      : integer range 0 to 31 := 16;
  constant c_scaling_factor_msb_bit       : integer range 0 to 31 := 2;
  constant c_scaling_factor_lsb_bit       : integer range 0 to 31 := 0;
  constant c_reg_update_immediate_bit     : integer range 0 to 1  := 1;
  constant c_reg_update_defferred_bit     : integer range 0 to 1  := 0;
  constant c_border_color_msb_bit         : integer range 0 to 31 := 2;
  constant c_border_color_lsb_bit         : integer range 0 to 31 := 0;
  constant c_border_color_r_bit           : integer range 0 to 2  := 1;
  constant c_border_color_g_bit           : integer range 0 to 2  := 2;
  constant c_border_color_b_bit           : integer range 0 to 2  := 0;
  
  -- Videostream generator
  signal s_sm_videostream : t_sm_videostream := s_vs_idle;
  signal s_axis_mm2s_tvalid : std_logic;
  signal s_start_of_frame : std_logic;
  signal s_end_of_line : std_logic;
  signal s_horiz_count : unsigned(g_max_hor_resolution_bits - 1 downto 0);
  signal s_vert_count : unsigned(g_max_hor_resolution_bits - 1 downto 0);
  signal s_red_component : std_logic_vector(g_color_component_width - 1 downto 0);
  signal s_green_component : std_logic_vector(g_color_component_width - 1 downto 0);
  signal s_blue_component : std_logic_vector(g_color_component_width - 1  downto 0);
  signal s_pixel_data_dout_56 : std_logic;
  signal s_color_attr_dout_63_56 : std_logic_vector(7 downto 0);
  signal s_zx_pixel : std_logic;
  signal s_zx_color_attr : std_logic_vector(g_axi_data_width - 1 downto 0);
  signal s_zx_border_red_component : std_logic_vector(g_color_component_width - 1 downto 0);
  signal s_zx_border_green_component : std_logic_vector(g_color_component_width - 1 downto 0);
  signal s_zx_border_blue_component : std_logic_vector(g_color_component_width - 1 downto 0);
  signal s_horiz_repeater : unsigned(2 downto 0);
  signal s_frame_counter : unsigned(5 downto 0);
  signal s_horizontal_resolution : integer range 640 to g_max_h_screen_res;
  signal s_vertical_resolution : integer range 480 to g_max_v_screen_res;
  signal s_zx_spec_h_border_left_pos : integer range 0 to 960;
  signal s_zx_spec_v_border_top_pos : integer range 0 to 640;
  signal s_zx_spec_h_border_right_pos : integer range 0 to g_max_h_screen_res;
  signal s_zx_spec_v_border_bottom_pos : integer range 0 to g_max_v_screen_res;
  signal s_sm_color_gen : t_sm_color_gen := s_cg_idle;
  signal s_zx_spec_scaling_factor : integer range 0 to 7;
  signal s_color_intensity : std_logic_vector(g_color_component_width - 1 downto 0);
  signal s_new_frame_int : std_logic;
  signal s_ula_attr : std_logic_vector(7 downto 0);
  -- Test pattern
  signal s_horiz_count_vec : std_logic_vector(g_max_hor_resolution_bits - 1 downto 0);
  signal s_vert_ramp_vec : std_logic_vector(g_max_hor_resolution_bits - 1 downto 0);
  -- AMBA specific (DMA)
  type t_state_amba is (t_idle_amba, t_set_addr_amba, t_wait_addr_ack_amba, t_wait_data_start_amba, t_read_amba, t_error_amba, t_done_amba);
  signal s_state_amba : t_state_amba := t_idle_amba;
  signal s_pixel_attr_selector : std_logic;
  signal s_axi_mm2s_arcache : std_logic_vector(3 downto 0) := "0011";
  signal s_amba_vert_count : unsigned(7 downto 0);
  signal s_amba_pixel_repeater : unsigned(2 downto 0);
  signal s_amba_color_attr_repeater : unsigned(2 downto 0);
  signal s_ram_bitmap_data_address : unsigned(g_axi_lite_data_width - 1 downto 0); -- address of the ZX Spectrum bitmap memory
  signal s_ram_color_attr_address : unsigned(g_axi_lite_data_width - 1 downto 0); -- address of the ZX Spectrum color attribute data
  -- Pixel data FIFO
  signal s_pixel_data_dout : std_logic_vector(g_axi_data_width - 1 downto 0);
  signal s_pixel_data_fifo_full : std_logic;
  signal s_pixel_data_fifo_empty : std_logic;
  signal s_pixel_data_fifo_overflow : std_logic;
  signal s_pixel_data_fifo_underflow : std_logic;
  signal s_pixel_data_fifo_wr_en : std_logic;
  signal s_pixel_data_fifo_rd_en : std_logic;
  signal s_pixel_data_fifo_prog_empty : std_logic;
  signal s_pixel_data_fifo_prog_full : std_logic;
  -- Color attribute FIFO
  signal s_color_attr_dout : std_logic_vector(g_axi_data_width - 1 downto 0);
  signal s_color_attr_fifo_full : std_logic;
  signal s_color_attr_fifo_empty : std_logic;
  signal s_color_attr_fifo_overflow : std_logic;
  signal s_color_attr_fifo_underflow : std_logic;
  signal s_color_attr_fifo_wr_en : std_logic;
  signal s_color_attr_fifo_prog_empty : std_logic;
  signal s_color_attr_fifo_prog_full : std_logic;
  -- Pixel address signals
  signal s_pixel_address : unsigned(g_axi_addr_width - 1 downto 0); -- range from 0 to c_zx_pixel_address_space starting from c_axi_ram_bitmap_data_address
  signal s_active_pixel_count : unsigned(7 downto 0);
  signal s_active_pix_reversed_3lsb : unsigned(5 downto 0);
  -- Color attribute address signals
  signal s_color_attr_address : unsigned(g_axi_addr_width - 1 downto 0);
  signal s_color_attr_count : integer range 0 to 255;
  signal s_color_attr_offset : unsigned(9 downto 0);
  signal s_flash_attr_offset : integer range 0 to 3;
  -- Registers
  signal s_sw_enable : std_logic;
  signal s_reg_update : integer range 0 to 1;
  signal s_test_pattern : std_logic;
  signal s_reg_change_pending : std_logic_vector(1 downto 0);
  signal s_reg_change_ack : std_logic;
  signal s_fifo_flush_req : std_logic_vector(1 downto 0);
  signal s_sm_reg_copy_over : t_sm_reg_copy_over := s_rc_idle;

  signal s_active_size_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_border_size_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_aux_attr_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_border_color_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_bitmap_addr_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_color_addr_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_bitmap_addr_2 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_color_addr_2 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_status_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_control_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_error_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_irq_1 : std_logic_vector(g_axi_lite_data_width - 1 downto 0);

  signal s_shadow_vram_offset : unsigned(15 downto 0);
  signal s_prev_border_color : std_logic_vector(2 downto 0);

  
  component fifo_512_64
    port (
      clk : in std_logic;
      rst : in std_logic;
      din : in std_logic_vector(g_axi_data_width - 1 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(g_axi_data_width - 1 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      underflow : out std_logic;
      prog_full : out std_logic;
      prog_empty : out std_logic
    );
  end component;

begin

  i_pixel_data_fifo : fifo_512_64
    port map (
      clk => i_axis_mm2s_aclk,
      rst => (not i_axi_resetn) or (not s_sw_enable) or (s_fifo_flush_req(c_reg_update_immediate_bit)),
      din => i_axi_mm2s_rdata,
      wr_en => s_pixel_data_fifo_wr_en,
      rd_en => s_pixel_data_fifo_rd_en,
      dout => s_pixel_data_dout,
      full => s_pixel_data_fifo_full,
      overflow => s_pixel_data_fifo_overflow,
      empty => s_pixel_data_fifo_empty,
      underflow => s_pixel_data_fifo_underflow,
      prog_full => s_pixel_data_fifo_prog_full,
      prog_empty => s_pixel_data_fifo_prog_empty
    );

  i_color_attr_fifo : fifo_512_64
    port map (
      clk => i_axis_mm2s_aclk,
      rst => (not i_axi_resetn) or (not s_sw_enable) or (s_fifo_flush_req(c_reg_update_immediate_bit)),
      din => i_axi_mm2s_rdata,
      wr_en => s_color_attr_fifo_wr_en,
      rd_en => s_pixel_data_fifo_rd_en,
      dout => s_color_attr_dout,
      full => s_color_attr_fifo_full,
      overflow => s_color_attr_fifo_overflow,
      empty => s_color_attr_fifo_empty,
      underflow => s_color_attr_fifo_underflow,
      prog_full => s_color_attr_fifo_prog_full,
      prog_empty => s_color_attr_fifo_prog_empty
    );

  s_pixel_data_fifo_wr_en <= i_axi_mm2s_rvalid when s_pixel_attr_selector = '0' else '0';
  s_color_attr_fifo_wr_en <= i_axi_mm2s_rvalid when s_pixel_attr_selector = '1' else '0';

  -- This process switches between original ZX 48 and shadow ZX 128 videopages
  p_shadow_vpage_handler: process(i_axis_mm2s_aclk) is
  begin
    if rising_edge(i_axis_mm2s_aclk) then
      if i_shadow_vram = '0' then
        s_shadow_vram_offset <= (others => '0');
      else
        s_shadow_vram_offset <= to_unsigned(c_shadow_vram_page_offset, s_shadow_vram_offset'length);
      end if;
    end if;
  end process;

  -- This process latches register values upon activation of WR_EN and one of
  -- _EN signals
  p_latching_registers: process(i_axis_mm2s_aclk) is
  begin
    if rising_edge(i_axis_mm2s_aclk) then
      if (i_axi_resetn = '0') then
        -- Set registers to default values immediately after reset
        s_active_size_1(c_hor_active_size_msb_bit downto c_hor_active_size_lsb_bit) <= 
          std_logic_vector(to_unsigned(c_horizontal_resolution, c_hor_active_size_msb_bit - c_hor_active_size_lsb_bit + 1));
        s_active_size_1(c_ver_active_size_msb_bit downto c_ver_active_size_lsb_bit) <= 
          std_logic_vector(to_unsigned(s_vertical_resolution, c_ver_active_size_msb_bit - c_ver_active_size_lsb_bit + 1));
        s_border_size_1(c_hor_border_size_msb_bit downto c_hor_border_size_lsb_bit) <=
          std_logic_vector(to_unsigned(c_zx_spec_h_border_size, c_hor_border_size_msb_bit - c_hor_border_size_lsb_bit + 1));
        s_border_size_1(c_ver_border_size_msb_bit downto c_ver_border_size_lsb_bit) <=
          std_logic_vector(to_unsigned(c_zx_spec_v_border_size, c_ver_border_size_msb_bit - c_ver_border_size_lsb_bit + 1));
        s_zx_aux_attr_1(c_scaling_factor_msb_bit downto c_scaling_factor_lsb_bit) <= 
          std_logic_vector(to_unsigned(c_zx_spec_scaling_factor, c_scaling_factor_msb_bit - c_scaling_factor_lsb_bit + 1));
        s_zx_border_color_1(c_border_color_msb_bit downto c_border_color_lsb_bit) <= 
          std_logic_vector(to_unsigned(c_zx_spec_border_color, c_border_color_msb_bit - c_border_color_lsb_bit + 1));
        s_zx_color_addr_1 <= std_logic_vector(to_unsigned(c_axi_ram_color_attr_address, s_zx_color_addr_1'length));
        s_zx_bitmap_addr_1 <= std_logic_vector(to_unsigned(c_axi_ram_bitmap_data_address, s_zx_bitmap_addr_1'length));
        s_control_1 <= c_control_reg_default;
        s_reg_change_pending <= (others => '0');
        s_fifo_flush_req <= (others => '0');
        s_reg_update <= 1;
        s_test_pattern <= '0';
      else
        if i_wr_en = '1' then
          if i_active_size_en = '1' then
            s_active_size_1 <= i_register_data_out;
            s_reg_change_pending(s_reg_update) <= '1';
            s_fifo_flush_req(s_reg_update) <= '1';
          elsif i_border_size_en = '1' then
            -- Border size doesn't require FIFOs to flush
            s_border_size_1 <= i_register_data_out;
            s_reg_change_pending(s_reg_update) <= '1';
          elsif i_zx_aux_attr_en = '1' then
            s_zx_aux_attr_1 <= i_register_data_out;
            s_reg_change_pending(s_reg_update) <= '1';
            s_fifo_flush_req(s_reg_update) <= '1';
          elsif i_zx_border_color_en = '1' then
            -- change the border color immedeately, no need to 
            -- synchronise with the end of frame so no register
            -- double buffering either
            s_zx_border_color_1 <= i_register_data_out;
          elsif i_zx_bitmap_addr_en = '1' then
            s_zx_bitmap_addr_1 <= i_register_data_out;
            s_reg_change_pending(s_reg_update) <= '1';
          elsif i_zx_color_addr_en = '1' then
            s_zx_color_addr_1 <= i_register_data_out;
            s_reg_change_pending(s_reg_update) <= '1';
          elsif i_status_en = '1' then
            s_status_1 <= i_register_data_out;
          elsif i_control_en = '1' then
            if i_register_data_out(c_control_reg_sw_enable_bit) = '1' then
              s_control_1 <= i_register_data_out;
              if s_reg_update = 0 and i_register_data_out(c_control_reg_update_bit) = '1' then
                -- As soon as reg_update becomes asserted again copy defferred states of the s_reg_change_pending
                -- and s_fifo_flush_req to immediate ones
                s_reg_change_pending(c_reg_update_immediate_bit) <= s_reg_change_pending(c_reg_update_defferred_bit);
                s_reg_change_pending(c_reg_update_defferred_bit) <= '0';
                s_fifo_flush_req(c_reg_update_immediate_bit) <= s_fifo_flush_req(c_reg_update_defferred_bit);
                s_fifo_flush_req(c_reg_update_defferred_bit) <= '0';
              end if; 
              s_reg_update <= 1 when i_register_data_out(c_control_reg_update_bit) = '1' else 0;
              s_test_pattern <= i_register_data_out(c_control_reg_test_patt_bit);
              if (i_register_data_out(c_control_reg_latch_brd_clr_bit) = '1') then
                s_prev_border_color <= s_zx_border_color_1(c_border_color_msb_bit downto c_border_color_lsb_bit);
              else
                s_zx_border_color_1(c_border_color_msb_bit downto c_border_color_lsb_bit) <= s_prev_border_color;
              end if;
            end if;
          elsif i_error_en = '1' then
            s_error_1 <= i_register_data_out;
          elsif i_irq_en = '1' then
            s_irq_1 <= i_register_data_out;
          end if;
        elsif (s_reg_change_ack = '1') and (s_reg_change_pending(c_reg_update_immediate_bit) = '1') then
          s_reg_change_pending(c_reg_update_immediate_bit) <= '0';
          s_fifo_flush_req(c_reg_update_immediate_bit) <= '0';
        end if;

        if (i_border_stb = '1') then
          s_zx_border_color_1(c_border_color_msb_bit downto c_border_color_lsb_bit) <= i_border_color;
        end if;
      end if;
    end if;
  end process;


  -- Copy over pending register changes in between of frames
  p_reg_copy_over : process(i_axis_mm2s_aclk)
  variable v_right_border_pos : integer range 0 to g_max_h_screen_res;
  variable v_bottom_border_pos : integer range 0 to g_max_v_screen_res;
  variable v_scaling_factor : unsigned(c_scaling_factor_msb_bit downto c_scaling_factor_lsb_bit);
  begin
    if rising_edge(i_axis_mm2s_aclk) then
      if i_axi_resetn = '0' then
        s_reg_change_ack <= '0';
        s_horizontal_resolution <= c_horizontal_resolution;
        s_vertical_resolution <= c_vertical_resolution;
        s_zx_spec_h_border_left_pos <= c_zx_spec_h_border_size;
        s_zx_spec_v_border_top_pos <= c_zx_spec_v_border_size;
        s_zx_spec_scaling_factor <= c_zx_spec_scaling_factor;
        v_bottom_border_pos := 0;
        v_right_border_pos := 0;
        for i in 1 to c_zx_spec_scaling_factor loop
          v_bottom_border_pos := v_bottom_border_pos + c_zx_spec_v_resolution;
          v_right_border_pos := v_right_border_pos + c_zx_spec_h_resolution;
        end loop;
        s_zx_spec_h_border_right_pos <= c_zx_spec_h_border_size + v_right_border_pos;
        s_zx_spec_v_border_bottom_pos <= c_zx_spec_v_border_size + v_bottom_border_pos;
        s_zx_color_addr_2 <= std_logic_vector(to_unsigned(c_axi_ram_color_attr_address, s_zx_color_addr_2'length));
        s_zx_bitmap_addr_2 <= std_logic_vector(to_unsigned(c_axi_ram_bitmap_data_address, s_zx_bitmap_addr_2'length));
      else
        case s_sm_reg_copy_over is
          when s_rc_idle =>
            if (s_sm_videostream = s_vs_idle) and (s_reg_change_pending(c_reg_update_immediate_bit) = '1') then
              s_zx_bitmap_addr_2 <= s_zx_bitmap_addr_1;
              s_zx_color_addr_2 <= s_zx_color_addr_1;
              s_horizontal_resolution <= to_integer(unsigned(s_active_size_1(c_hor_active_size_msb_bit downto c_hor_active_size_lsb_bit)));
              s_vertical_resolution <= to_integer(unsigned(s_active_size_1(c_ver_active_size_msb_bit downto c_ver_active_size_lsb_bit)));
              s_zx_spec_h_border_left_pos <= to_integer(unsigned(s_border_size_1(c_hor_border_size_msb_bit downto c_hor_border_size_lsb_bit)));
              s_zx_spec_v_border_top_pos <= to_integer(unsigned(s_border_size_1(c_ver_border_size_msb_bit downto c_ver_border_size_lsb_bit)));
              v_scaling_factor := unsigned(s_zx_aux_attr_1(c_scaling_factor_msb_bit downto c_scaling_factor_lsb_bit));
              s_zx_spec_scaling_factor <= to_integer(v_scaling_factor);
              s_zx_spec_h_border_right_pos <= to_integer(unsigned(s_border_size_1(c_hor_border_size_msb_bit downto c_hor_border_size_lsb_bit))) + 
                  c_zx_spec_h_resolution * to_integer(v_scaling_factor);
              s_zx_spec_v_border_bottom_pos <= to_integer(unsigned(s_border_size_1(c_ver_border_size_msb_bit downto c_ver_border_size_lsb_bit))) + 
                  c_zx_spec_v_resolution * to_integer(v_scaling_factor);
              s_reg_change_ack <= '1';
              s_sm_reg_copy_over <= s_rc_copy;
            end if;
          when s_rc_copy =>
            s_sm_reg_copy_over <= s_rc_end;
          when s_rc_end =>
            s_reg_change_ack <= '0';
            s_sm_reg_copy_over <= s_rc_idle;
          when others =>
            s_sm_reg_copy_over <= s_rc_idle;
        end case;
      end if;
    end if;      
  end process;


  -- sw_enable handler from the status register 
  p_sw_enable : process(i_axis_mm2s_aclk)
  begin
    if rising_edge(i_axis_mm2s_aclk) then
      if i_axi_resetn = '0' then
        s_sw_enable <= '1';
      else
        s_sw_enable <= s_control_1(c_control_reg_sw_enable_bit);
      end if;
    end if;      
  end process;
  
  
  -- This process retrieves data from videomemory and puts into two FIFOs
  -- (pixel data and color attributes are stored separately)
  p_amba_fsm : process(i_axis_mm2s_aclk)
  begin
    if rising_edge(i_axis_mm2s_aclk) then
      if (i_axi_resetn = '0') or (s_sw_enable = '0') or (s_fifo_flush_req(c_reg_update_immediate_bit) = '1') then
        s_state_amba <= t_idle_amba;
        o_axi_mm2s_rready <= '0';
        o_axi_mm2s_arvalid <= '0';
        s_pixel_attr_selector <= '0';
        s_amba_vert_count <= "00000001";
        s_amba_color_attr_repeater <= (others => '0');
        s_amba_pixel_repeater <= (others => '0');
        s_ram_bitmap_data_address <= unsigned(s_zx_bitmap_addr_2) + s_shadow_vram_offset;
        s_ram_color_attr_address <= unsigned(s_zx_color_addr_2) + s_shadow_vram_offset;
        s_pixel_address <= unsigned(s_zx_bitmap_addr_2);
        s_color_attr_address <=  unsigned(s_zx_color_addr_2) + s_shadow_vram_offset;
      else
        case s_state_amba is
          when t_idle_amba =>
            -- Don't start if there is no space in the FIFOs for at least one scanline worth of data
            if (s_pixel_data_fifo_prog_full = '0' and s_pixel_attr_selector = '0') or
               (s_color_attr_fifo_prog_full = '0' and s_pixel_attr_selector = '1') then
              s_state_amba <= t_set_addr_amba;
            end if;
          when t_set_addr_amba =>
            if s_pixel_attr_selector = '0' then
              o_axi_mm2s_araddr <= std_logic_vector(s_pixel_address(g_axi_addr_width - 1 downto 11)) &
                                   std_logic_vector(s_pixel_address(7 downto 5)) & 
                                   std_logic_vector(s_pixel_address(10 downto 8)) &
                                   std_logic_vector(s_pixel_address(4 downto 0));
            else
              o_axi_mm2s_araddr <= std_logic_vector(s_color_attr_address);
            end if;
            o_axi_mm2s_arsize <= std_logic_vector(to_unsigned(c_axi_arsize, o_axi_mm2s_arsize'length));
            o_axi_mm2s_arlen <= std_logic_vector(to_unsigned(c_axi_arlen, o_axi_mm2s_arlen'length));
            o_axi_mm2s_arburst <= std_logic_vector(to_unsigned(c_axi_arburst, o_axi_mm2s_arburst'length));
            o_axi_mm2s_arprot <= (others => '0');
            o_axi_mm2s_arvalid <= '1';
            s_state_amba <= t_wait_addr_ack_amba;
          when t_wait_addr_ack_amba =>
            if i_axi_mm2s_arready = '1' then
              o_axi_mm2s_arvalid <= '0';
              o_axi_mm2s_rready <= '1';
              s_state_amba <= t_wait_data_start_amba;
            end if;
          when t_wait_data_start_amba =>
            if i_axi_mm2s_rvalid = '1' and i_axi_mm2s_rlast = '0' then
              -- Read first portion of data
              s_state_amba <= t_read_amba;
            end if;
          when t_read_amba =>
            if i_axi_mm2s_rvalid = '1' then
              if i_axi_mm2s_rlast = '1' then
                -- Valid transmission
                s_state_amba <= t_done_amba;
              end if;
            else
              -- Didn't find rlast pulse
              s_state_amba <= t_error_amba;
            end if;
          when t_error_amba =>
            o_axi_mm2s_rready <= '0';
            s_state_amba <= t_idle_amba;
          when t_done_amba =>
            o_axi_mm2s_rready <= '0';
            if s_pixel_attr_selector = '0' then
              if (s_amba_pixel_repeater + 1) = s_zx_spec_scaling_factor then
                if (s_pixel_address - s_ram_bitmap_data_address + c_zx_pixel_data_per_scan_line) = c_zx_pixel_address_space then
                  s_ram_bitmap_data_address <= unsigned(s_zx_bitmap_addr_2) + s_shadow_vram_offset;
                  s_pixel_address <= unsigned(s_zx_bitmap_addr_2) + s_shadow_vram_offset;
                else
                  s_pixel_address <= s_pixel_address + c_zx_pixel_data_per_scan_line;
                end if;
                s_amba_pixel_repeater <= (others => '0');
              else
                -- Repeat transaction again with the same address to achieve picture vertical scaling effect
                s_amba_pixel_repeater <= s_amba_pixel_repeater + 1;
              end if;
              s_pixel_attr_selector <= '1';
            else
              if (s_amba_color_attr_repeater + 1) = s_zx_spec_scaling_factor then
                -- Work out the next address for the color attributes
                if (s_amba_vert_count + 1) = c_zx_spec_v_resolution then
                  s_ram_color_attr_address <= unsigned(s_zx_color_addr_2) + s_shadow_vram_offset;
                  s_color_attr_address <= resize(s_color_attr_offset, s_color_attr_address'length) + unsigned(s_zx_color_addr_2) + s_shadow_vram_offset;
                  s_amba_vert_count <= (others => '0');
                else
                  s_color_attr_address <= resize(s_color_attr_offset, s_color_attr_address'length) + s_ram_color_attr_address;
                  s_amba_vert_count <= s_amba_vert_count + 1;
                end if;
                s_amba_color_attr_repeater <= (others => '0');
              else
                -- Repeat transaction again with the same address to achieve picture vertical scaling effect
                s_amba_color_attr_repeater <= s_amba_color_attr_repeater + 1;
              end if;
              s_pixel_attr_selector <= '0'; 
            end if;
            s_state_amba <= t_idle_amba;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  o_axi_mm2s_arcache <= s_axi_mm2s_arcache;
  s_color_attr_offset <= unsigned(std_logic_vector(s_amba_vert_count(7 downto 3)) & "00000");

  
  -- This process generates color data for R, G and B channels in accordance with 
  -- horizontal and vertical counters
  p_color_gen : process(i_axis_mm2s_aclk)
  begin
    if rising_edge(i_axis_mm2s_aclk) then
      if (i_axi_resetn = '0') or (s_sw_enable = '0') then
        s_red_component <= (others => '0');
        s_green_component <= (others => '0');
        s_blue_component <= (others => '0');
        s_pixel_data_fifo_rd_en <= '0';
        s_horiz_repeater <= (others => '0');
        s_ula_attr <= (others => '1');
        s_sm_color_gen <= s_cg_idle;
      else
        case s_sm_color_gen is
          when s_cg_idle =>
            if i_axis_mm2s_tready = '1' then
              if s_vert_count = 0 then
                -- Draw pixel in the top border area
                s_red_component <= s_zx_border_red_component;
                s_green_component <= s_zx_border_green_component;
                s_blue_component <= s_zx_border_blue_component;
                if s_test_pattern = '1' then
                  s_sm_color_gen <= s_cg_test_pattern;
                else
                  s_sm_color_gen <= s_cg_top_border;
                  s_ula_attr <= (others => '1');
                end if;
              end if;
            end if;
            s_pixel_data_fifo_rd_en <= '0';
          when s_cg_test_pattern =>
            if i_axis_mm2s_tready = '1' then
              if (s_vert_count >= 0) and (s_vert_count < c_color_bar_scan_lines) then
                -- Generate color bars 64 pixel width which is 5 bits,
                -- colors should be generated in the following sequence:
                -- black, red, green, yellow, blue, magenta, cyan, white
                -- which would correspond to bit 6 for red, bit 7 for green
                -- and bit 8 for blue.
                s_red_component <= (others => s_horiz_count_vec(6));
                s_green_component <= (others => s_horiz_count_vec(7));
                s_blue_component <= (others => s_horiz_count_vec(8));
              elsif (s_vert_count >= c_color_bar_scan_lines) and (s_vert_count <= c_horiz_ramp_scan_lines) then
                -- Generate monochrome horizontal ramp
                s_red_component <= s_horiz_count_vec(7 downto 0);
                s_green_component <= s_horiz_count_vec(7 downto 0);
                s_blue_component <= s_horiz_count_vec(7 downto 0);
              else
                -- Generate monochrome vertical ramp for the rest area
                s_red_component <= s_vert_ramp_vec(7 downto 0);
                s_green_component <= s_vert_ramp_vec(7 downto 0);
                s_blue_component <= s_vert_ramp_vec(7 downto 0);
              end if;
              -- Stay in test pattern mode at least until the end of a frame
              if s_vert_count = s_vertical_resolution - 1 then
                if s_test_pattern = '0' then
                  s_sm_color_gen <= s_cg_idle;
                end if;
              end if;
            end if;
            s_pixel_data_fifo_rd_en <= '0';
          when s_cg_top_border =>
            if i_axis_mm2s_tready = '1' then
              if s_vert_count = s_zx_spec_v_border_top_pos then
                s_sm_color_gen <= s_cg_left_border;
              end if;
              s_red_component <= s_zx_border_red_component;
              s_green_component <= s_zx_border_green_component;
              s_blue_component <= s_zx_border_blue_component;
              s_ula_attr <= (others => '1');
            end if;
            s_pixel_data_fifo_rd_en <= '0';
          when s_cg_left_border =>
            if i_axis_mm2s_tready = '1' then
              if s_horiz_count = s_zx_spec_h_border_left_pos - 1 then
                s_active_pixel_count <= (others => '0');
                s_sm_color_gen <= s_cg_active_pixel_area;
              end if;
              s_red_component <= s_zx_border_red_component;
              s_green_component <= s_zx_border_green_component;
              s_blue_component <= s_zx_border_blue_component;
              s_ula_attr <= (others => '1');
            end if;
            s_pixel_data_fifo_rd_en <= '0';
          when s_cg_active_pixel_area =>
            if i_axis_mm2s_tready = '1' then
              if s_horiz_count = s_zx_spec_h_border_right_pos then
                s_red_component <= s_zx_border_red_component;
                s_green_component <= s_zx_border_green_component;
                s_blue_component <= s_zx_border_blue_component;
                s_active_pixel_count <= (others => '0');
                s_pixel_data_fifo_rd_en <= '0';
                s_sm_color_gen <= s_cg_right_border;
              else
                -- Active pixel area
                if s_horiz_repeater = 0 then 
                  -- Every 64 pixels we need to fetch another value from the FIFO meaning at 63, 127, 191, 255
                  -- or every time when all bits 5...0 are set
                  if s_active_pixel_count(5 downto 0) = (g_axi_data_width - 2) then -- Minus 2 instead of minus 1 as we start one clock cycle earlier
                    -- Read both FIFOs simultaneously
                    s_pixel_data_fifo_rd_en <= '1';
                    -- It takes 2 clock cycles to get the next value from FIFOs and generate new values for R, G and B components
                    -- in some cases i_axis_mm2s_tready is immediately asserted so we have only 1 clock cycle for scaling factor = 1
                    -- which results in four columns of flickering pixels. To overcome this we initiate fetching data from both FIFOs 
                    -- one clock cycle earlier but we need to latch the last pixel and its color attribute as they are not processed yet.
                    -- Latch the last pixel before reading new portion of data from FIFO
                    s_pixel_data_dout_56 <= s_pixel_data_dout(g_axi_data_width - 8); 
                    -- Latch the last color attribute before reading new portion of data from FIFO
                    s_color_attr_dout_63_56 <= s_color_attr_dout(g_axi_data_width - 1 downto g_axi_data_width - 8);
                  else
                    s_pixel_data_fifo_rd_en <= '0';
                  end if;
                  if s_zx_pixel = '1' then
                    -- Draw a regular ZX Spectrum pixel '1'
                    s_blue_component <= s_color_intensity when s_zx_color_attr(s_color_attr_count + 0 + s_flash_attr_offset) = '1' else c_byte_min_val;
                    s_red_component <= s_color_intensity when s_zx_color_attr(s_color_attr_count + 1 + s_flash_attr_offset) = '1' else c_byte_min_val;
                    s_green_component <= s_color_intensity when s_zx_color_attr(s_color_attr_count + 2 + s_flash_attr_offset) = '1' else c_byte_min_val;
                  else
                    -- Draw a regular ZX Spectrum pixel '0'
                    s_blue_component <= s_color_intensity when s_zx_color_attr(s_color_attr_count + 3 - s_flash_attr_offset) = '1' else c_byte_min_val;
                    s_red_component <= s_color_intensity when s_zx_color_attr(s_color_attr_count + 4 - s_flash_attr_offset) = '1' else c_byte_min_val;
                    s_green_component <= s_color_intensity when s_zx_color_attr(s_color_attr_count + 5 - s_flash_attr_offset) = '1' else c_byte_min_val;
                  end if;
                  s_active_pixel_count <= s_active_pixel_count + 1;
                  s_ula_attr <= s_zx_color_attr(s_color_attr_count + 7 downto s_color_attr_count);
                else
                  s_pixel_data_fifo_rd_en <= '0';
                end if;
                if (s_horiz_repeater + 1) = s_zx_spec_scaling_factor then
                  s_horiz_repeater <= (others => '0');
                else
                  s_horiz_repeater <= s_horiz_repeater + 1;
                end if;
              end if;
            else
              s_pixel_data_fifo_rd_en <= '0';
            end if;
          when s_cg_right_border =>
            if i_axis_mm2s_tready = '1' then
              if s_horiz_count = s_horizontal_resolution - 1 then
                if s_vert_count = s_zx_spec_v_border_bottom_pos - 1 then
                  s_sm_color_gen <= s_cg_bottom_border;
                else
                  s_sm_color_gen <= s_cg_left_border;
                end if;
              end if;
              s_red_component <= s_zx_border_red_component;
              s_green_component <= s_zx_border_green_component;
              s_blue_component <= s_zx_border_blue_component;
              s_ula_attr <= (others => '1');
            end if;
            s_pixel_data_fifo_rd_en <= '0';
          when s_cg_bottom_border =>
            if i_axis_mm2s_tready = '1' then
              if s_vert_count = s_vertical_resolution - 1 then
                if s_test_pattern = '1' then
                  s_sm_color_gen <= s_cg_test_pattern;
                else
                  s_sm_color_gen <= s_cg_idle;
                end if;
              end if;
              s_red_component <= s_zx_border_red_component;
              s_green_component <= s_zx_border_green_component;
              s_blue_component <= s_zx_border_blue_component;
              s_ula_attr <= (others => '1');
            end if;
            s_pixel_data_fifo_rd_en <= '0';
          when others =>
            s_sm_color_gen <= s_cg_idle;
        end case;
      end if;
    end if;
  end process;

  -- This manipulation is to reverse bit numbers in each byte of pixel data  
  s_active_pix_reversed_3lsb <= s_active_pixel_count(5 downto 3) & to_unsigned((7 - to_integer(s_active_pixel_count(2 downto 0))), 3);
  s_color_attr_count <= to_integer(s_active_pixel_count(5 downto 3) & "000");
  s_flash_attr_offset <= 3 when s_frame_counter(5) = '0' 
    and s_zx_color_attr(s_color_attr_count + c_zx_color_attr_flash_bit) = '1' else 0;
  s_color_intensity <= c_byte_max_brightness_val when s_zx_color_attr(s_color_attr_count + c_zx_color_attr_brightness_bit) = '1' 
    else c_byte_half_brightness_val;
  -- Push the latched last pixel when it comes to bit 56 as s_pixel_data_dout has already new data from FIFO
  s_zx_pixel <= s_pixel_data_dout_56 when to_integer(s_active_pix_reversed_3lsb) = (g_axi_data_width - 8) 
    else s_pixel_data_dout(to_integer(s_active_pix_reversed_3lsb));
  -- Push the latched last color attribute when it comes to bit 56 as s_color_attr_dout has already new data from FIFO
  s_zx_color_attr <= s_color_attr_dout_63_56 & s_color_attr_dout(g_axi_data_width - 9 downto 0) 
    when to_integer(s_active_pix_reversed_3lsb) = (g_axi_data_width - 8) else s_color_attr_dout;
  -- ZX border color   
  s_zx_border_red_component <= c_byte_half_brightness_val when s_zx_border_color_1(c_border_color_r_bit) = '1' else c_byte_min_val;
  s_zx_border_green_component <= c_byte_half_brightness_val when s_zx_border_color_1(c_border_color_g_bit) = '1' else c_byte_min_val;
  s_zx_border_blue_component <= c_byte_half_brightness_val when s_zx_border_color_1(c_border_color_b_bit) = '1' else c_byte_min_val;
  -- Test pattern
  s_horiz_count_vec <= std_logic_vector(s_horiz_count);
  s_vert_ramp_vec <= std_logic_vector(s_vert_count - c_horiz_ramp_scan_lines);
  -- Simulated ULA color attribute (not exactly the original Spectrum but better than nothing)
  o_ula_attr <= s_ula_attr;


  -- This process generates MM2S transactions
  p_mm2s_fsm : process(i_axis_mm2s_aclk)
  begin
    if rising_edge(i_axis_mm2s_aclk) then
      if (i_axi_resetn = '0') or (s_sw_enable = '0') then
        s_axis_mm2s_tvalid <= '0';
        s_end_of_line <= '0';
        s_start_of_frame <= '0';
        s_horiz_count <= (others => '0');
        s_vert_count <= (others => '0');
        s_frame_counter <= (others => '0');
        s_new_frame_int <= '0';
        s_sm_videostream <= s_vs_idle;
      else
        case s_sm_videostream is
          when s_vs_idle =>
            s_new_frame_int <= '0';
            if i_axis_mm2s_tready = '1' and s_pixel_data_fifo_prog_full = '1' and s_color_attr_fifo_prog_full = '1' then
              s_axis_mm2s_tvalid <= '0';
              s_end_of_line <= '0';
              s_start_of_frame <= '0';
              s_horiz_count <= (others => '0');
              s_vert_count <= (others => '0');
              if s_reg_change_pending(c_reg_update_immediate_bit) = '0' then
                s_sm_videostream <= s_vs_streaming;
              end if;
            end if;                
          when s_vs_streaming =>
            if i_axis_mm2s_tready = '1' then
              s_axis_mm2s_tvalid <= '1';
              if (s_horiz_count = 0) and (s_vert_count = 0) then
                s_start_of_frame <= '1';
                s_frame_counter <= s_frame_counter + 1;
              else
                s_start_of_frame <= '0';            
              end if;
              s_horiz_count <= s_horiz_count + 1;  
              if s_horiz_count = (s_horizontal_resolution - 1) then
                s_end_of_line <= '1';
                if s_vert_count = (s_vertical_resolution - 1) then
                  s_vert_count <= (others => '0');
                  s_new_frame_int <= '1';
                  s_sm_videostream <= s_vs_idle;
                else
                  s_vert_count <= s_vert_count + 1;
                  s_sm_videostream <= s_vs_eol;
                end if;
              end if;
            end if;
          when s_vs_eol =>
            if i_axis_mm2s_tready = '1' then
              s_start_of_frame <= '0';
              s_end_of_line <= '0';
              s_axis_mm2s_tvalid <= '0';
              s_horiz_count <= (others => '0');
              s_sm_videostream <= s_vs_streaming;
            end if;
          when others =>
            s_sm_videostream <= s_vs_idle;
        end case;
      end if;
    end if;
  end process;

  o_axis_mm2s_tdata <= s_red_component & s_blue_component & s_green_component;
  o_axis_mm2s_tlast <= s_end_of_line;
  o_axis_mm2s_tuser <= s_start_of_frame;
  o_axis_mm2s_tvalid <= s_axis_mm2s_tvalid;
  o_new_frame_int <= s_new_frame_int;

end architecture;
