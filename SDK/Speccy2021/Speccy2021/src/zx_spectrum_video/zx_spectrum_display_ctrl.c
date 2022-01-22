/*
 Driver for ZX Spectrum Video Controller on Zynq7020
 ===================================================

 This API allows for configuring ZX Spectrum Video 
 Controller from Magictale Electronics. 
 
 The hardware in FPGA fabric is configurable through 
 a set of readable and writable registers and includes 
 control for:
 - horizontal and vertical resolution;
 - scaling factor for ZX Spectrum area;
 - top, bottom, right and left offsets for the border area;
 - color for ZX Spectrum border;
 - start address for ZX Spectrum bitmap region;
 - start address for ZX Spectrum color attribute region;

 Designed in Magictale Electronics.
 
 Copyright (c) 2021 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 
 This code is in the public domain.
*/

#include "zx_spectrum_display_ctrl.h"

#include <xparameters.h>
#include <xil_io.h>

static reg_ZX_Control_Struct control_reg_value;
static reg_ZX_Aux_attr_Struct scaling_factor_value;
static reg_ZX_Border_size_Struct border_size_value;
static reg_ZX_Active_size_Struct active_size_value;
static reg_ZX_Border_color_Struct border_color_value;

//! @brief Loads a register at a specific offset
//! @param reg_offset is the offset from ZX_VIDEO_CTRL_BASE_ADDR
//! @return the result of reading the register
static uint32_t reg_read(uint32_t reg_offset);

//! @brief Writes to a register at a specific offset
//! @param reg_offset is the offset from ZX_VIDEO_CTRL_BASE_ADDR
//! @param value is a 32 bit register value to be written
static void reg_write(uint32_t reg_offset, uint32_t value);


static void reg_write(uint32_t reg_offset, uint32_t value)
{
    Xil_Out32(ZX_VIDEO_CTRL_BASE_ADDR + reg_offset, value);
}

static uint32_t reg_read(uint32_t reg_offset)
{
    return Xil_In32(ZX_VIDEO_CTRL_BASE_ADDR + reg_offset);
}

void zx_control_reg_write(reg_ZX_Control_Struct* value)
{
    reg_write(ZX_VIDEO_CONTROL_REG_OFFSET, value->u32);
}

void zx_aux_attr_reg_write(reg_ZX_Aux_attr_Struct* value)
{
    reg_write(ZX_VIDEO_AUX_ATTR_REG_OFFSET, value->u32);
}

void zx_border_color_reg_write(reg_ZX_Border_color_Struct* value)
{
    reg_write(ZX_VIDEO_BORDER_COLOR_REG_OFFSET, value->u32);
}

void zx_bitmap_addr_reg_write(reg_ZX_Bitmap_addr_Struct* value)
{
    reg_write(ZX_VIDEO_BITMAP_ADDR_REG_OFFSET, value->u32);
}

void zx_color_attr_addr_reg_write(reg_ZX_Color_attr_addr_Struct* value)
{
    reg_write(ZX_VIDEO_COLOR_ADDR_REG_OFFSET, value->u32);
}

void zx_active_size_reg_write(reg_ZX_Active_size_Struct* value)
{
    reg_write(ZX_VIDEO_ACTIVE_SIZE_REG_OFFSET, value->u32);
}

void zx_border_size_reg_write(reg_ZX_Border_size_Struct* value)
{
    reg_write(ZX_VIDEO_BORDER_SIZE_REG_OFFSET, value->u32);
}

void zx_mem_write_reg_write(reg_ZX_mem_write_test_Struct* value)
{
    reg_write(ZX_MEM_WRITE_TEST_REG_OFFSET, value->u32);
}

void zx_spectrum_control_reg_write(reg_ZX_Spectrum_cpu_control_Struct* value)
{
    reg_write(ZX_SPECTRUM_CONTROL_OFFSET, value->u32);
}

void zx_spectrum_io_ports_reg_write(reg_ZX_Spectrum_io_ports_Struct* value)
{
    reg_write(ZX_IO_PORTS_OFFSET, value->u32);
}

void zx_spectrum_io_ports_reg_read(reg_ZX_Spectrum_io_ports_Struct* value)
{
    value->u32 = reg_read(ZX_IO_PORTS_OFFSET);
}

void zx_spectrum_control_reg_read(reg_ZX_Spectrum_cpu_control_Struct* value)
{
    value->u32 = reg_read(ZX_SPECTRUM_CONTROL_OFFSET);
}

void zx_mem_write(uint32_t address, uint8_t value)
{
    reg_ZX_mem_write_test_Struct mem_write_test_reg;
    mem_write_test_reg.bits.address = address;
    mem_write_test_reg.bits.data = value;
    zx_mem_write_reg_write(&mem_write_test_reg);
}

