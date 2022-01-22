//! @file zx_spectrun_display_ctrl.h
//! @brief Driver for ZX Spectrum Video Controller on Zynq7020

#ifndef ZX_SPECTRUM_DISPLAY_CTRL_H
#define ZX_SPECTRUM_DISPLAY_CTRL_H

#include <stdint.h>

#define ZX_VIDEO_CTRL_BASE_ADDR (XPAR_S_VDMA_AXI_LITE_BASEADDR)

// Standard Video IP registers
#define ZX_VIDEO_CONTROL_REG_OFFSET       (0x0L)
#define ZX_VIDEO_STATUS_REG_OFFSET       (0x04L)
#define ZX_VIDEO_ERROR_REG_OFFSET        (0x08L)
#define ZX_VIDEO_IRQ_REG_OFFSET          (0x0CL)
#define ZX_VIDEO_VER_REG_OFFSET          (0x10L)
// Timing register set
#define ZX_VIDEO_ACTIVE_SIZE_REG_OFFSET  (0x20L)
// ZX Spectrum core specific registers
#define ZX_VIDEO_BORDER_SIZE_REG_OFFSET  (0x100L)
#define ZX_VIDEO_AUX_ATTR_REG_OFFSET     (0x104L)
#define ZX_VIDEO_BITMAP_ADDR_REG_OFFSET  (0x108L)
#define ZX_VIDEO_COLOR_ADDR_REG_OFFSET   (0x10CL)
#define ZX_VIDEO_BORDER_COLOR_REG_OFFSET (0x110L)

// The registers below are not related to the Video controller
// and used as extension in the register address space
// to save on resources
#define ZX_MEM_WRITE_TEST_REG_OFFSET     (0x114L)
#define ZX_SPECTRUM_CONTROL_OFFSET       (0x118L)
#define ZX_KEYBOARD_REG1_OFFSET          (0x11CL)
#define ZX_KEYBOARD_REG2_OFFSET          (0x120L)
#define ZX_IO_PORTS_OFFSET               (0x124L)
#define ZX_TAPE_FIFO_OFFSET              (0x128L)

// Spectrum common constants
#define ZX_SPECTRUM_H_RESOLUTION (256)
#define ZX_SPECTRUM_V_RESOLUTION (192)
#define ZX_MAX_SCALING_FACTOR (7)

#define ZX_PIXEL_DATA_REGION_SIZE (0x1800)
#define ZX_SPECTRUM_VRAM_SIZE (0x1B00)
#define ZX_SPECTRUM_VRAM_MIN_ALIGNMENT (0x2000)


//!@brief C structure representing ZX Spectrum Display control register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t sw_enable :1;
        uint32_t reg_update :1;
        uint32_t reserved_1 :2;
        uint32_t bypass_enable :1;
        uint32_t test_pattern_enable :1;
        uint32_t reserved_2 :24;
        uint32_t latch_border_color :1;
        uint32_t sw_reset :1;
    } bits;

} reg_ZX_Control_Struct;

//!@brief C structure representing ZX Spectrum Display AUX attribute register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t scaling_factor :3;
        uint32_t reserved_1 :29;
    } bits;

} reg_ZX_Aux_attr_Struct;

//!@brief C structure representing ZX Spectrum Display border color register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t border_color :3;
        uint32_t reserved_1 :29;
    } bits;

} reg_ZX_Border_color_Struct;

//!@brief C structure representing ZX Spectrum Display bitmap address register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t bitmap_addr;
    } bits;

} reg_ZX_Bitmap_addr_Struct;

//!@brief C structure representing ZX Spectrum Display color attr address register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t color_attr_addr :32;
    } bits;

} reg_ZX_Color_attr_addr_Struct;

//!@brief C structure representing ZX Spectrum Display active size register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t horizontal : 16;
        uint32_t vertical : 16;
    } bits;

} reg_ZX_Active_size_Struct;

