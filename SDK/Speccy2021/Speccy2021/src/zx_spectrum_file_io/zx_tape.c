/*
 Emulator of a tape recorder
 ===========================

 This logic allows for generating of an audio signal in the format of 
 original ZX Spectrum so that it can load binary streams as if they were
 played by a tape recorder.

 Originally designed by SYD as part of Speccy2010 project

 Code cleanup and documenting by Dmitry Pakhomenko (Magictale Electronics) in 2021
*/

#include "zx_tape.h"

#define ZX_TAPE_BLOCK_DATA 0
#define ZX_TAPE_SEQUENCE_DATA 1
#define ZX_TAPE_SKIP_DATA 2
#define ZX_TAPE_PATH_SIZE 0x80
#define ZX_TAPE_LOOPS_SIZE 0x10
#define ZX_TAPE_FIFO_DEPTH 0x30

typedef struct
{
    uint32_t fptr;
    uint32_t counter;
} zx_tape_loop_Struct;

typedef struct
{
    uint32_t pulse_pilot;
    uint32_t pulse_sync1;
    uint32_t pulse_sync2;
    uint32_t pulse_zero;
    uint32_t pulse_one;
    uint8_t block_lastbit;
    uint16_t tape_pilot;
    uint8_t tape_sync;
    uint16_t tape_pause;
    uint32_t data_size;
    uint8_t data_type;
} zx_tape_block_Struct;

static reg_ZX_Tape_fifo_Struct zx_tape_fifo_reg;
static bool zx_tape_tape_started = false;
static bool zx_tape_tape_restart = false;
static bool zx_tape_tape_finished = false;
static bool zx_tape_tzx = false;
static zx_tape_block_Struct zx_tape_current_block;
static char zx_tape_path[ZX_TAPE_PATH_SIZE];
static zx_tape_fifo_Struct zx_tape_fifo;
static uint8_t zx_tape_fifo_buf[ZX_TAPE_FIFO_DEPTH];

//! @brief Get the status of the FIFO
//! @return true if the FIFO is full or false otherwise
static bool zx_tape_fifo_full(void);

//! @brief Put the audio data into the FIFO
//! @param pulseLength is the length of the pulse in ZX Spectrum units
//! @param pulse is set to true for a pulse or false otherwise
static void zx_tape_send(uint16_t pulseLength, bool pulse);

//! @brief Fill the FIFO with a new portion of audio data
//! @return false if the end of data stream has been reached or true otherwise
static bool zx_tape_fill_buffer(void);


void zx_tape_block_clean(zx_tape_block_Struct* zx_tape_block)
{
    zx_tape_block->tape_pilot = 0;
    zx_tape_block->tape_sync = 0;
    zx_tape_block->tape_pause = 0;
    zx_tape_block->data_size = 0;
}

bool zx_tape_hid_keycode_handle(uint8_t keycode)
{
    bool res = false;
    if (HID_KEY_MINUS == keycode)
    {
        if (zx_tape_started())
        {
            zx_tape_stop();
        }
        else
        {
            zx_tape_start();
        }
        res = true;
    }
    return res;
}

uint16_t zx_tape_read_word(uint8_t* header)
{
    return (uint16_t)header[0] | ((uint16_t)header[1] << 8);
}

uint32_t zx_tape_read_word3(uint8_t* header)
{
    return (uint16_t)header[0] | ((uint16_t)header[1] << 8) | ((uint32_t)header[2] << 16);
}

uint32_t zx_tape_read_dword(uint8_t* header)
{
   return (uint16_t)header[0] | ((uint16_t)header[1] << 8) | ((uint32_t)header[2] << 16) | ((uint16_t)header[3] << 24);
}

uint32_t zx_tape_convert(uint32_t ticks)
{
    return ticks * 111 / 100;
}

