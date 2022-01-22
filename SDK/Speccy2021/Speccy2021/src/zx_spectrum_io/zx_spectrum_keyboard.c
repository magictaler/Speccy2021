/*
 Mapper for ZX Spectrum Keyboard
 ===================================================

 This API allows mapping HID keycodes into standard
 ZX Spectrum keyboard ports through just two AXI 
 registers. This module uses the API and the address 
 space provided by the the zx_spectrum_display_ctrl.h
 to save on resources. 

 Designed in Magictale Electronics.

 Copyright (c) 2021 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 
 This code is in the public domain.
*/

#include "zx_spectrum_keyboard.h"

#include "../zx_spectrum_video/zx_spectrum_display_ctrl.h"
#include "../zynq_usb/tinyusb/tusb.h"
#include "../zx_spectrum_file_io/zx_tape.h"
#include <xparameters.h>
#include <xil_io.h>


static uint8_t const keycode2zx_kbd[128][2] =  { HID_KEYCODE_TO_ZX_KBD };

extern bool hid_keycode_cb(uint8_t keycode);


//! @brief Writes to a register at a specific offset
//! @param reg_offset is the offset from ZX_VIDEO_CTRL_BASE_ADDR
//! @param value is a 32 bit register value to be written
static void reg_write(uint32_t reg_offset, uint32_t value);


void static reg_write(uint32_t reg_offset, uint32_t value)
{
    Xil_Out32(ZX_VIDEO_CTRL_BASE_ADDR + reg_offset, value);
}

void zx_keyboard_reg1_write(reg_ZX_Keyboard_Reg1_Struct* value)
{
    reg_write(ZX_KEYBOARD_REG1_OFFSET, value->u32);
}

void zx_keyboard_reg2_write(reg_ZX_Keyboard_Reg2_Struct* value)
{
    reg_write(ZX_KEYBOARD_REG2_OFFSET, value->u32);
}

// HID callback
void tuh_hid_report_received_cb(uint8_t dev_addr, uint8_t instance, uint8_t const* report, uint16_t len)
{
    uint8_t const itf_protocol = tuh_hid_interface_protocol(dev_addr, instance);

    switch (itf_protocol)
    {
        case HID_ITF_PROTOCOL_KEYBOARD:
            TU_LOG2("HID receive boot keyboard report\r\n");
            zx_keyboard_process_kbd_report( (hid_keyboard_report_t const*) report );
        break;

        //case HID_ITF_PROTOCOL_MOUSE:
        //    TU_LOG2("HID receive boot mouse report\r\n");
        //    process_mouse_report( (hid_mouse_report_t const*) report );
        //break;
    }

    // continue to request to receive report
    if (!tuh_hid_receive_report(dev_addr, instance))
    {
        xil_printf("Error: cannot request to receive report\r\n");
    }
}

// HID callback
void tuh_hid_mount_cb(uint8_t dev_addr, uint8_t instance, uint8_t const* desc_report, uint16_t desc_len)
{
    // request to receive report
    // tuh_hid_report_received_cb() will be invoked when report is available
    if (!tuh_hid_receive_report(dev_addr, instance))
    {
        xil_printf("Error: cannot request to receive report\r\n");
    }
}

void zx_keyboard_process_kbd_report(hid_keyboard_report_t const *report)
{
    reg_ZX_Keyboard_Reg1_Struct zx_keyboard_reg1;
    reg_ZX_Keyboard_Reg2_Struct zx_keyboard_reg2;
    zx_keyboard_reg1.u32 = ZX_KEYBOARD_ALL_BUTTONS_RELEASED;
    zx_keyboard_reg2.u32 = ZX_KEYBOARD_ALL_BUTTONS_RELEASED;
    bool const is_shift = report->modifier & (KEYBOARD_MODIFIER_LEFTSHIFT | KEYBOARD_MODIFIER_RIGHTSHIFT);
    for (uint8_t i = 0; i < sizeof(report->keycode) / sizeof(uint8_t); i++)
    {
        // HID report is capable of registering up to six simultaneously pressed and held buttons,
        // (not even counting SHIFT) while the electrical circuit of the standard ZX Spectrum was
        // only capable of handling just two so we are risking to compromise compatibility...
        // Should we handle only two first buttons in the report and ignore the others? Hmmm
        if (report->keycode[i])
        {
            uint8_t kbd_bitnum = keycode2zx_kbd[report->keycode[i]][0];
            uint8_t kbd_port = keycode2zx_kbd[report->keycode[i]][1];

            // let's map to the emulator
            if (hid_keycode_cb(report->keycode[i]) == false)
            {
                // we get here only if the ZX shell is inactive
                if (kbd_port == ZX_KEYBOARD_PORT1)
                {
                    zx_keyboard_reg1.u32 &= ~(1 << kbd_bitnum);
                }
                else if (kbd_port == ZX_KEYBOARD_PORT2)
                {
                    zx_keyboard_reg2.u32 &= ~(1 << kbd_bitnum);
                }
            }
        }
    }
    if (is_shift == true)
    {
        zx_keyboard_reg1.u32 &= ~(1 << ZX_KEYBOARD_SHIFT_BIT);
    }
    zx_keyboard_reg1_write(&zx_keyboard_reg1);
    zx_keyboard_reg2_write(&zx_keyboard_reg2);
}


