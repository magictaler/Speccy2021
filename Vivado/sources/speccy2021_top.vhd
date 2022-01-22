----------------------------------------------------------------------------------
-- Inspired by Speccy2010 project
--  
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
--
-- Design Name: Speccy2021 wrapper
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity speccy2021_top is
  port (
    DDR_addr : inout std_logic_vector ( 14 downto 0 );
    DDR_ba : inout std_logic_vector ( 2 downto 0 );
    DDR_cas_n : inout std_logic;
    DDR_ck_n : inout std_logic;
    DDR_ck_p : inout std_logic;
    DDR_cke : inout std_logic;
    DDR_cs_n : inout std_logic;
    DDR_dm : inout std_logic_vector ( 3 downto 0 );
    DDR_dq : inout std_logic_vector ( 31 downto 0 );
    DDR_dqs_n : inout std_logic_vector ( 3 downto 0 );
    DDR_dqs_p : inout std_logic_vector ( 3 downto 0 );
    DDR_odt : inout std_logic;
    DDR_ras_n : inout std_logic;
    DDR_reset_n : inout std_logic;
    DDR_we_n : inout std_logic;
    FIXED_IO_ddr_vrn : inout std_logic;
    FIXED_IO_ddr_vrp : inout std_logic;
    FIXED_IO_mio : inout std_logic_vector ( 53 downto 0 );
    FIXED_IO_ps_clk : inout std_logic;
    FIXED_IO_ps_porb : inout std_logic;
    FIXED_IO_ps_srstb : inout std_logic;
    HDMI_DDC_scl_io : inout std_logic;
    HDMI_DDC_sda_io : inout std_logic;
    HDMI_HPD_tri_i : in std_logic_vector ( 0 downto 0 );
    TMDS_clk_n : out std_logic;
    TMDS_clk_p : out std_logic;
    TMDS_data_n : out std_logic_vector ( 2 downto 0 );
    TMDS_data_p : out std_logic_vector ( 2 downto 0 );
    AUD_PWM : inout std_logic;
    AUD_SD : inout std_logic
  );
end speccy2021_top;