void zx_tape_block_parse_header(uint8_t* header, zx_tape_block_Struct* zx_tape_block)
{
    zx_tape_block->pulse_pilot = zx_tape_convert(2168);
    zx_tape_block->pulse_sync1 = zx_tape_convert(667);
    zx_tape_block->pulse_sync2 = zx_tape_convert(735);
    zx_tape_block->pulse_zero  = zx_tape_convert(855);
    zx_tape_block->pulse_one   = zx_tape_convert(1710);
    zx_tape_block->block_lastbit = 0;

    zx_tape_block->tape_pilot = 0;
    zx_tape_block->tape_sync = 0;
    zx_tape_block->tape_pause = 0;
    zx_tape_block->data_size = 0;

    if (!zx_tape_tzx)
    {
        zx_tape_block->tape_pilot = 6000;
        zx_tape_block->tape_sync = 2;
        zx_tape_block->tape_pause = 2000;

        zx_tape_block->data_size = zx_tape_read_word(header);
        zx_tape_block->data_type = ZX_TAPE_BLOCK_DATA;
    }
    else
    {
       switch ( header[0] )
       {
            case 0x10:
                zx_tape_block->tape_pilot = 6000;
                zx_tape_block->tape_sync = 2;
                zx_tape_block->tape_pause = zx_tape_read_word(header + 1);

                zx_tape_block->data_size = zx_tape_read_word(header + 3);
                zx_tape_block->data_type = ZX_TAPE_BLOCK_DATA;
                break;

            case 0x11:
                zx_tape_block->pulse_pilot = zx_tape_convert(zx_tape_read_word(header + 1));
                zx_tape_block->pulse_sync1 = zx_tape_convert(zx_tape_read_word(header + 3));
                zx_tape_block->pulse_sync2 = zx_tape_convert(zx_tape_read_word(header + 5));
                zx_tape_block->pulse_zero = zx_tape_convert(zx_tape_read_word(header + 7));
                zx_tape_block->pulse_one = zx_tape_convert(zx_tape_read_word(header + 9));

                zx_tape_block->tape_pilot = zx_tape_read_word(header + 11);
                zx_tape_block->tape_sync = 2;
                zx_tape_block->block_lastbit = (8 - header[13]) * 2;
                zx_tape_block->tape_pause = zx_tape_read_word(header + 14);

                zx_tape_block->data_size = zx_tape_read_word3(header + 16);
                zx_tape_block->data_type = ZX_TAPE_BLOCK_DATA;
                break;

            case 0x12:
                zx_tape_block->pulse_pilot = zx_tape_convert(zx_tape_read_word(header + 1));
                zx_tape_block->tape_pilot = zx_tape_read_word(header + 3);
                break;

            case 0x13:
                zx_tape_block->data_size = header[1] * 2;
                zx_tape_block->data_type = ZX_TAPE_SEQUENCE_DATA;
                break;

            case 0x14:
                zx_tape_block->pulse_zero = zx_tape_convert(zx_tape_read_word(header + 1));
                zx_tape_block->pulse_one = zx_tape_convert(zx_tape_read_word(header + 3));
                zx_tape_block->block_lastbit = (8 - header[5]) * 2;
                zx_tape_block->tape_pause = zx_tape_read_word(header + 6);

                zx_tape_block->data_size = zx_tape_read_word3(header + 8);
                zx_tape_block->data_type = ZX_TAPE_BLOCK_DATA;
                break;

            case 0x15:
                zx_tape_block->data_size = zx_tape_read_word3(header + 6) * 2;
                zx_tape_block->data_type = ZX_TAPE_SKIP_DATA;
                break;

            case 0x20:
                zx_tape_block->tape_pause = zx_tape_read_word(header + 1);
                break;

            case 0x21:
            case 0x30:
                zx_tape_block->data_size = header[1];
                zx_tape_block->data_type = ZX_TAPE_SKIP_DATA;
                break;

            case 0x22:
                break;
            case 0x23:
                break;
            case 0x24:
                break;
            case 0x25:
                break;
            case 0x31:
                zx_tape_block->data_size = header[2];
                zx_tape_block->data_type = ZX_TAPE_SKIP_DATA;
                break;
            case 0x32:
                zx_tape_block->data_size = zx_tape_read_word(header + 1);
                zx_tape_block->data_type = ZX_TAPE_SKIP_DATA;
                break;
            case 0x33:
                zx_tape_block->data_size = header[1] * 3;
                zx_tape_block->data_type = ZX_TAPE_SKIP_DATA;
                break;
            case 0x34:
                break;
            case 0x35:
                zx_tape_block->data_size = zx_tape_read_dword(header + 0x11);
                zx_tape_block->data_type = ZX_TAPE_SKIP_DATA;
                break;
            case 0x40:
                zx_tape_block->data_size = zx_tape_read_word3(header + 9);
                zx_tape_block->data_type = ZX_TAPE_SKIP_DATA;
                break;

            case 0x5A:
                break;

            default:
                zx_tape_block->data_size = zx_tape_read_dword(header + 1);
                zx_tape_block->data_type = ZX_TAPE_SKIP_DATA;
                break;
        }
    }
}

void zx_tape_select_file(const char *name)
{
    sniprintf(zx_tape_path, sizeof(zx_tape_path), "%s", name);
}

void zx_tape_start()
{
    zx_tape_tape_started = true;

    zx_fifo_init(&zx_tape_fifo, zx_tape_fifo_buf, ZX_TAPE_FIFO_DEPTH);
    zx_fifo_clean(&zx_tape_fifo);
}

void zx_tape_stop()
{
    zx_tape_tape_started = false;
}

