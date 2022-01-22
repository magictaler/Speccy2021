----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 07/24/2021 09:55:52 PM
-- Design Name: ZX Spectrum Videocontroller 
-- Module Name: zx_video_top - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as a drop in replacement for
-- the standard AXI Video Direct Memory Access IP Core from Xilinx to emulate
-- functionality of the standard ZX Spectrum video controller
-- 
-- Dependencies: fifo_512_64, zx_ctrl, zx_video
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

entity zx_video_top is
    generic (
      g_max_hor_resolution_bits : integer := 11;
      g_color_component_width : integer := 8;
      g_axi_data_width : integer := 64;
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
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
      -- AXI interface      
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
      -- AXI Lite interface
      i_axi_lite_araddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      o_axi_lite_arready : out std_logic;
      i_axi_lite_arvalid : in std_logic;
      i_axi_lite_awaddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      o_axi_lite_awready : out std_logic;
      i_axi_lite_awvalid : in std_logic;
      i_axi_lite_bready : in std_logic;
      o_axi_lite_bresp : out std_logic_vector (1 downto 0);
      o_axi_lite_bvalid : out std_logic;
      o_axi_lite_rdata : out std_logic_vector (g_axi_lite_data_width - 1 downto 0);
      i_axi_lite_rready : in std_logic;
      o_axi_lite_rresp : out std_logic_vector (1 downto 0);
      o_axi_lite_rvalid : out std_logic;
      i_axi_lite_wdata : in std_logic_vector (g_axi_lite_data_width - 1 downto 0);
      o_axi_lite_wready : out std_logic;
      i_axi_lite_wvalid : in std_logic;
      i_axi_lite_arprot : in std_logic_vector (2 downto 0);
      i_axi_lite_awprot : in std_logic_vector (2 downto 0);
      i_axi_lite_wstrb : in std_logic_vector ((g_axi_lite_data_width / 8 ) - 1 downto 0);

      o_wr_en : out std_logic;
      o_rd_en : out std_logic;
      o_register_data_out : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_mem_write_test_en : out std_logic;
      o_zx_control_en : out std_logic;
      i_zx_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_keyboard_1_en : out std_logic;
      o_zx_keyboard_2_en : out std_logic;
      o_zx_io_ports_en : out std_logic;
      i_zx_io_ports : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_tape_fifo_en : out std_logic;
      i_zx_tape_fifo : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      
      i_border_color : in std_logic_vector(2 downto 0);
      i_border_stb : in std_logic;
      o_new_frame_int : out std_logic;
      o_ula_attr : out std_logic_vector(7 downto 0);
      i_shadow_vram : in std_logic
    );

end zx_video_top;

