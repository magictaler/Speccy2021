/*
 A subset of TUSB1210 Tranceiver registers for direct communication with it 
 through the ULPI Viewport register on Zynq7020 SOC. This is to avoid 
 limitation of the Zynq7020 when initialising the USB controller in host mode. 
 The patch was specifically designed for the Arty Z20 boards from Digilent and
 may or may not work with other hardware designs.

 Copyright (c) 2021 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 
 This code is in the public domain.
*/

#ifndef ULPI_H
#define ULPI_H

#include <stdint.h>

// ULPI
#define XUSBPS_ULPI_VENDOR_ID_REG_OFFSET 0x0
#define XUSBPS_ULPI_OTG_CTRL_REG_OFFSET 0x0A

#define ULPI_TUSB1210_VENDOR_ID 0x51

//!@brief C structure representing ULPI_OTG_CTRL register.
typedef union
{
    uint32_t u8;

    struct
    {
        uint8_t id_pullup : 1;
        uint8_t dp_pulldown : 1;
        uint8_t dm_pulldown : 1;
        uint8_t dischrg_vbus : 1;
        uint8_t chrg_vbus : 1;
        uint8_t drv_vbus : 1;
        uint8_t drv_vbus_external : 1;
        uint8_t use_external_vbus_indicator : 1;

    } bits;

} reg_ULPI_OTG_CTRL_Struct;


#endif