void zx_tape_restart()
{
    zx_tape_block_clean(&zx_tape_current_block);

    zx_fifo_init(&zx_tape_fifo, zx_tape_fifo_buf, ZX_TAPE_FIFO_DEPTH);
    zx_fifo_clean(&zx_tape_fifo);

    zx_tape_tape_restart = true;
    zx_tape_tape_started = true;
}

bool zx_tape_started()
{
    return zx_tape_tape_started;
}

uint8_t zx_tape_get_header_size(uint8_t code)
{
    if (zx_tape_tzx)
    {
        const uint8_t tzx_header_size[] =
        {
            5, 19, 5, 2, 11, 9, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 2, 1, 3, 3, 1, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 3, 3, 2, 9, 0x15,
        };

        if( code == 'Z' ) return 10;
        else return tzx_header_size[ code - 0x10 ];
    }
    else return 2;
}

uint32_t zx_tape_get_data_size(uint8_t* header)
{
    if (zx_tape_tzx) return 0;
    else return zx_tape_read_word(header);
}

void zx_tape_routine()
{
    static FIL tape_file;
    static uint32_t header_size = 0;
    static uint32_t data_size = 0;
    static zx_tape_loop_Struct loops[ZX_TAPE_LOOPS_SIZE];
    static int loops_size;

    if (!zx_tape_tape_started && f_size(&tape_file) != 0 && tape_file.fptr >= f_size(&tape_file))
    {
        zx_tape_tape_restart = true;
    }

    //if (zx_tape_tape_started && (f_size(&tape_file) == 0 || zx_tape_tape_restart))
    if (zx_tape_tape_started && f_eof(&tape_file) == 1)
    {
        if (f_open(&tape_file, zx_tape_path, FA_READ ) == FR_OK)
        {
            f_lseek(&tape_file, 0);
            zx_tape_tzx = false;

            header_size = 0;
            data_size = 0;
            loops_size = 0;

            if (f_size(&tape_file) >= 10)
            {
                char buff[10];
                UINT res;
                f_read(&tape_file, buff, 10, &res);

                if (res == 10 && buff[0] == 'Z' && buff[1] == 'X' && buff[2] == 'T' ) zx_tape_tzx = true;
                else f_lseek(&tape_file, 0);
            }
        }
        else
        {
            zx_tape_tape_started = false;
        }

        zx_tape_tape_restart = false;
    }

    static uint8_t header[0x20];
    static uint32_t header_pos;

    while (zx_tape_tape_started && zx_fifo_get_free(&zx_tape_fifo) > 0)
    {
        if (header_size > 0)
        {
            zx_fifo_write_byte(&zx_tape_fifo, header[header_pos++]);
            header_size--;
            continue;
        }

        if (data_size > 0)
        {
            uint8_t data;
            UINT res;
            f_read(&tape_file, &data, 1, &res);

            if (res == 1)
            {
                zx_fifo_write_byte(&zx_tape_fifo, data);
                data_size--;
                continue;
            }
            else
            {
                zx_tape_tape_started = false;
                break;
            }
        }

        if (tape_file.fptr >= f_size(&tape_file))
        {
            zx_tape_tape_finished = true;
            break;
        }

        UINT res;
        f_read(&tape_file, header, 1, &res);
        if( res != 1 )
        {
            zx_tape_tape_finished = true;
            break;
        }

        uint8_t hs = zx_tape_get_header_size(header[0]);
        f_read(&tape_file, header + 1, hs - 1, &res);
        if( res + 1 != hs )
        {
            zx_tape_tape_finished = true;
            break;
        }

        zx_tape_block_Struct temp_block;
        zx_tape_block_parse_header(header, &temp_block);

        if (temp_block.tape_pilot > 0 || temp_block.tape_sync > 0 || temp_block.tape_pause > 0 || (temp_block.data_size > 0 && temp_block.data_type != ZX_TAPE_SKIP_DATA))
        {
            header_pos = 0;
            header_size = hs;
            data_size = temp_block.data_size;
        }
        else if( header[ 0 ] == 0x24 )
        {
            if (loops_size < ZX_TAPE_LOOPS_SIZE)
            {
                loops[loops_size].fptr = tape_file.fptr;
                loops[loops_size].counter = zx_tape_read_word(header + 1);
                loops_size++;
            }
        }
        else if( header[ 0 ] == 0x25 )
        {
            if (loops_size > 0)
            {
                if (loops[loops_size - 1].counter > 0) loops[loops_size - 1].counter--;

                if (loops[loops_size - 1].counter > 0 ) f_lseek(&tape_file, loops[loops_size - 1].fptr);
                else loops_size--;
            }
        }
        else
        {
            f_lseek(&tape_file, tape_file.fptr + temp_block.data_size);
        }
    }

    while (zx_tape_tape_started && zx_tape_fifo_full() == false)
    {
        if (zx_tape_fill_buffer() == false)
        {
            break;
        }
    }
}

