//! @file zx_loader.h
//! @brief Snapshot file (*.sna) loader
//!   Originally designed by SYD as part of Speccy2010 project

#ifndef ZX_SNAPSHOT_H_INCLUDED
#define ZX_SNAPSHOT_H_INCLUDED

#include <stdio.h>
#include <stdbool.h>
#include <FreeRTOS.h>
#include <task.h>
#include "../zynq_file_io/xilffs_v4_4/ff.h"
#include "../zx_spectrum_io/zx_config.h"
#include "../zx_spectrum_video/zx_spectrum_display_ctrl.h"
#include "xil_cache.h"

//! @brief Initiate the process of a snapshot (*.sna) loading
//! @param *name is a pointer to the file name
bool zx_snapshot_load(const char *file_name);

//! @brief Release the emulated Z80 CPU from reset
void zx_cpu_start(void);

//! @brief Reset the emulated Z80 CPU
//! @param reset set to false causes 7FFD, 1FFD ports to be initialised with 0
void zx_cpu_reset(bool reset);

//! @brief Put the emulated Z80 CPU into HALT mode by stopping the clock
void zx_cpu_stop(void);

//! @brief Get the emulated Z80 CPU HALT status
//! @return true is the CPU is held in HALT mode or false otherwise
bool zx_cpu_stopped(void);

#endif





