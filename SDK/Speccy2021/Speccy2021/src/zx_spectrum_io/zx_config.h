//! @file zx_config.h
//! @brief Some fundamental emulator definitions

#ifndef ZX_CONFIG_H
#define ZX_CONFIG_H

#include <stdint.h>

#define EMULATOR_MEMORY_AREA_START (0x8000000U)
#define EMULATOR_PAGE_SIZE (0x4000U)
#define EMULATOR_VDMA_AREA_OFFSET (0x24000U)

#define EMULATOR_ROM_PAGES_COUNT (4)
#define EMULATOR_PAGE_LEFT_SHIFT_BITS (14)
#define EMULATOR_THREE_PAGE_SIZE (0xC000U)
#define EMULATOR_PAGE_2 (2)

#endif
