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

#include "speccy2021.h"

#define UART_BASEADDR XPAR_PS7_UART_0_BASEADDR


uint32_t speccy_main_thread(void)
{
    /* This is the main thread responsible for hardware initialisation 
       and emulation of some peripherals in software which real 
       ZX Spectrum didn't have or wasn't aware of. This includes SD card, 
       FAT16/32 file system, USB stack and tape recorder emulator.
    */
    u32 *z80_address_space;

    zx_spectrum_video_init();
    z80_address_space = (u32*)EMULATOR_MEMORY_AREA_START;
    
    // Disable caching - Zynq specific
    Xil_SetTlbAttributes((UINTPTR)&z80_address_space, ZYNQ_MARK_UNCACHEABLE);

    zx_vdma_start_address_set(EMULATOR_MEMORY_AREA_START + EMULATOR_VDMA_AREA_OFFSET, 1);

    reg_ZX_Spectrum_cpu_control_Struct speccy2021_cpu_control_reg;
    speccy2021_cpu_control_reg.bits.cpu_halt_req = 0;
    speccy2021_cpu_control_reg.bits.cpu_restore_pc_n = 1;
    zx_spectrum_control_reg_write(&speccy2021_cpu_control_reg);

    zynq_sd_card_init();
    tusb_init();
    while (true)
    {
        tuh_task();
        zx_tape_routine();
    }

    return -1;
}


//! @brief A top level function to handle events from USB keyboard
//! @param keycode is a HID keycode
//! @return true is the keycode was handled and consumed by the top level PS emulator 
//!   (in other words, the keycode was consumed by the shell) 
//!   otherwise it should be fed through a register into ZX machine in PL
bool hid_keycode_cb(uint8_t keycode)
{
    bool res = false;
    if (zx_shell_hid_keycode_handle(keycode) == true)
    {
        zx_tape_hid_keycode_handle(keycode);
        res = true;
    }
    return res;
}

