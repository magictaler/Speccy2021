//! @file zx_spectrum_video.h
//! @brief High level API for ZX Spectrum Video Controller

#ifndef ZX_SPECTRUM_VIDEO_H
#define ZX_SPECTRUM_VIDEO_H

#include <stdbool.h>
#include "zx_spectrum_display_ctrl.h"

typedef struct
{
    uint8_t zx_spectrum_frameBuf[ZX_SPECTRUM_VRAM_SIZE] __attribute__ ((aligned (ZX_SPECTRUM_VRAM_MIN_ALIGNMENT)));
} ZXFrameBufStruct;

//! @brief Initialise ZX Spectrum video
void zx_spectrum_video_init(void);

//! @brief Switch to a specific video page
//! @param page number to switch to
bool zx_spectrum_activate_shell_vpage(uint32_t page);

//! @brief Get a pointer to the video memory of a specific video page
//! @param page number
//! @return a pointer to the start address of the given page
uint8_t* zx_spectrum_shell_vpage_address(uint32_t page);

#endif