architecture rtl of zx_video_top is

  signal s_reg_rd_en : std_logic;
  signal s_reg_wr_en : std_logic;
  signal s_register_data_out : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_active_size : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_active_size_en : std_logic;
  signal s_border_size : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_border_size_en : std_logic;
  signal s_zx_aux_attr : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_aux_attr_en : std_logic;
  signal s_zx_border_color : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_border_color_en : std_logic;
  signal s_zx_bitmap_addr : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_bitmap_addr_en : std_logic;
  signal s_zx_color_addr : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_zx_color_addr_en : std_logic;
  signal s_status : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_status_en : std_logic;
  signal s_control : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_control_en : std_logic;
  signal s_error : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_error_en : std_logic;
  signal s_irq : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_irq_en : std_logic;

  component zx_video
    generic (
      g_max_hor_resolution_bits : integer := 11;
      g_color_component_width : integer := 8;
      g_axi_data_width : integer := 64;
      g_axi_addr_width : integer := 32;
      g_axi_lite_data_width : integer := 32
    );
    port ( 
      i_axi_resetn : in std_logic;
      i_axis_mm2s_aclk : in std_logic;
      i_axi_lite_aclk : in std_logic;

      i_axis_mm2s_tready : in std_logic;
      o_axis_mm2s_tdata : out std_logic_vector(g_color_component_width * 3 - 1 downto 0);
      o_axis_mm2s_tlast : out std_logic;
      o_axis_mm2s_tuser : out std_logic;
      o_axis_mm2s_tvalid : out std_logic;
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
  end component;

  component zx_ctrl
    generic (
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_axi_resetn : in std_logic;
      i_axis_mm2s_aclk : in std_logic;
      i_axi_lite_aclk : in std_logic;

      i_axi_lite_araddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      o_axi_lite_arready : out std_logic;
      i_axi_lite_arvalid : in std_logic;
      i_axi_lite_awaddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      o_axi_lite_awready : out std_logic;
      i_axi_lite_awvalid : in std_logic;
      i_axi_lite_bready : in std_logic;
      o_axi_lite_bresp : out std_logic_vector (1 downto 0);
      o_axi_lite_bvalid : out std_logic;
      o_axi_lite_rdata : out std_logic_vector (g_axi_lite_data_width - 1 downto 0);
      i_axi_lite_rready : in std_logic;
      o_axi_lite_rresp : out std_logic_vector (1 downto 0);
      o_axi_lite_rvalid : out std_logic;
      i_axi_lite_wdata : in std_logic_vector (g_axi_lite_data_width - 1 downto 0);
      o_axi_lite_wready : out std_logic;
      i_axi_lite_wvalid : in std_logic;
      i_axi_lite_arprot : in std_logic_vector (2 downto 0);
      i_axi_lite_awprot : in std_logic_vector (2 downto 0);
      i_axi_lite_wstrb : in std_logic_vector ((g_axi_lite_data_width / 8 ) - 1 downto 0);

      o_rd_en : out std_logic;
      o_wr_en : out std_logic;
      o_register_data_out : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      
      i_active_size : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_active_size_en : out std_logic;
      i_border_size : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_border_size_en : out std_logic;
      i_zx_aux_attr : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_aux_attr_en : out std_logic;
      i_zx_border_color : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_border_color_en : out std_logic;
      i_zx_bitmap_addr : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_bitmap_addr_en : out std_logic;
      i_zx_color_addr : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_color_addr_en : out std_logic;
      i_status : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_status_en : out std_logic;
      i_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_control_en : out std_logic;
      i_error : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_error_en : out std_logic;
      i_irq : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_irq_en : out std_logic;

      o_mem_write_test_en : out std_logic;
      o_zx_control_en : out std_logic;
      i_zx_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_keyboard_1_en : out std_logic;
      o_zx_keyboard_2_en : out std_logic;
      o_zx_io_ports_en  : out std_logic;
      i_zx_io_ports : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_tape_fifo_en : out std_logic;
      i_zx_tape_fifo : in std_logic_vector(g_axi_lite_data_width - 1 downto 0)

    );
  end component;

begin

  i_zx_video : zx_video
    port map (
      i_axi_resetn => i_axi_resetn,
      i_axis_mm2s_aclk => i_axis_mm2s_aclk,
      i_axi_lite_aclk => i_axi_lite_aclk,
      i_axis_mm2s_tready => i_axis_mm2s_tready,
      o_axis_mm2s_tdata => o_axis_mm2s_tdata,
      o_axis_mm2s_tlast => o_axis_mm2s_tlast,
      o_axis_mm2s_tuser => o_axis_mm2s_tuser,
      o_axis_mm2s_tvalid => o_axis_mm2s_tvalid,
      o_axi_mm2s_araddr => o_axi_mm2s_araddr,
      o_axi_mm2s_arburst => o_axi_mm2s_arburst,
      o_axi_mm2s_arcache => o_axi_mm2s_arcache,
      o_axi_mm2s_arlen => o_axi_mm2s_arlen,
      o_axi_mm2s_arprot => o_axi_mm2s_arprot,
      i_axi_mm2s_arready => i_axi_mm2s_arready,
      o_axi_mm2s_arsize => o_axi_mm2s_arsize,
      o_axi_mm2s_arvalid => o_axi_mm2s_arvalid,
      i_axi_mm2s_rdata => i_axi_mm2s_rdata,
      i_axi_mm2s_rlast => i_axi_mm2s_rlast,
      o_axi_mm2s_rready => o_axi_mm2s_rready,
      i_axi_mm2s_rresp => i_axi_mm2s_rresp,
      i_axi_mm2s_rvalid => i_axi_mm2s_rvalid,

      i_rd_en => s_reg_rd_en,
      i_wr_en => s_reg_wr_en,
      i_register_data_out => s_register_data_out,
      o_active_size => s_active_size,
      i_active_size_en => s_active_size_en,
      o_border_size => s_border_size,
      i_border_size_en => s_border_size_en,
      o_zx_aux_attr => s_zx_aux_attr,
      i_zx_aux_attr_en => s_zx_aux_attr_en,
      o_zx_border_color => s_zx_border_color,
      i_zx_border_color_en => s_zx_border_color_en,
      o_zx_bitmap_addr => s_zx_bitmap_addr,
      i_zx_bitmap_addr_en => s_zx_bitmap_addr_en,
      o_zx_color_addr => s_zx_color_addr,
      i_zx_color_addr_en => s_zx_color_addr_en,
      o_status => s_status,
      i_status_en => s_status_en,
      o_control => s_control,
      i_control_en => s_control_en,
      o_error => s_error,
      i_error_en => s_error_en,
      o_irq => s_irq,
      i_irq_en => s_irq_en,

      i_border_color => i_border_color,
      i_border_stb => i_border_stb,
      o_new_frame_int => o_new_frame_int,
      o_ula_attr => o_ula_attr,
      i_shadow_vram => i_shadow_vram
    );

  i_zx_ctrl : zx_ctrl
    port map (
      i_axi_resetn => i_axi_resetn,
      i_axis_mm2s_aclk => i_axis_mm2s_aclk,
      i_axi_lite_aclk => i_axi_lite_aclk,
      i_axi_lite_araddr => i_axi_lite_araddr,
      o_axi_lite_arready => o_axi_lite_arready,
      i_axi_lite_arvalid => i_axi_lite_arvalid,
      i_axi_lite_awaddr => i_axi_lite_awaddr,
      o_axi_lite_awready => o_axi_lite_awready,
      i_axi_lite_awvalid => i_axi_lite_awvalid,
      i_axi_lite_bready => i_axi_lite_bready,
      o_axi_lite_bresp => o_axi_lite_bresp,
      o_axi_lite_bvalid => o_axi_lite_bvalid,
      o_axi_lite_rdata => o_axi_lite_rdata,
      i_axi_lite_rready => i_axi_lite_rready,
      o_axi_lite_rresp => o_axi_lite_rresp,
      o_axi_lite_rvalid => o_axi_lite_rvalid,
      i_axi_lite_wdata => i_axi_lite_wdata,
      o_axi_lite_wready => o_axi_lite_wready,
      i_axi_lite_wvalid => i_axi_lite_wvalid,
      i_axi_lite_arprot => i_axi_lite_arprot,
      i_axi_lite_awprot => i_axi_lite_awprot,
      i_axi_lite_wstrb => i_axi_lite_wstrb,

      o_rd_en => s_reg_rd_en,
      o_wr_en => s_reg_wr_en,
      o_register_data_out => s_register_data_out,
      i_active_size => s_active_size,
      o_active_size_en => s_active_size_en,
      i_border_size => s_border_size,
      o_border_size_en => s_border_size_en,
      i_zx_aux_attr => s_zx_aux_attr,
      o_zx_aux_attr_en => s_zx_aux_attr_en,
      i_zx_border_color => s_zx_border_color,
      o_zx_border_color_en => s_zx_border_color_en,
      i_zx_bitmap_addr => s_zx_bitmap_addr,
      o_zx_bitmap_addr_en => s_zx_bitmap_addr_en,
      i_zx_color_addr => s_zx_color_addr,
      o_zx_color_addr_en => s_zx_color_addr_en,
      i_status => s_status,
      o_status_en => s_status_en,
      i_control => s_control,
      o_control_en => s_control_en,
      i_error => s_error,
      o_error_en => s_error_en,
      i_irq => s_irq,
      o_irq_en => s_irq_en,

      o_mem_write_test_en => o_mem_write_test_en,
      o_zx_control_en => o_zx_control_en,
      i_zx_control => i_zx_control,
      o_zx_keyboard_1_en => o_zx_keyboard_1_en,
      o_zx_keyboard_2_en => o_zx_keyboard_2_en,
      o_zx_io_ports_en => o_zx_io_ports_en,
      i_zx_io_ports => i_zx_io_ports,
      o_zx_tape_fifo_en => o_zx_tape_fifo_en,
      i_zx_tape_fifo  => i_zx_tape_fifo
    );
  
    o_register_data_out <= s_register_data_out;
    o_wr_en <= s_reg_wr_en;
    o_rd_en <= s_reg_rd_en;

end architecture;
