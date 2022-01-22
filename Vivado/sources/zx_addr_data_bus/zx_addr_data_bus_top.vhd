----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 09/28/2021 11:00:00 PM
-- Design Name: ZX Spectrum Address and Data bus mapper
-- Module Name: zx_addr_data_bus_top - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module allows 8-bit MCU accessing DDRAM via 32-bit AXI bus
-- 
-- Dependencies: 
-- 
-- Revision:
-- 
-- Revision 0.02 - Fully functional data mapper
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zx_addr_data_bus_top is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_axi_resetn : in std_logic;
      i_axis_zx_bus_aclk : in std_logic;
      -- AXI interface      
      o_axi_zx_bus_araddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_zx_bus_arburst : out std_logic_vector(1 downto 0);
      o_axi_zx_bus_arcache : out std_logic_vector(3 downto 0);
      o_axi_zx_bus_arlen : out std_logic_vector(7 downto 0);
      o_axi_zx_bus_arprot : out std_logic_vector(2 downto 0);
      i_axi_zx_bus_arready : in std_logic;
      o_axi_zx_bus_arsize : out std_logic_vector(2 downto 0);
      o_axi_zx_bus_arvalid : out std_logic;
      i_axi_zx_bus_rdata : in std_logic_vector(g_axi_data_width - 1 downto 0);
      i_axi_zx_bus_rlast : in std_logic;
      o_axi_zx_bus_rready : out std_logic;
      i_axi_zx_bus_rresp : in std_logic_vector(1 downto 0);
      i_axi_zx_bus_rvalid : in std_logic;

      o_axi_zx_bus_awaddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_zx_bus_awburst : out std_logic_vector(1 downto 0);
      o_axi_zx_bus_awcache : out std_logic_vector(3 downto 0);
      o_axi_zx_bus_awlen : out std_logic_vector(7 downto 0);
      o_axi_zx_bus_awprot : out std_logic_vector(2 downto 0);
      i_axi_zx_bus_awready : in std_logic;
      o_axi_zx_bus_awsize : out std_logic_vector(2 downto 0);
      o_axi_zx_bus_awvalid : out std_logic;
      o_axi_zx_bus_wdata : out std_logic_vector(g_axi_data_width - 1 downto 0);
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

      i_register_data_out : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_mem_write_test_en : in std_logic
    );

end zx_addr_data_bus_top;

architecture rtl of zx_addr_data_bus_top is

  component zx_addr_data_bus
    generic (
      g_axi_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_axi_resetn : in std_logic;
      i_axis_zx_bus_aclk : in std_logic;

      o_axi_zx_bus_araddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_zx_bus_arburst : out std_logic_vector(1 downto 0);
      o_axi_zx_bus_arcache : out std_logic_vector(3 downto 0);
      o_axi_zx_bus_arlen : out std_logic_vector(7 downto 0);
      o_axi_zx_bus_arprot : out std_logic_vector(2 downto 0);
      i_axi_zx_bus_arready : in std_logic;
      o_axi_zx_bus_arsize : out std_logic_vector(2 downto 0);
      o_axi_zx_bus_arvalid : out std_logic;
      i_axi_zx_bus_rdata : in std_logic_vector(g_axi_data_width - 1 downto 0);
      i_axi_zx_bus_rlast : in std_logic;
      o_axi_zx_bus_rready : out std_logic;
      i_axi_zx_bus_rresp : in std_logic_vector(1 downto 0);
      i_axi_zx_bus_rvalid : in std_logic;

      o_axi_zx_bus_awaddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_zx_bus_awburst : out std_logic_vector(1 downto 0);
      o_axi_zx_bus_awcache : out std_logic_vector(3 downto 0);
      o_axi_zx_bus_awlen : out std_logic_vector(7 downto 0);
      o_axi_zx_bus_awprot : out std_logic_vector(2 downto 0);
      i_axi_zx_bus_awready : in std_logic;
      o_axi_zx_bus_awsize : out std_logic_vector(2 downto 0);
      o_axi_zx_bus_awvalid : out std_logic;
      o_axi_zx_bus_wdata : out std_logic_vector(g_axi_data_width - 1 downto 0);
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

      i_register_data_out : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_mem_write_test_en : in std_logic

    );
  end component;


begin

  i_zx_addr_data_bus : zx_addr_data_bus
    port map (
      i_axi_resetn => i_axi_resetn,
      i_axis_zx_bus_aclk => i_axis_zx_bus_aclk,
      
      o_axi_zx_bus_araddr => o_axi_zx_bus_araddr,
      o_axi_zx_bus_arburst => o_axi_zx_bus_arburst,
      o_axi_zx_bus_arcache => o_axi_zx_bus_arcache,
      o_axi_zx_bus_arlen => o_axi_zx_bus_arlen,
      o_axi_zx_bus_arprot => o_axi_zx_bus_arprot,
      i_axi_zx_bus_arready => i_axi_zx_bus_arready,
      o_axi_zx_bus_arsize => o_axi_zx_bus_arsize,
      o_axi_zx_bus_arvalid => o_axi_zx_bus_arvalid,
      i_axi_zx_bus_rdata => i_axi_zx_bus_rdata,
      i_axi_zx_bus_rlast => i_axi_zx_bus_rlast,
      o_axi_zx_bus_rready => o_axi_zx_bus_rready,
      i_axi_zx_bus_rresp => i_axi_zx_bus_rresp,
      i_axi_zx_bus_rvalid => i_axi_zx_bus_rvalid,

      o_axi_zx_bus_awaddr => o_axi_zx_bus_awaddr,
      o_axi_zx_bus_awburst => o_axi_zx_bus_awburst,
      o_axi_zx_bus_awcache => o_axi_zx_bus_awcache,
      o_axi_zx_bus_awlen => o_axi_zx_bus_awlen,
      o_axi_zx_bus_awprot => o_axi_zx_bus_awprot,
      i_axi_zx_bus_awready => i_axi_zx_bus_awready,
      o_axi_zx_bus_awsize => o_axi_zx_bus_awsize,
      o_axi_zx_bus_awvalid => o_axi_zx_bus_awvalid,
      o_axi_zx_bus_wdata => o_axi_zx_bus_wdata,
      o_axi_zx_bus_wlast => o_axi_zx_bus_wlast,
      i_axi_zx_bus_wready => i_axi_zx_bus_wready,
      i_axi_zx_bus_bresp => i_axi_zx_bus_bresp,
      o_axi_zx_bus_wvalid => o_axi_zx_bus_wvalid,
      o_axi_zx_bus_wstrb => o_axi_zx_bus_wstrb,
      i_axi_zx_bus_bvalid => i_axi_zx_bus_bvalid,
      o_axi_zx_bus_bready => o_axi_zx_bus_bready,

      i_zx_bus_address => i_zx_bus_address,
      i_zx_bus_data => i_zx_bus_data,
      o_zx_bus_data => o_zx_bus_data,
      i_zx_bus_mem_wr => i_zx_bus_mem_wr,
      i_zx_bus_mem_req => i_zx_bus_mem_req,
      o_zx_bus_mem_ack => o_zx_bus_mem_ack,

      i_register_data_out => i_register_data_out,
      i_mem_write_test_en => i_mem_write_test_en
    );

end architecture;