static bool zx_tape_fifo_full()
{
    zx_tape_fifo_reg_read(&zx_tape_fifo_reg);
    return (zx_tape_fifo_reg.bits.fifo_full == 1);
}

static void zx_tape_send(uint16_t pulseLength, bool pulse)
{
    pulseLength &= 0x7fff;
    if (pulse)
    {
       pulseLength |= 0x8000;
    }
    zx_tape_fifo_reg.bits.fifo_data = pulseLength;
    zx_tape_fifo_reg_write(&zx_tape_fifo_reg);
}

static bool zx_tape_fill_buffer()
{
    bool result = false;

    static uint8_t tape_header[0x20];
    static uint8_t tape_header_pos = 0;
    static uint8_t tape_header_size = 2;

    static uint8_t tape_bit = 0;
    static uint8_t tape_byte = 0;

    if (!zx_tape_current_block.tape_pilot && !zx_tape_current_block.tape_sync && !zx_tape_current_block.tape_pause && !zx_tape_current_block.data_size)
    {
        while (zx_fifo_get_cntr(&zx_tape_fifo) > 0 && (tape_header_pos == 0 || tape_header_pos < tape_header_size))
        {
            tape_header[tape_header_pos++] = zx_fifo_read_byte(&zx_tape_fifo);
            if (tape_header_pos == 1) tape_header_size = zx_tape_get_header_size(tape_header[0]);
        }

        if (tape_header_size != 0 && tape_header_pos == tape_header_size)
        {
            zx_tape_block_parse_header(tape_header, &zx_tape_current_block);
            tape_bit = 0;
            tape_header_pos = 0;
            tape_header_size = 0;
        }
        else
        {
            if (zx_tape_tape_finished)
            {
                zx_tape_tape_finished = false;
                zx_tape_tape_started = false;
            }
        }
    }

    if (zx_tape_current_block.tape_pilot > 0)
    {
        zx_tape_send(zx_tape_current_block.pulse_pilot, true);
        zx_tape_current_block.tape_pilot--;
        result = true;
    }
    else if (zx_tape_current_block.tape_sync >= 2)
    {
        zx_tape_send(zx_tape_current_block.pulse_sync1, true);
        zx_tape_current_block.tape_sync--;
        result = true;
    }
    else if (zx_tape_current_block.tape_sync == 1)
    {
        zx_tape_send(zx_tape_current_block.pulse_sync2, true);
        zx_tape_current_block.tape_sync--;
        result = true;
    }
    else if (zx_tape_current_block.data_size > 0)
    {
        if (zx_tape_current_block.data_type == ZX_TAPE_BLOCK_DATA)
        {
            if (tape_bit == 0)
            {
                if (zx_fifo_get_cntr(&zx_tape_fifo) > 0)
                {
                    tape_byte = zx_fifo_read_byte(&zx_tape_fifo);
                    tape_bit = 16;
                }
            }

            if (tape_bit != 0)
            {
                if ((tape_byte & 0x80) != 0) zx_tape_send(zx_tape_current_block.pulse_one, true);
                else zx_tape_send(zx_tape_current_block.pulse_zero, true);

                if ( tape_bit & 1 ) tape_byte <<= 1;
                tape_bit--;

                if (tape_bit == 0) zx_tape_current_block.data_size--;
                else if (zx_tape_current_block.data_size == 1 && tape_bit == zx_tape_current_block.block_lastbit)
                {
                    zx_tape_current_block.data_size = 0;
                    tape_bit = 0;
                }
                result = true;
            }
        }
        else if (zx_tape_current_block.data_type == ZX_TAPE_SEQUENCE_DATA)
        {
            if (zx_fifo_get_cntr(&zx_tape_fifo) >= 2)
            {
                uint16_t next;
                zx_filo_read_file(&zx_tape_fifo, (uint8_t*)&next, 2);
                zx_tape_send(zx_tape_convert(next), true);
                zx_tape_current_block.data_size -= 2;
                result = true;
            }
        }
        else
        {
            while (zx_fifo_get_cntr(&zx_tape_fifo) > 0  && zx_tape_current_block.data_size > 0)
            {
                zx_fifo_read_byte(&zx_tape_fifo);
                zx_tape_current_block.data_size--;
            }
        }
    }
    else if (zx_tape_current_block.tape_pause > 0)
    {
        zx_tape_send(3500, false);
        zx_tape_current_block.tape_pause--;
        result = true;
    }
    return result;
}

