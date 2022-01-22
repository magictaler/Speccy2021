----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 07/24/2021 09:55:52 PM
-- Design Name: ZX Spectrum Videocontroller 
-- Module Name: zx_ctrl - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as a drop in replacement for
-- the standard AXI Video Direct Memory Access IP Core from Xilinx to emulate
-- functionality of the standard ZX Spectrum video controller
-- 
-- Dependencies: zx_video
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

entity zx_ctrl is
    generic (
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_axi_resetn : in std_logic;
      i_axis_mm2s_aclk : in std_logic;
      i_axi_lite_aclk : in std_logic;
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

      o_rd_en : out std_logic;
      o_wr_en : out std_logic;
      o_register_data_out : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      -- Video controller registers
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
      -- Memory mapper registers
      o_mem_write_test_en : out std_logic;
      -- ZX Spectrum registers
      o_zx_control_en : out std_logic;
      i_zx_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_keyboard_1_en : out std_logic;
      o_zx_keyboard_2_en : out std_logic;
      o_zx_io_ports_en : out std_logic;
      i_zx_io_ports : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_zx_tape_fifo_en : out std_logic;
      i_zx_tape_fifo : in std_logic_vector(g_axi_lite_data_width - 1 downto 0)
      
    );

end zx_ctrl;

architecture rtl of zx_ctrl is

  -- AXI4LITE signals
  signal s_axi_awaddr : std_logic_vector(g_axi_addr_width - 1 downto 0);
  signal s_axi_awready : std_logic;
  signal s_axi_wready : std_logic;
  signal s_axi_bresp : std_logic_vector(1 downto 0);
  signal s_axi_bvalid : std_logic;
  signal s_axi_araddr : std_logic_vector(g_axi_addr_width - 1 downto 0);
  signal s_axi_arready : std_logic;
  signal s_axi_rdata : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_axi_rresp : std_logic_vector(1 downto 0);
  signal s_axi_rvalid : std_logic_vector(2 downto 0);

  -- Example-specific design signals
  -- local parameter for addressing 32 bit / 64 bit g_axi_lite_data_width
  -- c_addr_lsb is used for addressing 32/64 bit registers/memories
  -- c_addr_lsb = 2 for 32 bits (n downto 2)
  -- c_addr_lsb = 3 for 64 bits (n downto 3)
  constant c_addr_lsb  : integer := (g_axi_lite_data_width / 32) + 1;
  constant c_opt_mem_addr_bits : integer := 6;
  ------------------------------------------------
  ---- Signals for user logic register space 
  --------------------------------------------------
  signal s_active_size_en : std_logic;
  signal s_border_size_en : std_logic;
  signal s_zx_aux_attr_en : std_logic;
  signal s_zx_border_color_en : std_logic;
  signal s_zx_bitmap_addr_en : std_logic;
  signal s_zx_color_addr_en : std_logic;
  signal s_status_en : std_logic;
  signal s_control_en : std_logic;
  signal s_error_en : std_logic;
  signal s_irq_en : std_logic;
  signal s_mem_write_test_en : std_logic;
  signal s_zx_control_en : std_logic;
  signal s_zx_keyboard_1_en : std_logic;
  signal s_zx_keyboard_2_en : std_logic;
  signal s_zx_io_ports_en : std_logic;
  signal s_zx_tape_fifo_en : std_logic;

  signal s_slv_reg_rden : std_logic;
  signal s_slv_reg_wren : std_logic;
  signal s_reg_data_out : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_byte_index : integer;
  --signal s_slv_reg_rdrdy : std_logic_vector(1 downto 0);
  signal s_slv_reg_rden_vec : std_logic_vector(2 downto 0);

  signal s_register_data_out : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_rd_en : std_logic;
  signal s_wr_en : std_logic;
  -- Crossing clock domain 
  signal s_axi_awaddr_r1 : std_logic_vector(g_axi_addr_width - 1 downto 0);
  signal s_axi_awaddr_r2 : std_logic_vector(g_axi_addr_width - 1 downto 0);
  signal s_axi_araddr_r1 : std_logic_vector(g_axi_addr_width - 1 downto 0);
  signal s_axi_araddr_r2 : std_logic_vector(g_axi_addr_width - 1 downto 0);
  signal s_slv_reg_wren_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_slv_reg_rden_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_axi_bvalid_cdc : std_logic_vector(2 downto 0) := (others => '0');

  -- Standard Video IP registers
  constant c_control_reg             : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000000";
  constant c_status_reg              : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000001";
  constant c_error_reg               : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000010";
  constant c_irq_reg                 : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000011";
  constant c_version_reg             : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000100";
  -- Timing register set 0
  constant c_timing_reg_set_0_start  : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0001000";
  constant c_active_size_reg         : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0001000";
  -- Core specific registers
  constant c_core_specific_reg_start : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000000";
  constant c_border_size_reg         : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000000";
  constant c_zx_aux_attr_reg         : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000001"; -- pixel scaling factor etc
  constant c_zx_bitmap_addr_reg      : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000010"; -- ZX Spectrum bitmap data start address
  constant c_zx_color_addr_reg       : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000011"; -- ZX Spectrum color attribute start address
  constant c_zx_border_color_reg     : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000100"; -- ZX Spectrum border color
  -- Memory mapper test registers
  constant c_mem_write_test_reg      : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000101"; -- Memory write test register
  -- ZX Spectrum control register
  constant c_zx_control_reg          : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000110"; -- ZX Spectrun control register
  -- ZX Keyboard registers
  constant c_zx_keyboard_1_reg       : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000111"; -- ZX Keyboard register 1
  constant c_zx_keyboard_2_reg       : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001000"; -- ZX Keyboard register 2
  -- ZX IO ports
  constant c_zx_io_ports_reg         : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001001"; -- ZX IO ports
  -- ZX TAPE FIFO
  constant c_zx_tape_fifo_reg        : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001010"; -- ZX TAPE fifo
  
  constant c_version : std_logic_vector(g_axi_lite_data_width - 1 downto 0) := x"00000001";


