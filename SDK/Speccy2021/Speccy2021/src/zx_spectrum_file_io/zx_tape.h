//! @file zx_tape.h
//! @brief Emulator of tape recorder
//!   Originally designed by SYD as part of Speccy2010 project

#ifndef ZX_TAPE_H
#define ZX_TAPE_H

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "zx_fifo.h"
#include "../zynq_file_io/xilffs_v4_4/ff.h"
#include "../zx_spectrum_video/zx_spectrum_display_ctrl.h"
#include "../zynq_usb/tinyusb/class/hid/hid.h"

//! @brief Select *.tap, *.tzx file for playback
//! @param *name is a pointer to the file name
void zx_tape_select_file(const char *name);

//! @brief Start playback for a selected file
void zx_tape_start(void);

//! @brief Stop playback of a file
void zx_tape_stop(void);

//! @brief Restart playback of a file
void zx_tape_restart(void);

//! @brief Get playback status
//! @return true is playback is active false otherwise
bool zx_tape_started(void);

//! @brief Non-blocking routine which should be periodically called from main thread
void zx_tape_routine(void);

//! @brief Handle keyboard events
//! @return true if the even has been consumed false otherwise
bool zx_tape_hid_keycode_handle(uint8_t keycode);

#endif