architecture STRUCTURE of speccy2021_top is
  component speccy2021 is
  port (
    HDMI_HPD_tri_i : in std_logic_vector ( 0 downto 0 );
    DDR_cas_n : inout std_logic;
    DDR_cke : inout std_logic;
    DDR_ck_n : inout std_logic;
    DDR_ck_p : inout std_logic;
    DDR_cs_n : inout std_logic;
    DDR_reset_n : inout std_logic;
    DDR_odt : inout std_logic;
    DDR_ras_n : inout std_logic;
    DDR_we_n : inout std_logic;
    DDR_ba : inout std_logic_vector ( 2 downto 0 );
    DDR_addr : inout std_logic_vector ( 14 downto 0 );
    DDR_dm : inout std_logic_vector ( 3 downto 0 );
    DDR_dq : inout std_logic_vector ( 31 downto 0 );
    DDR_dqs_n : inout std_logic_vector ( 3 downto 0 );
    DDR_dqs_p : inout std_logic_vector ( 3 downto 0 );
    FIXED_IO_mio : inout std_logic_vector ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout std_logic;
    FIXED_IO_ddr_vrp : inout std_logic;
    FIXED_IO_ps_srstb : inout std_logic;
    FIXED_IO_ps_clk : inout std_logic;
    FIXED_IO_ps_porb : inout std_logic;
    HDMI_DDC_sda_i : in std_logic;
    HDMI_DDC_sda_o : out std_logic;
    HDMI_DDC_sda_t : out std_logic;
    HDMI_DDC_scl_i : in std_logic;
    HDMI_DDC_scl_o : out std_logic;
    HDMI_DDC_scl_t : out std_logic;
    TMDS_clk_p : out std_logic;
    TMDS_clk_n : out std_logic;
    TMDS_data_p : out std_logic_vector ( 2 downto 0 );
    TMDS_data_n : out std_logic_vector ( 2 downto 0 );

    S_VDMA_AXIS_MM2S_aclk : out std_logic;
    S_VDMA_AXI_LITE_aclk : out std_logic;
    S_VDMA_AXIS_MM2S_resetn : out std_logic_vector ( 0 downto 0 );

    S_VDMA_AXIS_MM2S_tdata : in std_logic_vector ( 23 downto 0 );
    S_VDMA_AXIS_MM2S_tready : out std_logic;
    S_VDMA_AXIS_MM2S_tuser : in std_logic_vector ( 0 downto 0 );
    S_VDMA_AXIS_MM2S_tvalid : in std_logic;
    S_VDMA_AXIS_MM2S_tlast : in std_logic;

    S_VDMA_AXI_MM2S_araddr : in std_logic_vector ( 31 downto 0 );
    S_VDMA_AXI_MM2S_arburst : in std_logic_vector ( 1 downto 0 );
    S_VDMA_AXI_MM2S_arcache : in std_logic_vector ( 3 downto 0 );
    S_VDMA_AXI_MM2S_arlen : in std_logic_vector ( 7 downto 0 );
    S_VDMA_AXI_MM2S_arprot : in std_logic_vector ( 2 downto 0 );
    S_VDMA_AXI_MM2S_arready : out std_logic;
    S_VDMA_AXI_MM2S_arsize : in std_logic_vector ( 2 downto 0 );
    S_VDMA_AXI_MM2S_arvalid : in std_logic;
    S_VDMA_AXI_MM2S_rdata : out std_logic_vector ( 63 downto 0 );
    S_VDMA_AXI_MM2S_rlast : out std_logic;
    S_VDMA_AXI_MM2S_rready : in std_logic;
    S_VDMA_AXI_MM2S_rresp : out std_logic_vector ( 1 downto 0 );
    S_VDMA_AXI_MM2S_rvalid : out std_logic;
    
    S_VDMA_AXI_LITE_araddr : out std_logic_vector ( 31 downto 0 );
    S_VDMA_AXI_LITE_arready : in std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_arvalid : out std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_awaddr : out std_logic_vector ( 31 downto 0 );
    S_VDMA_AXI_LITE_awready : in std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_awvalid : out std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_bready : out std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_bresp : in std_logic_vector ( 1 downto 0 );
    S_VDMA_AXI_LITE_bvalid : in std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_rdata : in std_logic_vector ( 31 downto 0 );
    S_VDMA_AXI_LITE_rready : out std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_rresp : in std_logic_vector ( 1 downto 0 );
    S_VDMA_AXI_LITE_rvalid : in std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_wdata : out std_logic_vector ( 31 downto 0 );
    S_VDMA_AXI_LITE_wready : in std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_wvalid : out std_logic_vector ( 0 downto 0 );
    S_VDMA_AXI_LITE_arprot : out std_logic_vector ( 2 downto 0 );
    S_VDMA_AXI_LITE_awprot : out std_logic_vector ( 2 downto 0 );
    S_VDMA_AXI_LITE_wstrb : out std_logic_vector ( 3 downto 0 );

    S_ZX_ADDR_DATA_BUS_AXI_araddr : in std_logic_vector ( 31 downto 0 );
    S_ZX_ADDR_DATA_BUS_AXI_arburst : in std_logic_vector ( 1 downto 0 );
    S_ZX_ADDR_DATA_BUS_AXI_arcache : in std_logic_vector ( 3 downto 0 );
    S_ZX_ADDR_DATA_BUS_AXI_arlen : in std_logic_vector ( 7 downto 0 );
    S_ZX_ADDR_DATA_BUS_AXI_arprot : in std_logic_vector ( 2 downto 0 );
    S_ZX_ADDR_DATA_BUS_AXI_arready : out std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_arsize : in std_logic_vector ( 2 downto 0 );
    S_ZX_ADDR_DATA_BUS_AXI_arvalid : in std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_rdata : out std_logic_vector ( 31 downto 0 );
    S_ZX_ADDR_DATA_BUS_AXI_rlast : out std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_rready : in std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_rresp : out std_logic_vector ( 1 downto 0 );
    S_ZX_ADDR_DATA_BUS_AXI_rvalid : out std_logic;

    S_ZX_ADDR_DATA_BUS_AXI_awaddr : in std_logic_vector(31 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_awburst : in std_logic_vector(1 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_awcache : in std_logic_vector(3 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_awlen : in std_logic_vector(7 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_awprot : in std_logic_vector(2 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_awready : out std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_awsize : in std_logic_vector(2 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_awvalid : in std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_wdata : in std_logic_vector(31 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_wlast : in std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_wready : out std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_bresp : out std_logic_vector(1 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_wvalid : in std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_wstrb : in std_logic_vector(3 downto 0);
    S_ZX_ADDR_DATA_BUS_AXI_bvalid : out std_logic;
    S_ZX_ADDR_DATA_BUS_AXI_bready : in std_logic
    
    
  );
  end component video_controller;

  component zx_video_top is
  port ( 
    i_axi_resetn : in std_logic;
    i_axis_mm2s_aclk : in std_logic;
    i_axi_lite_aclk : in std_logic;

    i_axis_mm2s_tready : in std_logic;
    o_axis_mm2s_tdata : out std_logic_vector ( 23 downto 0 );
    o_axis_mm2s_tlast : out std_logic;
    o_axis_mm2s_tuser : out std_logic;
    o_axis_mm2s_tvalid : out std_logic;

    o_axi_mm2s_araddr : out std_logic_vector ( 31 downto 0 );
    o_axi_mm2s_arburst : out std_logic_vector ( 1 downto 0 );
    o_axi_mm2s_arcache : out std_logic_vector ( 3 downto 0 );
    o_axi_mm2s_arlen : out std_logic_vector ( 7 downto 0 );
    o_axi_mm2s_arprot : out std_logic_vector ( 2 downto 0 );
    i_axi_mm2s_arready : in std_logic;
    o_axi_mm2s_arsize : out std_logic_vector ( 2 downto 0 );
    o_axi_mm2s_arvalid : out std_logic;
    i_axi_mm2s_rdata : in std_logic_vector ( 63 downto 0 );
    i_axi_mm2s_rlast : in std_logic;
    o_axi_mm2s_rready : out std_logic;
    i_axi_mm2s_rresp : in std_logic_vector ( 1 downto 0 );
    i_axi_mm2s_rvalid : in std_logic;

    i_axi_lite_araddr : in std_logic_vector ( 31 downto 0 );
    o_axi_lite_arready : out std_logic;
    i_axi_lite_arvalid : in std_logic;
    i_axi_lite_awaddr : in std_logic_vector ( 31 downto 0 );
    o_axi_lite_awready : out std_logic;
    i_axi_lite_awvalid : in std_logic;
    i_axi_lite_bready : in std_logic;
    o_axi_lite_bresp : out std_logic_vector ( 1 downto 0 );
    o_axi_lite_bvalid : out std_logic;
    o_axi_lite_rdata : out std_logic_vector ( 31 downto 0 );
    i_axi_lite_rready : in std_logic;
    o_axi_lite_rresp : out std_logic_vector ( 1 downto 0 );
    o_axi_lite_rvalid : out std_logic;
    i_axi_lite_wdata : in std_logic_vector ( 31 downto 0 );
    o_axi_lite_wready : out std_logic;
    i_axi_lite_wvalid : in std_logic;
    i_axi_lite_arprot : in std_logic_vector ( 2 downto 0 );
    i_axi_lite_awprot : in std_logic_vector ( 2 downto 0 );
    i_axi_lite_wstrb : in std_logic_vector ( 3 downto 0 );

    o_wr_en : out std_logic;    
    o_rd_en : out std_logic;    
    o_register_data_out : out std_logic_vector(31 downto 0);
    o_mem_write_test_en : out std_logic;
    o_zx_control_en : out std_logic;
    i_zx_control : in std_logic_vector(31 downto 0);
    o_zx_keyboard_1_en : out std_logic;
    o_zx_keyboard_2_en : out std_logic;
    o_zx_io_ports_en : out std_logic;
    i_zx_io_ports : in std_logic_vector(31 downto 0);
    o_zx_tape_fifo_en : out std_logic;
    i_zx_tape_fifo : in std_logic_vector(31 downto 0);

    i_border_color : in std_logic_vector(2 downto 0);
    i_border_stb : in std_logic;
    o_new_frame_int : out std_logic;
    o_ula_attr : out std_logic_vector(7 downto 0);
    i_shadow_vram : in std_logic
  );
  end component zx_video_top;

  component zx_addr_data_bus_top is
  port ( 
    i_axi_resetn : in std_logic;
    i_axis_zx_bus_aclk : in std_logic;

    o_axi_zx_bus_araddr : out std_logic_vector ( 31 downto 0 );
    o_axi_zx_bus_arburst : out std_logic_vector ( 1 downto 0 );
    o_axi_zx_bus_arcache : out std_logic_vector ( 3 downto 0 );
    o_axi_zx_bus_arlen : out std_logic_vector ( 7 downto 0 );
    o_axi_zx_bus_arprot : out std_logic_vector ( 2 downto 0 );
    i_axi_zx_bus_arready : in std_logic;
    o_axi_zx_bus_arsize : out std_logic_vector ( 2 downto 0 );
    o_axi_zx_bus_arvalid : out std_logic;
    i_axi_zx_bus_rdata : in std_logic_vector ( 31 downto 0 );
    i_axi_zx_bus_rlast : in std_logic;
    o_axi_zx_bus_rready : out std_logic;
    i_axi_zx_bus_rresp : in std_logic_vector ( 1 downto 0 );
    i_axi_zx_bus_rvalid : in std_logic;

    o_axi_zx_bus_awaddr : out std_logic_vector(31 downto 0);
    o_axi_zx_bus_awburst : out std_logic_vector(1 downto 0);
    o_axi_zx_bus_awcache : out std_logic_vector(3 downto 0);
    o_axi_zx_bus_awlen : out std_logic_vector(7 downto 0);
    o_axi_zx_bus_awprot : out std_logic_vector(2 downto 0);
    i_axi_zx_bus_awready : in std_logic;
    o_axi_zx_bus_awsize : out std_logic_vector(2 downto 0);
    o_axi_zx_bus_awvalid : out std_logic;
    o_axi_zx_bus_wdata : out std_logic_vector(31 downto 0);
    o_axi_zx_bus_wlast : out std_logic;
    i_axi_zx_bus_wready : in std_logic;
    i_axi_zx_bus_bresp : in std_logic_vector(1 downto 0);
    o_axi_zx_bus_wvalid : out std_logic;
    o_axi_zx_bus_wstrb : out std_logic_vector(3 downto 0);
    i_axi_zx_bus_bvalid : in std_logic;
    o_axi_zx_bus_bready : out std_logic;

    i_zx_bus_address : in std_logic_vector(23 downto 0);
    i_zx_bus_data : in std_logic_vector(7 downto 0);
    o_zx_bus_data : out std_logic_vector(7 downto 0);
    i_zx_bus_mem_wr : in std_logic;
    i_zx_bus_mem_req : in std_logic;
    o_zx_bus_mem_ack : out std_logic;

    i_register_data_out : in std_logic_vector(31 downto 0);
    i_mem_write_test_en : in std_logic

  );
  end component zx_addr_data_bus_top;

  component zx_main_top is
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
    o_zx_control : out std_logic_vector(31 downto 0);
    i_zx_keyboard_1_en : in std_logic;
    i_zx_keyboard_2_en : in std_logic;
    i_zx_io_ports_en : in std_logic;
    o_zx_io_ports : out std_logic_vector(31 downto 0);
    i_zx_tape_fifo_en : in std_logic;
    o_zx_tape_fifo : out std_logic_vector(31 downto 0);

    o_border_color : out std_logic_vector(2 downto 0);
    o_border_stb : out std_logic;
    i_new_frame_int : in std_logic;
    i_ula_attr : in std_logic_vector(7 downto 0);

    o_aud_pwm : out std_logic;
    o_aud_sd : out std_logic;
    o_shadow_vram : out std_logic

  );
  end component zx_main_top;

  component IOBUF is
  port (
    I : in std_logic;
    O : out std_logic;
    T : in std_logic;
    IO : inout std_logic
  );
  end component IOBUF;

  signal HDMI_DDC_scl_i : std_logic;
  signal HDMI_DDC_scl_o : std_logic;
  signal HDMI_DDC_scl_t : std_logic;
  signal HDMI_DDC_sda_i : std_logic;
  signal HDMI_DDC_sda_o : std_logic;
  signal HDMI_DDC_sda_t : std_logic;
  
  signal s_vdma_axis_mm2s_aclk : std_logic;
  signal s_vdma_axi_lite_aclk : std_logic;
  signal s_vdma_axis_mm2s_resetn : std_logic_vector ( 0 downto 0 );
  signal s_vdma_axis_mm2s_tdata : std_logic_vector ( 23 downto 0 );
  signal s_vdma_axis_mm2s_tlast : std_logic;
  signal s_vdma_axis_mm2s_tready : std_logic;
  signal s_vdma_axis_mm2s_tuser : std_logic_vector ( 0 downto 0 );
  signal s_vdma_axis_mm2s_tvalid : std_logic;

  signal s_vdma_axi_mm2s_araddr : std_logic_vector ( 31 downto 0 );
  signal s_vdma_axi_mm2s_arburst : std_logic_vector ( 1 downto 0 );
  signal s_vdma_axi_mm2s_arcache : std_logic_vector ( 3 downto 0 );
  signal s_vdma_axi_mm2s_arlen : std_logic_vector ( 7 downto 0 );
  signal s_vdma_axi_mm2s_arprot : std_logic_vector ( 2 downto 0 );
  signal s_vdma_axi_mm2s_arready : std_logic;
  signal s_vdma_axi_mm2s_arsize : std_logic_vector ( 2 downto 0 );
  signal s_vdma_axi_mm2s_arvalid : std_logic;
  signal s_vdma_axi_mm2s_rdata : std_logic_vector ( 63 downto 0 );
  signal s_vdma_axi_mm2s_rlast : std_logic;
  signal s_vdma_axi_mm2s_rready  : std_logic;
  signal s_vdma_axi_mm2s_rresp : std_logic_vector ( 1 downto 0 );
  signal s_vdma_axi_mm2s_rvalid  : std_logic;

  signal s_vdma_axi_lite_araddr : std_logic_vector ( 31 downto 0 );
  signal s_vdma_axi_lite_arready : std_logic;
  signal s_vdma_axi_lite_arvalid : std_logic;
  signal s_vdma_axi_lite_awaddr : std_logic_vector ( 31 downto 0 );
  signal s_vdma_axi_lite_awready : std_logic;
  signal s_vdma_axi_lite_awvalid : std_logic;
  signal s_vdma_axi_lite_bready : std_logic;
  signal s_vdma_axi_lite_bresp : std_logic_vector ( 1 downto 0 );
  signal s_vdma_axi_lite_bvalid : std_logic;
  signal s_vdma_axi_lite_rdata : std_logic_vector ( 31 downto 0 );
  signal s_vdma_axi_lite_rready : std_logic;
  signal s_vdma_axi_lite_rresp : std_logic_vector ( 1 downto 0 );
  signal s_vdma_axi_lite_rvalid : std_logic;
  signal s_vdma_axi_lite_wdata : std_logic_vector ( 31 downto 0 );
  signal s_vdma_axi_lite_wready : std_logic;
  signal s_vdma_axi_lite_wvalid : std_logic;
  signal s_vdma_axi_lite_arprot : std_logic_vector ( 2 downto 0 );
  signal s_vdma_axi_lite_awprot : std_logic_vector ( 2 downto 0 );
  signal s_vdma_axi_lite_wstrb : std_logic_vector ( 3 downto 0 );

  signal s_axi_zx_bus_araddr : std_logic_vector ( 31 downto 0 );
  signal s_axi_zx_bus_arburst : std_logic_vector ( 1 downto 0 );
  signal s_axi_zx_bus_arcache : std_logic_vector ( 3 downto 0 );
  signal s_axi_zx_bus_arlen : std_logic_vector ( 7 downto 0 );
  signal s_axi_zx_bus_arprot : std_logic_vector ( 2 downto 0 );
  signal s_axi_zx_bus_arready : std_logic;
  signal s_axi_zx_bus_arsize : std_logic_vector ( 2 downto 0 );
  signal s_axi_zx_bus_arvalid : std_logic;
  signal s_axi_zx_bus_rdata : std_logic_vector ( 31 downto 0 );
  signal s_axi_zx_bus_rlast : std_logic;
  signal s_axi_zx_bus_rready  : std_logic;
  signal s_axi_zx_bus_rresp : std_logic_vector ( 1 downto 0 );
  signal s_axi_zx_bus_rvalid  : std_logic;
 
  signal s_axi_zx_bus_awaddr : std_logic_vector(31 downto 0);
  signal s_axi_zx_bus_awburst : std_logic_vector(1 downto 0);
  signal s_axi_zx_bus_awcache : std_logic_vector(3 downto 0);
  signal s_axi_zx_bus_awlen : std_logic_vector(7 downto 0);
  signal s_axi_zx_bus_awprot : std_logic_vector(2 downto 0);
  signal s_axi_zx_bus_awready : std_logic;
  signal s_axi_zx_bus_awsize : std_logic_vector(2 downto 0);
  signal s_axi_zx_bus_awvalid : std_logic;
  signal s_axi_zx_bus_wdata : std_logic_vector(31 downto 0);
  signal s_axi_zx_bus_wlast : std_logic;
  signal s_axi_zx_bus_wready : std_logic;
  signal s_axi_zx_bus_bresp : std_logic_vector(1 downto 0);
  signal s_axi_zx_bus_wvalid : std_logic;
  signal s_axi_zx_bus_wstrb : std_logic_vector(3 downto 0);
  signal s_axi_zx_bus_bvalid : std_logic;
  signal s_axi_zx_bus_bready : std_logic;

  signal s_zx_bus_address : std_logic_vector(23 downto 0);
  signal s_zx_bus_data_in : std_logic_vector(7 downto 0);
  signal s_zx_bus_data_out : std_logic_vector(7 downto 0);
  signal s_zx_bus_mem_wr : std_logic;
  signal s_zx_bus_mem_req : std_logic;
  signal s_zx_bus_mem_ack : std_logic;

  signal s_register_data_out : std_logic_vector(31 downto 0);
  signal s_wr_en : std_logic;    
  signal s_rd_en : std_logic;    
  signal s_mem_write_test_en : std_logic;
  signal s_zx_control_en : std_logic;
  signal s_zx_control : std_logic_vector(31 downto 0);
  signal s_zx_keyboard_1_en : std_logic;
  signal s_zx_keyboard_2_en : std_logic;
  signal s_zx_io_ports_en : std_logic;
  signal s_zx_io_ports : std_logic_vector(31 downto 0);
  signal s_zx_tape_fifo_en : std_logic;
  signal s_zx_tape_fifo : std_logic_vector(31 downto 0);
  signal s_border_color : std_logic_vector(2 downto 0);
  signal s_border_stb : std_logic;
  signal s_new_frame_int : std_logic;
  signal s_ula_attr : std_logic_vector(7 downto 0);
  signal s_shadow_vram : std_logic;
  
begin

HDMI_DDC_scl_iobuf: component IOBUF
     port map (
      I => HDMI_DDC_scl_o,
      IO => HDMI_DDC_scl_io,
      O => HDMI_DDC_scl_i,
      T => HDMI_DDC_scl_t
    );

HDMI_DDC_sda_iobuf: component IOBUF
     port map (
      I => HDMI_DDC_sda_o,
      IO => HDMI_DDC_sda_io,
      O => HDMI_DDC_sda_i,
      T => HDMI_DDC_sda_t
    );

speccy2021_i: component speccy2021
     port map (
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      HDMI_DDC_scl_i => HDMI_DDC_scl_i,
      HDMI_DDC_scl_o => HDMI_DDC_scl_o,
      HDMI_DDC_scl_t => HDMI_DDC_scl_t,
      HDMI_DDC_sda_i => HDMI_DDC_sda_i,
      HDMI_DDC_sda_o => HDMI_DDC_sda_o,
      HDMI_DDC_sda_t => HDMI_DDC_sda_t,
      HDMI_HPD_tri_i(0) => HDMI_HPD_tri_i(0),
      S_VDMA_AXIS_MM2S_aclk => s_vdma_axis_mm2s_aclk,
      S_VDMA_AXI_LITE_aclk => s_vdma_axi_lite_aclk,
      S_VDMA_AXIS_MM2S_resetn(0) => s_vdma_axis_mm2s_resetn(0),
      S_VDMA_AXIS_MM2S_tdata(23 downto 0) => s_vdma_axis_mm2s_tdata(23 downto 0),
      S_VDMA_AXIS_MM2S_tlast => s_vdma_axis_mm2s_tlast,
      S_VDMA_AXIS_MM2S_tready => s_vdma_axis_mm2s_tready,
      S_VDMA_AXIS_MM2S_tuser(0) => s_vdma_axis_mm2s_tuser(0),
      S_VDMA_AXIS_MM2S_tvalid => s_vdma_axis_mm2s_tvalid,

      S_VDMA_AXI_MM2S_araddr => s_vdma_axi_mm2s_araddr,
      S_VDMA_AXI_MM2S_arburst => s_vdma_axi_mm2s_arburst,
      S_VDMA_AXI_MM2S_arcache => s_vdma_axi_mm2s_arcache,
      S_VDMA_AXI_MM2S_arlen => s_vdma_axi_mm2s_arlen,
      S_VDMA_AXI_MM2S_arprot => s_vdma_axi_mm2s_arprot,
      S_VDMA_AXI_MM2S_arready => s_vdma_axi_mm2s_arready,
      S_VDMA_AXI_MM2S_arsize => s_vdma_axi_mm2s_arsize,
      S_VDMA_AXI_MM2S_arvalid => s_vdma_axi_mm2s_arvalid,
      S_VDMA_AXI_MM2S_rdata => s_vdma_axi_mm2s_rdata,
      S_VDMA_AXI_MM2S_rlast => s_vdma_axi_mm2s_rlast,
      S_VDMA_AXI_MM2S_rready => s_vdma_axi_mm2s_rready,
      S_VDMA_AXI_MM2S_rresp => s_vdma_axi_mm2s_rresp,
      S_VDMA_AXI_MM2S_rvalid => s_vdma_axi_mm2s_rvalid,

      S_VDMA_AXI_LITE_araddr => s_vdma_axi_lite_araddr,
      S_VDMA_AXI_LITE_arready(0) => s_vdma_axi_lite_arready,
      S_VDMA_AXI_LITE_arvalid(0) => s_vdma_axi_lite_arvalid,
      S_VDMA_AXI_LITE_awaddr => s_vdma_axi_lite_awaddr,
      S_VDMA_AXI_LITE_awready(0) => s_vdma_axi_lite_awready,
      S_VDMA_AXI_LITE_awvalid(0) => s_vdma_axi_lite_awvalid,
      S_VDMA_AXI_LITE_bready(0) => s_vdma_axi_lite_bready,
      S_VDMA_AXI_LITE_bresp => s_vdma_axi_lite_bresp,
      S_VDMA_AXI_LITE_bvalid(0) => s_vdma_axi_lite_bvalid,
      S_VDMA_AXI_LITE_rdata => s_vdma_axi_lite_rdata,
      S_VDMA_AXI_LITE_rready(0) => s_vdma_axi_lite_rready,
      S_VDMA_AXI_LITE_rresp => s_vdma_axi_lite_rresp,
      S_VDMA_AXI_LITE_rvalid(0) => s_vdma_axi_lite_rvalid,
      S_VDMA_AXI_LITE_wdata => s_vdma_axi_lite_wdata,
      S_VDMA_AXI_LITE_wready(0) => s_vdma_axi_lite_wready,
      S_VDMA_AXI_LITE_wvalid(0) => s_vdma_axi_lite_wvalid,
      S_VDMA_AXI_LITE_arprot => s_vdma_axi_lite_arprot,
      S_VDMA_AXI_LITE_awprot => s_vdma_axi_lite_awprot,
      S_VDMA_AXI_LITE_wstrb => s_vdma_axi_lite_wstrb,
      
      S_ZX_ADDR_DATA_BUS_AXI_araddr => s_axi_zx_bus_araddr,
      S_ZX_ADDR_DATA_BUS_AXI_arburst => s_axi_zx_bus_arburst,
      S_ZX_ADDR_DATA_BUS_AXI_arcache => s_axi_zx_bus_arcache,
      S_ZX_ADDR_DATA_BUS_AXI_arlen => s_axi_zx_bus_arlen,
      S_ZX_ADDR_DATA_BUS_AXI_arprot => s_axi_zx_bus_arprot,
      S_ZX_ADDR_DATA_BUS_AXI_arready => s_axi_zx_bus_arready,
      S_ZX_ADDR_DATA_BUS_AXI_arsize => s_axi_zx_bus_arsize,
      S_ZX_ADDR_DATA_BUS_AXI_arvalid => s_axi_zx_bus_arvalid,
      S_ZX_ADDR_DATA_BUS_AXI_rdata => s_axi_zx_bus_rdata,
      S_ZX_ADDR_DATA_BUS_AXI_rlast => s_axi_zx_bus_rlast,
      S_ZX_ADDR_DATA_BUS_AXI_rready => s_axi_zx_bus_rready,
      S_ZX_ADDR_DATA_BUS_AXI_rresp => s_axi_zx_bus_rresp,
      S_ZX_ADDR_DATA_BUS_AXI_rvalid => s_axi_zx_bus_rvalid,

      S_ZX_ADDR_DATA_BUS_AXI_awaddr => s_axi_zx_bus_awaddr,
      S_ZX_ADDR_DATA_BUS_AXI_awburst => s_axi_zx_bus_awburst,
      S_ZX_ADDR_DATA_BUS_AXI_awcache => s_axi_zx_bus_awcache,
      S_ZX_ADDR_DATA_BUS_AXI_awlen => s_axi_zx_bus_awlen,
      S_ZX_ADDR_DATA_BUS_AXI_awprot => s_axi_zx_bus_awprot,
      S_ZX_ADDR_DATA_BUS_AXI_awready => s_axi_zx_bus_awready,
      S_ZX_ADDR_DATA_BUS_AXI_awsize => s_axi_zx_bus_awsize,
      S_ZX_ADDR_DATA_BUS_AXI_awvalid => s_axi_zx_bus_awvalid,
      S_ZX_ADDR_DATA_BUS_AXI_wdata => s_axi_zx_bus_wdata,
      S_ZX_ADDR_DATA_BUS_AXI_wlast => s_axi_zx_bus_wlast,
      S_ZX_ADDR_DATA_BUS_AXI_wready => s_axi_zx_bus_wready,
      S_ZX_ADDR_DATA_BUS_AXI_bresp => s_axi_zx_bus_bresp,
      S_ZX_ADDR_DATA_BUS_AXI_wvalid => s_axi_zx_bus_wvalid,
      S_ZX_ADDR_DATA_BUS_AXI_wstrb => s_axi_zx_bus_wstrb,
      S_ZX_ADDR_DATA_BUS_AXI_bvalid => s_axi_zx_bus_bvalid,
      S_ZX_ADDR_DATA_BUS_AXI_bready => s_axi_zx_bus_bready,

      TMDS_clk_n => TMDS_clk_n,
      TMDS_clk_p => TMDS_clk_p,
      TMDS_data_n(2 downto 0) => TMDS_data_n(2 downto 0),
      TMDS_data_p(2 downto 0) => TMDS_data_p(2 downto 0)
    );

zx_video_top_i : component zx_video_top
     port map(
      i_axi_resetn => s_vdma_axis_mm2s_resetn(0),
      i_axis_mm2s_aclk => s_vdma_axis_mm2s_aclk,
      i_axi_lite_aclk => s_vdma_axi_lite_aclk,
      o_axis_mm2s_tdata => s_vdma_axis_mm2s_tdata,
      o_axis_mm2s_tlast  => s_vdma_axis_mm2s_tlast,
      i_axis_mm2s_tready => s_vdma_axis_mm2s_tready,
      o_axis_mm2s_tuser => s_vdma_axis_mm2s_tuser(0),
      o_axis_mm2s_tvalid => s_vdma_axis_mm2s_tvalid, 

      o_axi_mm2s_araddr => s_vdma_axi_mm2s_araddr,
      o_axi_mm2s_arburst => s_vdma_axi_mm2s_arburst,
      o_axi_mm2s_arcache => s_vdma_axi_mm2s_arcache,
      o_axi_mm2s_arlen => s_vdma_axi_mm2s_arlen,
      o_axi_mm2s_arprot => s_vdma_axi_mm2s_arprot,
      i_axi_mm2s_arready => s_vdma_axi_mm2s_arready,
      o_axi_mm2s_arsize => s_vdma_axi_mm2s_arsize,
      o_axi_mm2s_arvalid => s_vdma_axi_mm2s_arvalid,
      i_axi_mm2s_rdata => s_vdma_axi_mm2s_rdata,
      i_axi_mm2s_rlast => s_vdma_axi_mm2s_rlast,
      o_axi_mm2s_rready => s_vdma_axi_mm2s_rready,
      i_axi_mm2s_rresp => s_vdma_axi_mm2s_rresp,
      i_axi_mm2s_rvalid => s_vdma_axi_mm2s_rvalid,

      i_axi_lite_araddr => s_vdma_axi_lite_araddr,
      o_axi_lite_arready => s_vdma_axi_lite_arready,
      i_axi_lite_arvalid => s_vdma_axi_lite_arvalid,
      i_axi_lite_awaddr => s_vdma_axi_lite_awaddr,
      o_axi_lite_awready => s_vdma_axi_lite_awready,
      i_axi_lite_awvalid => s_vdma_axi_lite_awvalid,
      i_axi_lite_bready => s_vdma_axi_lite_bready,
      o_axi_lite_bresp => s_vdma_axi_lite_bresp,
      o_axi_lite_bvalid => s_vdma_axi_lite_bvalid,
      o_axi_lite_rdata => s_vdma_axi_lite_rdata,
      i_axi_lite_rready => s_vdma_axi_lite_rready,
      o_axi_lite_rresp => s_vdma_axi_lite_rresp,
      o_axi_lite_rvalid => s_vdma_axi_lite_rvalid,
      i_axi_lite_wdata => s_vdma_axi_lite_wdata,
      o_axi_lite_wready => s_vdma_axi_lite_wready,
      i_axi_lite_wvalid => s_vdma_axi_lite_wvalid,
      i_axi_lite_arprot => s_vdma_axi_lite_arprot,
      i_axi_lite_awprot => s_vdma_axi_lite_awprot,
      i_axi_lite_wstrb => s_vdma_axi_lite_wstrb,

      o_wr_en => s_wr_en,
      o_rd_en => s_rd_en,
      o_register_data_out => s_register_data_out,
      o_mem_write_test_en => s_mem_write_test_en,
      o_zx_control_en => s_zx_control_en,
      i_zx_control => s_zx_control,
      o_zx_keyboard_1_en => s_zx_keyboard_1_en,
      o_zx_keyboard_2_en => s_zx_keyboard_2_en,
      o_zx_io_ports_en => s_zx_io_ports_en,
      i_zx_io_ports => s_zx_io_ports,
      o_zx_tape_fifo_en => s_zx_tape_fifo_en,
      i_zx_tape_fifo => s_zx_tape_fifo,

      i_border_color => s_border_color,
      i_border_stb => s_border_stb,
      o_new_frame_int => s_new_frame_int,
      o_ula_attr => s_ula_attr,
      i_shadow_vram => s_shadow_vram
    );

zx_addr_data_bus_top_i : component zx_addr_data_bus_top
     port map(
      i_axi_resetn => s_vdma_axis_mm2s_resetn(0),
      i_axis_zx_bus_aclk => s_vdma_axis_mm2s_aclk,
 
      o_axi_zx_bus_araddr => s_axi_zx_bus_araddr,
      o_axi_zx_bus_arburst => s_axi_zx_bus_arburst,
      o_axi_zx_bus_arcache => s_axi_zx_bus_arcache,
      o_axi_zx_bus_arlen => s_axi_zx_bus_arlen,
      o_axi_zx_bus_arprot => s_axi_zx_bus_arprot,
      i_axi_zx_bus_arready => s_axi_zx_bus_arready,
      o_axi_zx_bus_arsize => s_axi_zx_bus_arsize,
      o_axi_zx_bus_arvalid => s_axi_zx_bus_arvalid,
      i_axi_zx_bus_rdata => s_axi_zx_bus_rdata,
      i_axi_zx_bus_rlast => s_axi_zx_bus_rlast,
      o_axi_zx_bus_rready => s_axi_zx_bus_rready,
      i_axi_zx_bus_rresp => s_axi_zx_bus_rresp,
      i_axi_zx_bus_rvalid => s_axi_zx_bus_rvalid,

      o_axi_zx_bus_awaddr => s_axi_zx_bus_awaddr,
      o_axi_zx_bus_awburst => s_axi_zx_bus_awburst,
      o_axi_zx_bus_awcache => s_axi_zx_bus_awcache,
      o_axi_zx_bus_awlen => s_axi_zx_bus_awlen,
      o_axi_zx_bus_awprot => s_axi_zx_bus_awprot,
      i_axi_zx_bus_awready => s_axi_zx_bus_awready,
      o_axi_zx_bus_awsize => s_axi_zx_bus_awsize,
      o_axi_zx_bus_awvalid => s_axi_zx_bus_awvalid,
      o_axi_zx_bus_wdata => s_axi_zx_bus_wdata,
      o_axi_zx_bus_wlast => s_axi_zx_bus_wlast,
      i_axi_zx_bus_wready => s_axi_zx_bus_wready,
      i_axi_zx_bus_bresp => s_axi_zx_bus_bresp,
      o_axi_zx_bus_wvalid => s_axi_zx_bus_wvalid,
      o_axi_zx_bus_wstrb => s_axi_zx_bus_wstrb,
      i_axi_zx_bus_bvalid => s_axi_zx_bus_bvalid,
      o_axi_zx_bus_bready => s_axi_zx_bus_bready,

      i_zx_bus_address => s_zx_bus_address,
      i_zx_bus_data => s_zx_bus_data_in,
      o_zx_bus_data => s_zx_bus_data_out,
      i_zx_bus_mem_wr => s_zx_bus_mem_wr,
      i_zx_bus_mem_req => s_zx_bus_mem_req,
      o_zx_bus_mem_ack => s_zx_bus_mem_ack,

      i_register_data_out => s_register_data_out,
      i_mem_write_test_en => s_mem_write_test_en
      
    );
  
zx_main_top_i : component zx_main_top
     port map(
      i_resetn => s_vdma_axis_mm2s_resetn(0),
      i_aclk => s_vdma_axis_mm2s_aclk,

      o_zx_bus_address => s_zx_bus_address,
      i_zx_bus_data => s_zx_bus_data_out,
      o_zx_bus_data => s_zx_bus_data_in,
      o_zx_bus_mem_wr => s_zx_bus_mem_wr,
      o_zx_bus_mem_req => s_zx_bus_mem_req,
      i_zx_bus_mem_ack => s_zx_bus_mem_ack,

      i_wr_en => s_wr_en,
      i_rd_en => s_rd_en,
      i_register_data_out => s_register_data_out,      
      i_zx_control_en => s_zx_control_en,
      o_zx_control => s_zx_control,
      i_zx_keyboard_1_en => s_zx_keyboard_1_en,
      i_zx_keyboard_2_en => s_zx_keyboard_2_en,
      i_zx_io_ports_en => s_zx_io_ports_en,
      o_zx_io_ports => s_zx_io_ports,
      i_zx_tape_fifo_en => s_zx_tape_fifo_en,
      o_zx_tape_fifo => s_zx_tape_fifo,
      
      o_border_color => s_border_color,
      o_border_stb => s_border_stb,
      i_new_frame_int => s_new_frame_int,
      i_ula_attr => s_ula_attr,
  
      o_aud_pwm => AUD_PWM,
      o_aud_sd => AUD_SD,
      o_shadow_vram => s_shadow_vram
    );   

end STRUCTURE;
