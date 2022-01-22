//! @file zx_shell.h
//! @brief Shell to provide with basic navigation through the files and folders on SD card
//!   Originally designed by SYD as part of Speccy2010 project

#ifndef ZX_SHELL_H
#define ZX_SHELL_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include "../zx_spectrum_video/zx_spectrum_display_ctrl.h"
#include "../zx_spectrum_video/zx_spectrum_video.h"
#include "xil_cache.h"
#include "../version.h"
#include "../zynq_file_io/xilffs_v4_4/ff.h"
#include "../zynq_usb/tinyusb/class/hid/hid.h"
#include "zx_snapshot.h"
#include "zx_tape.h"

#define ZX_SHELL_DEFAULT_PAGE (0)

typedef enum
{
    ZX_FONT1 = 0,
    ZX_FONT2 = 1,
    ZX_FONT3 = 2,
    ZX_FONT_LAST_ENTRY
} zx_font_Enum;

//! @brief Handle keyboard events
//! @return true if the even has been consumed or false otherwise
bool zx_shell_hid_keycode_handle(uint8_t keycode);

//! @brief Get the shell status
//! @return true if the shell is active or false otherwise
bool zx_shell_active_get(void);

#endif





