//! @file zx_spectrun_keyboard.h
//! @brief Mapper between HID keycodes and ZX Spectrum keyboard

#ifndef ZX_SPECTRUM_KEYBOARD_H
#define ZX_SPECTRUM_KEYBOARD_H

#include <stdint.h>

#include "../zynq_usb/tinyusb/class/hid/hid.h"

// ZX:   FEFE port                  |  FDFE port                  |  FBFE port                  |  F7FE port
//     ----------------------------------------------------------------------------------------------------------------------
// bits  4     3     2     1     0  |  4     3     2     1     0  |  4     3     2     1     0  |  4     3     2     1     0
//      'V'   'C'   'X'   'Z'  Shift| 'G'   'F'   'D'   'S'   'A' | 'T'   'R'   'E'   'W'   'Q' | '5'   '4'   '3'   '2'   '1'
//     ----------------------------------------------------------------------------------------------------------------------
// AXI: Keyboard port '1':
// bits 19    18    17    16    15  | 14    13    12    11    10  |  9     8     7     6     5  |  4     3     2     1     0

// ZX:   EFFE port                  |  DFFE port                  |  BFFE port                  |  7FFE port
//     ----------------------------------------------------------------------------------------------------------------------
// bits  4     3     2     1     0  |  4     3     2     1     0  |  4     3     2     1     0  |  4     3     2     1     0
//      '6'   '7'   '8'   '9'   '0' | 'Y'   'U'   'I'   'O'   'P' | 'H'   'J'   'K'   'L'  Enter| 'B'   'N'   'M'   SYM  Space
//     ----------------------------------------------------------------------------------------------------------------------
// AXI: Keyboard port '2':
// bits 19    18    17    16    15  | 14    13    12    11    10  |  9     8     7     6     5  |  4     3     2     1     0

enum
{
    ZX_KEYBOARD_NO_MAPPING = 0,
    ZX_KEYBOARD_PORT1 = 1,
    ZX_KEYBOARD_PORT2 = 2,
};

#define ZX_KEYBOARD_ALL_BUTTONS_RELEASED 0xFFFFF

#define ZX_KEYBOARD_SHIFT_BIT 15

//Bit num  Port num
#define HID_KEYCODE_TO_ZX_KBD    \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x00 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x01 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x02 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x03 */ \
    {10    , ZX_KEYBOARD_PORT1           }, /* 0x04 */ \
    {4     , ZX_KEYBOARD_PORT2           }, /* 0x05 */ \
    {18    , ZX_KEYBOARD_PORT1           }, /* 0x06 */ \
    {12    , ZX_KEYBOARD_PORT1           }, /* 0x07 */ \
    {7     , ZX_KEYBOARD_PORT1           }, /* 0x08 */ \
    {13    , ZX_KEYBOARD_PORT1           }, /* 0x09 */ \
    {14    , ZX_KEYBOARD_PORT1           }, /* 0x0a */ \
    {9     , ZX_KEYBOARD_PORT2           }, /* 0x0b */ \
    {12    , ZX_KEYBOARD_PORT2           }, /* 0x0c */ \
    {8     , ZX_KEYBOARD_PORT2           }, /* 0x0d */ \
    {7     , ZX_KEYBOARD_PORT2           }, /* 0x0e */ \
    {6     , ZX_KEYBOARD_PORT2           }, /* 0x0f */ \
    {2     , ZX_KEYBOARD_PORT2           }, /* 0x10 */ \
    {3     , ZX_KEYBOARD_PORT2           }, /* 0x11 */ \
    {11    , ZX_KEYBOARD_PORT2           }, /* 0x12 */ \
    {10    , ZX_KEYBOARD_PORT2           }, /* 0x13 */ \
    {5     , ZX_KEYBOARD_PORT1           }, /* 0x14 */ \
    {8     , ZX_KEYBOARD_PORT1           }, /* 0x15 */ \
    {11    , ZX_KEYBOARD_PORT1           }, /* 0x16 */ \
    {9     , ZX_KEYBOARD_PORT1           }, /* 0x17 */ \
    {13    , ZX_KEYBOARD_PORT2           }, /* 0x18 */ \
    {19    , ZX_KEYBOARD_PORT1           }, /* 0x19 */ \
    {6     , ZX_KEYBOARD_PORT1           }, /* 0x1a */ \
    {17    , ZX_KEYBOARD_PORT1           }, /* 0x1b */ \
    {14    , ZX_KEYBOARD_PORT2           }, /* 0x1c */ \
    {16    , ZX_KEYBOARD_PORT1           }, /* 0x1d */ \
    {0     , ZX_KEYBOARD_PORT1           }, /* 0x1e */ \
    {1     , ZX_KEYBOARD_PORT1           }, /* 0x1f */ \
    {2     , ZX_KEYBOARD_PORT1           }, /* 0x20 */ \
    {3     , ZX_KEYBOARD_PORT1           }, /* 0x21 */ \
    {4     , ZX_KEYBOARD_PORT1           }, /* 0x22 */ \
    {19    , ZX_KEYBOARD_PORT2           }, /* 0x23 */ \
    {18    , ZX_KEYBOARD_PORT2           }, /* 0x24 */ \
    {17    , ZX_KEYBOARD_PORT2           }, /* 0x25 */ \
    {16    , ZX_KEYBOARD_PORT2           }, /* 0x26 */ \
    {15    , ZX_KEYBOARD_PORT2           }, /* 0x27 */ \
    {5     , ZX_KEYBOARD_PORT2           }, /* 0x28 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x29 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x2a */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x2b */ \
    {0     , ZX_KEYBOARD_PORT2           }, /* 0x2c */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x2d */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x2e */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x2f */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x30 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x31 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x32 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x33 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x34 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x35 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x36 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x37 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x38 */ \
                                  \
    {1     , ZX_KEYBOARD_PORT2           }, /* 0x39 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x3a */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x3b */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x3c */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x3d */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x3e */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x3f */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x40 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x41 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x42 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x43 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x44 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x45 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x46 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x47 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x48 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x49 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x4a */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x4b */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x4c */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x4d */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x4e */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x4f */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x50 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x51 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x52 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x53 */ \
                                  \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x54 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x55 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x56 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x57 */ \
    {5     , ZX_KEYBOARD_PORT2           }, /* 0x58 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x59 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x5a */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x5b */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x5c */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x5d */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x5e */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x5f */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x60 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x61 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x62 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x63 */ \
    {0     , ZX_KEYBOARD_NO_MAPPING      }, /* 0x67 */ \


//!@brief C structure representing our internal keyboard register 1.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t keyboard_buttons :20;
        uint32_t reserved :12;
    } bits;

} reg_ZX_Keyboard_Reg1_Struct;

//!@brief C structure representing our internal keyboard register 2.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t keyboard_buttons :20;
        uint32_t reserved :12;
    } bits;

} reg_ZX_Keyboard_Reg2_Struct;

//! @brief Write to the first keyboard register
//! @param *value is a pointer to reg_ZX_Keyboard_Reg1_Struct to be written
void zx_keyboard_reg1_write(reg_ZX_Keyboard_Reg1_Struct* value);

//! @brief Write to the second keyboard register
//! @param *value is a pointer to reg_ZX_Keyboard_Reg1_Struct to be written
void zx_keyboard_reg2_write(reg_ZX_Keyboard_Reg2_Struct* value);

//! @brief Low level handler of HID keycodes
//! @param *report is a pointer to the hid_keyboard_report_t struct
void zx_keyboard_process_kbd_report(hid_keyboard_report_t const *report);

#endif