//!@brief C structure representing ZX Spectrum Display border size register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t horizontal_left : 16;
        uint32_t vertical_top : 16;
    } bits;

} reg_ZX_Border_size_Struct;

//!@brief C structure representing a register for testing ZX address and data bus mapper.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t address : 24;
        uint32_t data : 8;
    } bits;

} reg_ZX_mem_write_test_Struct;

//!@brief C structure representing ZX Spectrum 2021 control register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t cpu_halt_req : 1;
        uint32_t cpu_restore_pc_n : 1;
        uint32_t cpu_one_cycle_wait_req : 1;
        uint32_t cpu_reset : 1;
        uint32_t magic_button : 1;
        uint32_t cpu_trace_req : 1;
        uint32_t trdos_flag : 1; 
        uint32_t trdos_wait : 1; 
        uint32_t cpu_pc : 16;
        uint32_t cpu_int : 8;
    } bits;
 
} reg_ZX_Spectrum_cpu_control_Struct;

//!@brief C structure representing ZX Spectrum 2021 IO port register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t zx_port_fe : 8;
        uint32_t zx_port_7ffd : 8;
        uint32_t zx_port_1ffd : 8;
        uint32_t zx_port_trdos_ff : 8;
    } bits;
    
} reg_ZX_Spectrum_io_ports_Struct;

//!@brief C structure representing ZX Spectrum 2021 TR-DOS port register (currently not used).
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t trdos_fifo_read_wr : 8;
        uint32_t reserved : 24;
    } bits;

} reg_ZX_Spectrum_trdos_ports_Struct;

//!@brief C structure representing ZX Spectrum 2021 TR-DOS FIFO control register (currently not used).
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t trdos_fifo_write_rst : 1;
        uint32_t trdos_fifo_write_counter : 11;
        uint32_t reserved : 20;
    } bits;

} reg_ZX_Spectrum_trdos_fifo_ctrl_Struct;

//!@brief C structure representing ZX Spectrum 2021 mouse register (currently not used).
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t mouse_x : 8;
        uint32_t mouse_y : 8;
        uint32_t mouse_buttons : 8;
        uint32_t reserved : 8;
    } bits;

} reg_ZX_Spectrum_mouse_Struct;

//!@brief C structure representing ZX Spectrum 2021 audio config register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t spec_mode : 2;
        uint32_t cpu_turbo : 3;
        uint32_t ay_mode : 2;
        uint32_t turbo_sound : 1;
        uint32_t ayym_mode : 1;
        uint32_t reserved : 23;
    } bits;

} reg_ZX_Spectrum_config_Struct;

//!@brief C structure representing ZX Spectrum 2021 tape FIFO register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t fifo_data : 16;
        uint32_t reserved : 12;
        uint32_t fifo_underflow : 1;
        uint32_t fifo_overflow : 1;
        uint32_t fifo_full : 1;
        uint32_t fifo_empty : 1;
    } bits;

} reg_ZX_Tape_fifo_Struct;


//! @brief Writes to the control register
//! @param *value is a pointer to reg_ZX_Control_Struct to be written
void zx_control_reg_write(reg_ZX_Control_Struct* value);

//! @brief Writes to the AUX attribute register
//! @param *value is a pointer to reg_ZX_Aux_attr_Struct to be written
void zx_aux_attr_reg_write(reg_ZX_Aux_attr_Struct* value);

//! @brief Writes to the border color register
//! @param *value is a pointer to reg_ZX_Border_color_Struct to be written
void zx_border_color_reg_write(reg_ZX_Border_color_Struct* value);

//! @brief Writes to the bitmap address register
//! @param *value is a pointer to reg_ZX_Bitmap_addr_Struct to be written
void zx_bitmap_addr_reg_write(reg_ZX_Bitmap_addr_Struct* value);

//! @brief Writes to the color attribute address register
//! @param *value is a pointer to reg_ZX_Color_attr_addr_Struct to be written
void zx_color_attr_addr_reg_write(reg_ZX_Color_attr_addr_Struct* value);

