//! @file zx_fifo.h
//! @brief A general purpose non-thread safe FIFO
//!   Originally designed by SYD as part of Speccy2010 project

#ifndef ZX_FIFO_H
#define ZX_FIFO_H

#include <stdio.h>
#include <stdbool.h>

typedef struct
{
    uint8_t *buffer;
    uint32_t size;
    uint32_t cntr;
    uint32_t write_ptr;
    uint32_t read_ptr;
} zx_tape_fifo_Struct;


//! @brief Initialise FIFO 
//! @param *p_zx_fifo is a pointer to zx_tape_fifo_Struct
//! @param *buffer is a pointer to allocated chunk of memory for storing FIFO elements
//! @param buffer_size is the size of the allocated memory
void zx_fifo_init(zx_tape_fifo_Struct* p_zx_fifo, uint8_t* buffer, size_t buffer_size);

//! @brief Reset FIFO to its initial state, remove all the stored elements
//! @param *p_zx_fifo is a pointer to zx_tape_fifo_Struct
void zx_fifo_clean(zx_tape_fifo_Struct* p_zx_fifo);

//! @brief Get the number of elements stored in FIFO
//! @param *p_zx_fifo is a pointer to zx_tape_fifo_Struct
//! @return the number of stored elements (bytes)
uint32_t zx_fifo_get_cntr(zx_tape_fifo_Struct* p_zx_fifo);

//! @brief Get the size of the FIFO availabe for storing
//! @param *p_zx_fifo is a pointer to zx_tape_fifo_Struct
//! @return the number of available elements (bytes)
uint32_t zx_fifo_get_free(zx_tape_fifo_Struct* p_zx_fifo);

//! @brief Read one element (byte) from the FIFO. Before reading 
//!   the number of available bytes should be checked with @zx_fifo_get_cntr
//! @param *p_zx_fifo is a pointer to zx_tape_fifo_Struct
//! @return the next available byte
uint8_t zx_fifo_read_byte(zx_tape_fifo_Struct* p_zx_fifo);

//! @brief Write one element (byte) to the FIFO. Before writing
//!   the free space should be checked with @zx_fifo_get_free
//! @param *p_zx_fifo is a pointer to zx_tape_fifo_Struct
//! @param the element (byte) to be written
void zx_fifo_write_byte(zx_tape_fifo_Struct* p_zx_fifo, uint8_t value);

//! @brief Read a number of elements (bytes) from the FIFO. 
//! @param *p_zx_fifo is a pointer to zx_tape_fifo_Struct
//! @param *s is a pointer to the read buffer
//! @param cnt is the number of bytes to be read, must not exceed the size of the buffer
//! @return the number of bytes actually read
uint32_t zx_filo_read_file(zx_tape_fifo_Struct* p_zx_fifo, uint8_t* s, size_t cnt);

#endif