void zx_vdma_start_address_set(uint32_t bitmap_address, uint8_t store_border)
{
    control_reg_value.bits.reg_update = 0;
    control_reg_value.bits.sw_enable = 1;
    control_reg_value.bits.latch_border_color = store_border;
    zx_control_reg_write(&control_reg_value);

    reg_ZX_Bitmap_addr_Struct bitmap_address_reg_value;
    bitmap_address_reg_value.bits.bitmap_addr = bitmap_address;
    zx_bitmap_addr_reg_write(&bitmap_address_reg_value);

    uint32_t color_attr_address = bitmap_address + ZX_PIXEL_DATA_REGION_SIZE;
    reg_ZX_Color_attr_addr_Struct color_attr_address_reg_value;
    color_attr_address_reg_value.bits.color_attr_addr = color_attr_address;
    zx_color_attr_addr_reg_write(&color_attr_address_reg_value);

    control_reg_value.bits.reg_update = 1;
    zx_control_reg_write(&control_reg_value);
}

void zx_scaling_factor_set(uint8_t scaling_factor)
{
    control_reg_value.bits.reg_update = 0;
    control_reg_value.bits.sw_enable = 1;
    zx_control_reg_write(&control_reg_value);

    scaling_factor_value.bits.scaling_factor = scaling_factor;
    zx_aux_attr_reg_write(&scaling_factor_value);

    // FIXME: add overflow check
    border_size_value.bits.horizontal_left = (active_size_value.bits.horizontal - ZX_SPECTRUM_H_RESOLUTION * scaling_factor) / 2;
    border_size_value.bits.vertical_top = (active_size_value.bits.vertical - ZX_SPECTRUM_V_RESOLUTION * scaling_factor) / 2;
    zx_border_size_reg_write(&border_size_value);

    control_reg_value.bits.reg_update = 1;
    zx_control_reg_write(&control_reg_value);
}

void zx_resolution_set(uint16_t hor_resolution, uint16_t ver_resolution)
{
    uint8_t scaling_factor;
    control_reg_value.bits.reg_update = 0;
    control_reg_value.bits.sw_enable = 1;
    zx_control_reg_write(&control_reg_value);

    active_size_value.bits.horizontal = hor_resolution;
    active_size_value.bits.vertical = ver_resolution;
    zx_active_size_reg_write(&active_size_value);

    for (scaling_factor = ZX_MAX_SCALING_FACTOR; scaling_factor > 0; scaling_factor--)
    {
        int32_t horizontal_left = (hor_resolution - ZX_SPECTRUM_H_RESOLUTION * scaling_factor) / 2;
        int32_t vertical_top = (ver_resolution - ZX_SPECTRUM_V_RESOLUTION * scaling_factor) / 2;
        if ((horizontal_left > 0) && (vertical_top > 0))
        {
            break;
        }
    }

    border_size_value.bits.horizontal_left = (hor_resolution - ZX_SPECTRUM_H_RESOLUTION * scaling_factor) / 2;
    border_size_value.bits.vertical_top = (ver_resolution - ZX_SPECTRUM_V_RESOLUTION * scaling_factor) / 2;
    zx_border_size_reg_write(&border_size_value);

    scaling_factor_value.bits.scaling_factor = scaling_factor;
    zx_aux_attr_reg_write(&scaling_factor_value);

    control_reg_value.bits.reg_update = 1;
    zx_control_reg_write(&control_reg_value);
}

void zx_vdma_enable_set(uint8_t enabled)
{
    control_reg_value.bits.sw_enable = enabled;
    zx_control_reg_write(&control_reg_value);
}

void zx_border_color_set(uint8_t value)
{
    border_color_value.bits.border_color = value;
    zx_border_color_reg_write(&border_color_value);
}

void zx_test_mode_set(uint8_t enabled)
{
    control_reg_value.bits.test_pattern_enable = enabled;
    zx_control_reg_write(&control_reg_value);
}

void zx_border_set(uint16_t hor_left_pos, uint16_t ver_top_pos)
{
    border_size_value.bits.horizontal_left = hor_left_pos;
    border_size_value.bits.vertical_top = ver_top_pos;
    zx_border_size_reg_write(&border_size_value);
}

void zx_tape_fifo_reg_write(reg_ZX_Tape_fifo_Struct* value)
{
    reg_write(ZX_TAPE_FIFO_OFFSET, value->u32);
}

void zx_tape_fifo_reg_read(reg_ZX_Tape_fifo_Struct* value)
{
    value->u32 = reg_read(ZX_TAPE_FIFO_OFFSET);
}


