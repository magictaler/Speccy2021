/*
 A general purpose non-thread safe FIFO
 ======================================

 This API implements a simple FIFO 

 Originally designed by SYD as part of Speccy2010 project

 Code cleanup and documenting by Dmitry Pakhomenko (Magictale Electronics) in 2021
*/

#include "zx_fifo.h"


void zx_fifo_init(zx_tape_fifo_Struct* p_zx_fifo, uint8_t* buffer, size_t buffer_size)
{
    p_zx_fifo->buffer = buffer;
    p_zx_fifo->size = buffer_size;

    p_zx_fifo->cntr = 0;
    p_zx_fifo->write_ptr = 0;
    p_zx_fifo->read_ptr = 0;
}

void zx_fifo_clean(zx_tape_fifo_Struct* p_zx_fifo)
{
    p_zx_fifo->cntr = 0;
    p_zx_fifo->write_ptr = 0;
    p_zx_fifo->read_ptr = 0;
}

uint32_t zx_fifo_get_cntr(zx_tape_fifo_Struct* p_zx_fifo)
{
    return p_zx_fifo->cntr;
}

uint32_t zx_fifo_get_free(zx_tape_fifo_Struct* p_zx_fifo)
{
    return (p_zx_fifo->size - p_zx_fifo->cntr);
}

uint8_t zx_fifo_read_byte(zx_tape_fifo_Struct* p_zx_fifo)
{
    if (p_zx_fifo->cntr == 0)
    {
        return 0;
    }
    uint8_t temp_byte = p_zx_fifo->buffer[p_zx_fifo->read_ptr++];
    if (p_zx_fifo->read_ptr >= p_zx_fifo->size)
    {
        p_zx_fifo->read_ptr = 0;
    }
    p_zx_fifo->cntr--;
    return temp_byte;
}

void zx_fifo_write_byte(zx_tape_fifo_Struct* p_zx_fifo, uint8_t value)
{
    if (p_zx_fifo->cntr == p_zx_fifo->size) 
    {
        return;
    }

    p_zx_fifo->buffer[p_zx_fifo->write_ptr++] = value;
    if (p_zx_fifo->write_ptr >= p_zx_fifo->size) 
    {
        p_zx_fifo->write_ptr = 0;
    }
    p_zx_fifo->cntr++;
}

uint32_t zx_filo_read_file(zx_tape_fifo_Struct* p_zx_fifo, uint8_t* s, size_t cnt)
{
    if (cnt > p_zx_fifo->cntr) 
    {
        cnt = p_zx_fifo->cntr;
    }
    for (size_t i = 0; i < cnt; i++ )
    {
        *( s++ ) = p_zx_fifo->buffer[p_zx_fifo->read_ptr++];
        if (p_zx_fifo->read_ptr >= p_zx_fifo->size ) 
        {
            p_zx_fifo->read_ptr = 0;
        }
    }
    p_zx_fifo->cntr -= cnt;
    return cnt;
}
