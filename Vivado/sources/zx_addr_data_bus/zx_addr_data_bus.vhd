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

entity zx_addr_data_bus is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_addr_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_zx_addr_width : integer := 24
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
      
      i_zx_bus_address : in std_logic_vector(g_axi_zx_addr_width - 1 downto 0);
      i_zx_bus_data : in std_logic_vector(7 downto 0);
      o_zx_bus_data : out std_logic_vector(7 downto 0);
      i_zx_bus_mem_wr : in std_logic;
      i_zx_bus_mem_req : in std_logic;
      o_zx_bus_mem_ack : out std_logic;

      i_register_data_out : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_mem_write_test_en : in std_logic
    );

end zx_addr_data_bus;

architecture rtl of zx_addr_data_bus is

  -- AXI (AMBA) specific
  constant c_axi_arsize                   : integer range 0 to 7 := 2; -- burst size. '0' means 1 byte per transfer, '2' means 4 bytes
  constant c_axi_arlen                    : integer range 0 to 7 := 1; -- burst length. '0' means 1 transfer in a burst
  constant c_axi_arburst                  : integer range 0 to 3 := 1; -- burst type. '1' means incrementing
  constant c_axi_ram_start_address        : integer := 134217728; -- default start address of the ZX Spectrum memory
  constant c_axi_awsize                   : integer range 0 to 7 := 2; -- burst size. '0' means 1 byte per transfer, '2' means 4 bytes
  constant c_axi_awlen                    : integer range 0 to 7 := 0; -- burst length. '0' means 1 transfer in a burst
  constant c_axi_awburst                  : integer range 0 to 3 := 1; -- burst type. '1' means incrementing
 
  -- AXI (AMBA) specific 
  type t_state_amba is (t_idle_amba, t_set_addr_amba, t_wait_addr_ack_amba, t_wait_data_start_amba, t_read_amba, t_write_amba, t_write_ack_amba, t_error_amba, t_done_amba);
  signal s_state_amba : t_state_amba := t_idle_amba;
  signal s_axi_zx_bus_arcache : std_logic_vector(3 downto 0) := "0011";
  signal s_axi_zx_bus_awcache : std_logic_vector(3 downto 0) := "0011";
  signal s_rwdata_lsb : integer range 0 to 24;


