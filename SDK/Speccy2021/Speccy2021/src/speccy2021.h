/*
 Speccy-2021, a ZX Spectrum Emulator on Arty-Z7 (Zynq7020)
 =========================================================

 This is the emulator initialisation logic


 Designed in Magictale Electronics.
 
 Copyright (c) 2021 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 
 This code is in the public domain.
*/


#ifndef SPECCY_2021_H
#define SPECCY_2021_H

#include <FreeRTOS.h>
#include <task.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <xil_printf.h>
#include <xil_mmu.h>
#include <lwip/sys.h>
#include "xuartps.h"
#include "math.h"
#include "xil_cache.h"
#include "xil_types.h"
#include "xparameters.h"
#include "xil_io.h"
#include "zynq_video/display_ctrl/display_ctrl.h"
#include "zynq_misc/timer_ps/timer_ps.h"
#include "zx_spectrum_video/zx_spectrum_display_ctrl.h"
#include "zx_spectrum_video/zx_spectrum_video.h"
#include "zx_spectrum_io/zx_spectrum_keyboard.h"
#include "zx_spectrum_io/zx_config.h"
#include "zx_spectrum_file_io/zx_snapshot.h"
#include "zynq_usb/tinyusb/tusb.h"
#include "zynq_usb/tinyusb/host/usbh.h"
#include "zynq_file_io/xilffs_v4_4/diskio.h"
#include "zynq_file_io/xilffs_v4_4/ff.h"
#include "zynq_file_io/zynq_file_io.h"
#include "zx_spectrum_file_io/zx_shell.h"
#include "zx_spectrum_file_io/zx_tape.h"

#define DEFAULT_THREAD_PRIO 2
#define ZYNQ_MARK_UNCACHEABLE 0x14de2U
#define DEMO_TIMEOUT_DEFAULT_US (5000000U)

static const uint32_t THREAD_STACKSIZE = 4096;

//! @brief The main thread of the project
//! @return error code as uint
uint32_t speccy_main_thread(void);


#endif /* SPECCY_2021_H */