//! @brief Writes to the active size register
//! @param *value is a pointer to reg_ZX_Active_size_Struct to be written
void zx_active_size_reg_write(reg_ZX_Active_size_Struct* value);

//! @brief Writes to the border size register
//! @param *value is a pointer to reg_ZX_Border_size_Struct to be written
void zx_border_size_reg_write(reg_ZX_Border_size_Struct* value);

//! @brief Sets both the bitmap and color attribute addresses for standard Spectrum screen
//! @param bitmap_address is the start of the bitmap regiion, the address of the color 
//! @param store_border latches current border register if 1 and restores the latched value if 0
//! attributes is calculated as offset from the bitmap address
void zx_vdma_start_address_set(uint32_t bitmap_address, uint8_t store_border);

//! @brief Sets the scaling factor for current screen resolution
//! @param scaling factor is in the range of 1...7
void zx_scaling_factor_set(uint8_t scaling_factor);

//! @brief Sets horizontal left and vertical top postions for ZX border,
//! the horizontal right and vertical bottom positions are calculated by the
//! controller
//! @param hor_left_pos is the horizontal left position, minimal value is 1
//! @param ver_top_pos is the vertical top position, minimal value is 1
void zx_border_set(uint16_t hor_left_pos, uint16_t ver_top_pos);

//! @brief Sets vertical and horizontal screen resolution
//! @param hor_resolution is horizontal resolution in the range of 640...1920
//! @param ver_resolution is vertical resolution in the range of 480...1080
void zx_resolution_set(uint16_t hor_resolution, uint16_t ver_resolution);

//! @brief Enables or disables the video controller
//! @param enabled set to 0 to disable, 1 to enable
void zx_vdma_enable_set(uint8_t enabled);

//! @brief Sets the border color
//! @param value in range of 0...7 as a border color
void zx_border_color_set(uint8_t value);

//! @brief Enables or disables generation of a test pattern
//! @param enabled set to 0 to disable, 1 to enable
void zx_test_mode_set(uint8_t enabled);

//! @brief Writes to the memory test register
//! @param *value is a pointer to reg_ZX_mem_write_test_Struct to be written
void zx_mem_write_reg_write(reg_ZX_mem_write_test_Struct* value);

//! @brief High level function for writing to memory through ZX Spectrum Address and Data bus mapper
//! @param address to be written at
//! @param 8 bit value to be written at a given address
void zx_mem_write(uint32_t address, uint8_t value);

//! @brief Writes to the ZX Spectrum CPU control register
//! @param *value is a pointer to reg_ZX_Spectrum_cpu_control_Struct to be written
void zx_spectrum_control_reg_write(reg_ZX_Spectrum_cpu_control_Struct* value);

//! @brief Writes to the ZX Spectrum IO port register
//! @param *value is a pointer to reg_ZX_Spectrum_io_ports_Struct to be written
void zx_spectrum_io_ports_reg_write(reg_ZX_Spectrum_io_ports_Struct* value);

//! @brief Reads from the ZX Spectrum IO port register
//! @param *value is a pointer to reg_ZX_Spectrum_io_ports_Struct to be read
void zx_spectrum_io_ports_reg_read(reg_ZX_Spectrum_io_ports_Struct* value);

//! @brief Reads from the ZX Spectrum CPU control register
//! @param *value is a pointer to reg_ZX_Spectrum_cpu_control_Struct to be read
void zx_spectrum_control_reg_read(reg_ZX_Spectrum_cpu_control_Struct* value);

//! @brief Writes to the ZX Spectrum tape FIFO register
//! @param *value is a pointer to reg_ZX_Spectrum_io_ports_Struct to be written
void zx_tape_fifo_reg_write(reg_ZX_Tape_fifo_Struct* value);

//! @brief Reads from the ZX Spectrum tape FIFO register
//! @param *value is a pointer to reg_ZX_Spectrum_io_ports_Struct to be read
void zx_tape_fifo_reg_read(reg_ZX_Tape_fifo_Struct* value);

#endif