begin

  -- This process reads/writes data from/to DDR RAM
  p_amba_fsm : process(i_axis_zx_bus_aclk)
  begin
    if rising_edge(i_axis_zx_bus_aclk) then
      if (i_axi_resetn = '0') then
        s_state_amba <= t_idle_amba;
        o_axi_zx_bus_rready <= '0';
        o_axi_zx_bus_arvalid <= '0';
        -- TODO: add the writing signals
        o_axi_zx_bus_wstrb <= (others => '0');
      else
        case s_state_amba is
          when t_idle_amba =>
            if (i_zx_bus_mem_req = '1') then
              s_state_amba <= t_set_addr_amba;
            end if;
            o_zx_bus_mem_ack <= '0';
          when t_set_addr_amba =>
            if (i_zx_bus_mem_wr = '0') then
              -- resetting the two least significant bits as we read in chunks of 32 bits and have to be 32 bits aligned
              o_axi_zx_bus_araddr <= std_logic_vector(c_axi_ram_start_address + 
                unsigned("00000000" & i_zx_bus_address(g_axi_zx_addr_width - 1 downto 2) & "00"));
              o_axi_zx_bus_arsize <= std_logic_vector(to_unsigned(c_axi_arsize, o_axi_zx_bus_arsize'length));
              o_axi_zx_bus_arlen <= std_logic_vector(to_unsigned(c_axi_arlen, o_axi_zx_bus_arlen'length));
              o_axi_zx_bus_arburst <= std_logic_vector(to_unsigned(c_axi_arburst, o_axi_zx_bus_arburst'length));
              o_axi_zx_bus_arprot <= (others => '0');
              o_axi_zx_bus_arvalid <= '1';
            else
              -- resetting the two least significant bits as we read in chunks of 32 bits and have to be 32 bits aligned
              o_axi_zx_bus_awaddr <= std_logic_vector(c_axi_ram_start_address + 
                unsigned("00000000" & i_zx_bus_address(g_axi_zx_addr_width - 1 downto 2) & "00"));
              o_axi_zx_bus_awsize <= std_logic_vector(to_unsigned(c_axi_awsize, o_axi_zx_bus_awsize'length));
              o_axi_zx_bus_awlen <= std_logic_vector(to_unsigned(c_axi_awlen, o_axi_zx_bus_awlen'length));
              o_axi_zx_bus_awburst <= std_logic_vector(to_unsigned(c_axi_awburst, o_axi_zx_bus_awburst'length));
              o_axi_zx_bus_arprot <= (others => '0');
              o_axi_zx_bus_awvalid <= '1';
            end if;
            s_state_amba <= t_wait_addr_ack_amba;
          when t_wait_addr_ack_amba =>
            if (i_zx_bus_mem_wr = '0') then
              if i_axi_zx_bus_arready = '1' then
                o_axi_zx_bus_arvalid <= '0';
                o_axi_zx_bus_rready <= '1';
                s_state_amba <= t_wait_data_start_amba;
              end if;
            else 
              if i_axi_zx_bus_awready = '1' then
                o_axi_zx_bus_awvalid <= '0';
                s_state_amba <= t_wait_data_start_amba;
              end if;
            end if;
          when t_wait_data_start_amba =>
            if (i_zx_bus_mem_wr = '0') then
              if i_axi_zx_bus_rvalid = '1' and i_axi_zx_bus_rlast = '0' then
                -- Read first portion of data
                o_zx_bus_data <= i_axi_zx_bus_rdata(s_rwdata_lsb + 7 downto s_rwdata_lsb);
                s_state_amba <= t_read_amba;
              end if;
            else
              if (i_axi_zx_bus_wready = '1') then
                o_axi_zx_bus_wdata(s_rwdata_lsb + 7 downto s_rwdata_lsb) <= i_zx_bus_data;
                o_axi_zx_bus_wvalid <= '1';
                o_axi_zx_bus_wlast <= '1';
                o_axi_zx_bus_wstrb(to_integer(unsigned(i_zx_bus_address(1 downto 0)))) <= '1';
                s_state_amba <= t_write_amba;
              end if;
            end if;
          when t_write_amba => 
            if (i_axi_zx_bus_wready = '1') then
              o_axi_zx_bus_wdata <= (others => '0');
              o_axi_zx_bus_wvalid <= '0';
              o_axi_zx_bus_wlast <= '0';
              o_axi_zx_bus_wstrb <= (others => '0');
              s_state_amba <= t_write_ack_amba;
            end if;
          when t_write_ack_amba => 
             if (i_axi_zx_bus_bvalid = '1') then
               if (i_axi_zx_bus_bresp = "00") then
                 s_state_amba <= t_done_amba;
               else
                 s_state_amba <= t_error_amba; 
               end if;
               o_axi_zx_bus_bready <= '1';
               o_zx_bus_mem_ack <= '1';
             end if;
          when t_read_amba =>
            if i_axi_zx_bus_rvalid = '1' then
              if i_axi_zx_bus_rlast = '1' then
                -- Valid transmission
                s_state_amba <= t_done_amba;
              end if;
            else
              -- Didn't find rlast pulse
              s_state_amba <= t_error_amba;
            end if;
            o_zx_bus_mem_ack <= '1';
          when t_error_amba =>
            if (i_zx_bus_mem_wr = '0') then
              o_axi_zx_bus_rready <= '0';
            else
              o_axi_zx_bus_bready <= '0';
            end if;
            -- We have to ack the transaction regardless
            o_zx_bus_mem_ack <= '1';
            s_state_amba <= t_idle_amba;
          when t_done_amba =>
            if (i_zx_bus_mem_wr = '0') then
              o_axi_zx_bus_rready <= '0';
            else
              o_axi_zx_bus_bready <= '0';
            end if;
            o_zx_bus_mem_ack <= '0';
            s_state_amba <= t_idle_amba;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  o_axi_zx_bus_arcache <= s_axi_zx_bus_arcache;
  s_rwdata_lsb <= to_integer(signed(i_zx_bus_address(1 downto 0) & "000"));


end architecture;