begin

  -- I/O Connections assignments
  o_axi_lite_awready <= s_axi_awready;
  o_axi_lite_wready <= s_axi_wready;
  o_axi_lite_bresp <= s_axi_bresp;
  o_axi_lite_bvalid <= s_axi_bvalid;
  o_axi_lite_arready <= s_axi_arready;
  o_axi_lite_rdata <= s_axi_rdata;
  o_axi_lite_rresp <= s_axi_rresp;
  o_axi_lite_rvalid <= s_axi_rvalid(2);

  o_wr_en <= s_wr_en;
  o_rd_en <= s_rd_en;
  o_register_data_out <= s_register_data_out;

  o_active_size_en <= s_active_size_en;
  o_border_size_en <= s_border_size_en;
  o_zx_aux_attr_en <= s_zx_aux_attr_en;
  o_zx_border_color_en <= s_zx_border_color_en;
  o_zx_bitmap_addr_en <= s_zx_bitmap_addr_en;
  o_zx_color_addr_en <= s_zx_color_addr_en;
  o_status_en <= s_status_en;
  o_control_en <= s_control_en;
  o_error_en <= s_error_en;
  o_irq_en <= s_irq_en;
  o_mem_write_test_en <= s_mem_write_test_en;
  o_zx_control_en <= s_zx_control_en;
  o_zx_keyboard_1_en <= s_zx_keyboard_1_en;
  o_zx_keyboard_2_en <= s_zx_keyboard_2_en;
  o_zx_io_ports_en <= s_zx_io_ports_en;
  o_zx_tape_fifo_en <= s_zx_tape_fifo_en;
  
  -- Implement s_axi_awready generation
  -- s_axi_awready is asserted for one i_axi_lite_aclk clock cycle when both
  -- i_axi_lite_awvalid and i_axi_lite_wvalid are asserted. s_axi_awready is
  -- de-asserted when reset is low.
  p_process1: process (i_axi_lite_aclk)
  begin
    if rising_edge(i_axi_lite_aclk) then 
      if i_axi_resetn = '0' then
        s_axi_awready <= '0';
      else
        if (s_axi_awready = '0' and i_axi_lite_awvalid = '1' and i_axi_lite_wvalid = '1') then
          -- slave is ready to accept write address when
          -- there is a valid write address and write data
          -- on the write address and data bus. This design 
          -- expects no outstanding transactions. 
          s_axi_awready <= '1';
        else
          s_axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Implement s_axi_awaddr latching
  -- This process is used to latch the address when both 
  -- i_axi_lite_awvalid and i_axi_lite_wvalid are valid. 
  p_process2: process (i_axi_lite_aclk)
  begin
    if rising_edge(i_axi_lite_aclk) then 
      if i_axi_resetn = '0' then
        s_axi_awaddr <= (others => '0');
      else
        if (s_axi_awready = '0' and i_axi_lite_awvalid = '1' and i_axi_lite_wvalid = '1') then
          -- Write Address latching
          s_axi_awaddr <= i_axi_lite_awaddr;
        end if;
      end if;
    end if;                   
  end process; 

  -- Implement axi_wready generation
  -- axi_wready is asserted for one i_axi_lite_aclk clock cycle when both
  -- i_axi_lite_wvalid and i_axi_lite_awvalid are asserted. s_axi_wready is 
  -- de-asserted when reset is low. 
  p_process3: process (i_axi_lite_aclk)
  begin
    if rising_edge(i_axi_lite_aclk) then 
      if i_axi_resetn = '0' then
        s_axi_wready <= '0';
      else
        if (s_axi_wready = '0' and i_axi_lite_wvalid = '1' and i_axi_lite_awvalid = '1') then
          -- slave is ready to accept write data when 
          -- there is a valid write address and write data
          -- on the write address and data bus. This design 
          -- expects no outstanding transactions.           
          s_axi_wready <= '1';
        else
          s_axi_wready <= '0';
        end if;
      end if;
    end if;
  end process; 

  -- p_process4: Implement write response logic generation
  -- The write response and response valid signals are asserted by the slave
  -- when s_axi_wready, i_axi_lite_wvalid, s_axi_wready and i_axi_lite_awvalid are asserted.
  -- This marks the acceptance of address and indicates the status of
  -- write transaction.
  p_process4: process (i_axi_lite_aclk)
  begin
    if rising_edge(i_axi_lite_aclk) then
      if i_axi_resetn = '0' then
        s_axi_bvalid <= '0';
        s_axi_bresp <= "00";
      else
        if (s_axi_awready = '1' and i_axi_lite_awvalid = '1' and s_axi_wready = '1' and i_axi_lite_wvalid = '1' and s_axi_bvalid = '0') then
          s_axi_bvalid <= '1';
          s_axi_bresp  <= "00";
        elsif (i_axi_lite_bready = '1' and s_axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
          s_axi_bvalid <= '0';                                        -- (there is a possibility that bready is always asserted high)
        end if;
      end if;
    end if;
  end process;

  -- p_process5: Implement s_axi_arready generation
  -- s_axi_arready is asserted for one i_axi_lite_aclk clock cycle when
  -- i_axi_lite_arvalid is asserted. s_axi_awready is
  -- de-asserted when reset (active low) is asserted.
  -- The read address is also latched when i_axi_arvalid is
  -- asserted. s_axi_araddr is reset to zero on reset assertion.
  p_process5: process (i_axi_lite_aclk)
  begin
    if rising_edge(i_axi_lite_aclk) then
      if i_axi_resetn = '0' then
        s_axi_arready <= '0';
        s_axi_araddr <= (others => '1');
      else
        if (s_axi_arready = '0' and i_axi_lite_arvalid = '1') then
          -- indicates that the slave has accepted the valid read address
          s_axi_arready <= '1';
          -- Read Address latching
          s_axi_araddr  <= i_axi_lite_araddr;
        else
          s_axi_arready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- p_process6: Implement axi_arvalid generation
  -- s_axi_rvalid is asserted for one i_axi_lite_aclk clock cycle when both
  -- i_axi_lite_arvalid and s_axi_arready are asserted. The slave registers
  -- data are available on the s_axi_rdata bus at this instance. The
  -- assertion of s_axi_rvalid marks the validity of read data on the
  -- bus and s_axi_rresp indicates the status of read transaction. s_axi_rvalid
  -- is deasserted on reset (active low). s_axi_rresp and s_axi_rdata are
  -- cleared to zero on reset (active low).
  --------------------------------------
  p_process6: process (i_axi_lite_aclk)
  begin
    if rising_edge(i_axi_lite_aclk) then
      if i_axi_resetn = '0' then
        s_axi_rvalid <= "000";
        s_axi_rresp  <= "00";
      else
        if (s_axi_arready = '1' and i_axi_lite_arvalid = '1' and s_axi_rvalid(2) = '0') then
          s_axi_rvalid <= "001";
        end if;
        if (s_axi_rvalid(0) = '1') then
          s_axi_rvalid <= "010";
        elsif (s_axi_rvalid(1) = '1') then
          -- Valid read data is available at the read data bus
          s_axi_rvalid <= "100";
          s_axi_rresp  <= "00"; -- 'OKAY' response
        elsif (s_axi_rvalid(2) = '1' and i_axi_lite_rready = '1') then
          -- Read data is accepted by the master
          s_axi_rvalid <= "000";
        end if;
      end if;
    end if;
  end process;


  s_slv_reg_wren <= s_axi_wready and i_axi_lite_wvalid and s_axi_awready and i_axi_lite_awvalid;
  s_slv_reg_rden <= s_axi_arready and i_axi_lite_arvalid and (not s_axi_rvalid(2)) ;
  s_rd_en <= '1' when s_slv_reg_rden_cdc(2 downto 1) = "01" else '0'; --s_slv_reg_rdrdy(0); -- FIXME: need to cross clock domain for this signal too and for read operations in general


  -- Crossing clock domain for register writes. Transitioning from a slow (i_axi_lite_aclk, 100 Mhz)
  -- to a fast clock (i_axis_mm2s_aclk, 142.857 Mhz) by simply double flopping and detecting 
  -- rising edges for s_slv_reg_wren, s_slv_reg_rden and s_axi_bvalid
  p_register_data_out_cdc: process(i_axis_mm2s_aclk) is
  begin
    if rising_edge(i_axis_mm2s_aclk) then
      if (i_axi_resetn = '0') then
        s_axi_awaddr_r1 <= (others => '0');
        s_axi_awaddr_r2 <= (others => '0');
        s_axi_araddr_r1 <= (others => '0');
        s_axi_araddr_r2 <= (others => '0');
        s_slv_reg_wren_cdc <= (others => '0');
        s_slv_reg_rden_cdc <= (others => '0');
        s_axi_bvalid_cdc <= (others => '0');
      else
        s_axi_awaddr_r1 <= s_axi_awaddr;
        s_axi_awaddr_r2 <= s_axi_awaddr_r1;
        s_axi_araddr_r1 <= s_axi_araddr;
        s_axi_araddr_r2 <= s_axi_araddr_r1;
        s_slv_reg_wren_cdc <= s_slv_reg_wren_cdc(1 downto 0) & s_slv_reg_wren;
        s_slv_reg_rden_cdc <= s_slv_reg_rden_cdc(1 downto 0) & s_slv_reg_rden;
        s_axi_bvalid_cdc <= s_axi_bvalid_cdc(1 downto 0) & s_axi_bvalid;
        s_wr_en <= '1' when s_slv_reg_wren_cdc(2 downto 1) = "01" else '0';
      end if;
    end if;
  end process;

  -- p_process7: Implement memory mapped register enable
  -- Slave register write enable is asserted when valid address and data are available
  -- Slave register read enable is asserted when valid address is available
  p_process7: process (i_axis_mm2s_aclk)
  variable v_loc_addr : std_logic_vector(c_opt_mem_addr_bits downto 0); 
  begin
    if rising_edge(i_axis_mm2s_aclk) then 
      if i_axi_resetn = '0' then
        s_active_size_en <= '0';
        s_border_size_en <= '0';
        s_zx_aux_attr_en <= '0';
        s_zx_border_color_en <= '0';
        s_zx_bitmap_addr_en <= '0';
        s_zx_color_addr_en <= '0';
        s_status_en <= '0';
        s_control_en <= '0';
        s_error_en <= '0';
        s_irq_en <= '0';
        s_mem_write_test_en <= '0';
        s_zx_control_en <= '0';
        s_zx_keyboard_1_en <= '0';
        s_zx_keyboard_2_en <= '0';
        s_zx_io_ports_en <= '0';
        s_zx_tape_fifo_en <= '0';
      else
        if s_slv_reg_wren_cdc(2 downto 1) = "01" then
          v_loc_addr := s_axi_awaddr_r2(c_addr_lsb + c_opt_mem_addr_bits downto c_addr_lsb);
        elsif s_slv_reg_rden_cdc(2 downto 1) = "01" then
          v_loc_addr := s_axi_araddr_r2(c_addr_lsb + c_opt_mem_addr_bits downto c_addr_lsb);
        end if;

        if (s_slv_reg_wren_cdc(2 downto 1) = "01") or (s_slv_reg_rden_cdc(2 downto 1) = "01") then
          case v_loc_addr is
            when c_active_size_reg =>
              s_active_size_en <= '1';
            when c_border_size_reg =>
              s_border_size_en <= '1';
            when c_zx_aux_attr_reg =>
              s_zx_aux_attr_en <= '1';
            when c_zx_border_color_reg =>
              s_zx_border_color_en <= '1';
            when c_zx_bitmap_addr_reg =>
              s_zx_bitmap_addr_en <= '1';
            when c_zx_color_addr_reg =>
              s_zx_color_addr_en <= '1';
            when c_status_reg =>
              s_status_en <= '1';
            when c_control_reg =>
              s_control_en <= '1';
            when c_error_reg =>
              s_error_en <= '1';
            when c_irq_reg =>
              s_irq_en <= '1';
            when c_mem_write_test_reg =>
              s_mem_write_test_en <= '1';
            when c_zx_control_reg =>
              s_zx_control_en <= '1';
            when c_zx_keyboard_1_reg =>
              s_zx_keyboard_1_en <= '1';
            when c_zx_keyboard_2_reg =>
              s_zx_keyboard_2_en <= '1';
            when c_zx_io_ports_reg =>
              s_zx_io_ports_en <= '1';
            when c_zx_tape_fifo_reg =>
              s_zx_tape_fifo_en <= '1';
            when others =>
              s_active_size_en <= '0';
              s_border_size_en <= '0';
              s_zx_aux_attr_en <= '0';
              s_zx_border_color_en <= '0';
              s_zx_bitmap_addr_en <= '0';
              s_zx_color_addr_en <= '0';
              s_status_en <= '0';
              s_control_en <= '0';
              s_error_en <= '0';
              s_irq_en <= '0';
              s_mem_write_test_en <= '0';
              s_zx_control_en <= '0';
              s_zx_keyboard_1_en <= '0';
              s_zx_keyboard_2_en <= '0';
              s_zx_io_ports_en <= '0';
              s_zx_tape_fifo_en <= '0';
          end case;
        else
          s_active_size_en <= '0';
          s_border_size_en <= '0';
          s_zx_aux_attr_en <= '0';
          s_zx_border_color_en <= '0';
          s_zx_bitmap_addr_en <= '0';
          s_zx_color_addr_en <= '0';
          s_status_en <= '0';
          s_control_en <= '0';
          s_error_en <= '0';
          s_irq_en <= '0';
          s_mem_write_test_en <= '0';
          s_zx_control_en <= '0';
          s_zx_keyboard_1_en <= '0';
          s_zx_keyboard_2_en <= '0';
          s_zx_io_ports_en <= '0';
          s_zx_tape_fifo_en <= '0';
        end if;
      end if;
    end if;                   
  end process; 

  -- p_process8: Delay s_slv_reg_rden by one clock cycle
  p_process8: process(i_axi_lite_aclk) is
  begin
    if rising_edge(i_axi_lite_aclk) then
      s_slv_reg_rden_vec <= s_slv_reg_rden_vec(1 downto 0) & s_slv_reg_rden;
    end if;
  end process;

  -- p_process9: Register write data
  p_process9: process(i_axi_lite_aclk) is
  begin
    if (rising_edge (i_axi_lite_aclk)) then
      if (i_axi_lite_wvalid = '1' and i_axi_lite_awvalid = '1') then
          loop_1: for s_byte_index in 0 to (g_axi_lite_data_width/ 8 - 1) loop
            if ( i_axi_lite_wstrb(s_byte_index) = '1' ) then
              -- Respective byte enables are asserted as per write strobes
              s_register_data_out(s_byte_index * 8 + 7 downto s_byte_index * 8) <= i_axi_lite_wdata(s_byte_index * 8 + 7 downto s_byte_index * 8);
            end if;
          end loop;
        end if;
    end if;
  end process;

  -- p_process10: Register read data
  p_process10: process(i_axi_lite_aclk) is
  variable v_loc_addr : std_logic_vector(c_opt_mem_addr_bits downto 0);
  begin
    if (rising_edge (i_axi_lite_aclk)) then
      if ( i_axi_resetn = '0' ) then
        s_axi_rdata  <= (others => '0');
      else
        if (s_slv_reg_rden_vec(2 downto 1) = "01") then
          -- When there is a valid read address (i_axi_arvalid) with
          -- acceptance of read address by the slave (s_axi_arready),
          -- output the read data
          -- Read address mux
          v_loc_addr := s_axi_araddr(c_addr_lsb + c_opt_mem_addr_bits downto c_addr_lsb);
            case v_loc_addr is
              when c_active_size_reg =>
                s_axi_rdata <= i_active_size;
              when c_border_size_reg =>
                s_axi_rdata <= i_border_size;
              when c_zx_aux_attr_reg =>
                s_axi_rdata <= i_zx_aux_attr;
              when c_zx_border_color_reg =>
                s_axi_rdata <= i_zx_border_color;
              when c_zx_bitmap_addr_reg =>
                s_axi_rdata <= i_zx_bitmap_addr;
              when c_zx_color_addr_reg =>
                s_axi_rdata <= i_zx_color_addr;
              when c_status_reg =>
                s_axi_rdata <= i_status;
              when c_control_reg =>
                s_axi_rdata <= i_control;
              when c_error_reg =>
                s_axi_rdata <= i_error;
              when c_irq_reg =>
                s_axi_rdata <= i_irq;
              when c_version_reg =>
                s_axi_rdata <= c_version;
              when c_zx_control_reg =>
                s_axi_rdata <= i_zx_control;
              when c_zx_io_ports_reg =>
                s_axi_rdata <= i_zx_io_ports;
              when c_zx_tape_fifo_reg =>
                s_axi_rdata <= i_zx_tape_fifo;
              when others => 
                s_axi_rdata <= (others => '0');
          end case;
        end if;
      end if;
    end if;
  end process;

end architecture;
