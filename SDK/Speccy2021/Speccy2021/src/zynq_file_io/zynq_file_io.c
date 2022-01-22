/*
 High level glue logic for SD card and FAT file system
 =====================================================

 This API allows for initialising SD card and mounting
 FAT file system on Zynq7020 hardware 

 Designed in Magictale Electronics.
 
 Copyright (c) 2021 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 
 This code is in the public domain.
*/

#include "zynq_file_io.h"

#include "../zynq_file_io/xilffs_v4_4/diskio.h"
#include "../zynq_file_io/xilffs_v4_4/ff.h"

bool zynq_sd_card_init(void)
{
    DSTATUS ds;
    FRESULT f_res = FR_NOT_ENABLED;

    ds = disk_initialize(0);
    if (ds == RES_OK)
    {
        static FATFS fatfs;
        f_res = f_mount(&fatfs, "0:", 1);
    }

    return f_res == FR_OK;
}
