//! @file zynq_file_io.h
//! @brief High level SD card initialising logic

#ifndef ZYNQ_FILE_IO_H
#define ZYNQ_FILE_IO_H

#include <stdint.h>
#include <stdbool.h>

//! @brief Initialise SD card and FAT16/32 system
//! @return true if SD is detected and the file system is mounted or false otherwise
bool zynq_sd_card_init(void);


#endif /* ZYNQ_FILE_IO_H */
