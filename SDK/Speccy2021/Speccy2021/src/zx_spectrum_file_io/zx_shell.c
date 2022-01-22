/*
 ZX Shell
 ========

 A shell to provide with basic navigation through the files and folders on SD card.
 The shell uses its own video page and functions separately from the ZX machine.

 Originally designed by SYD as part of Speccy2010 project

 Code cleanup and documenting by Dmitry Pakhomenko (Magictale Electronics) in 2021
*/


#include "zx_shell.h"

#include "../zx_spectrum_video/zx_font1.h"
#include "../zx_spectrum_video/zx_font2.h"
#include "../zx_spectrum_video/zx_font3.h"


#define ZX_SHELL_BYTES_PER_CHAR (8)
#define ZX_SHELL_H_PIXELS_PER_CHAR (8)
#define ZX_SHELL_TOTAL_CHAR_COLUMNS (32)
#define ZX_SHELL_TOTAL_CHAR_ROWS (24)

#define ZX_SHELL_FILES_PER_ROW (18)
#define ZX_SHELL_FILES_PER_COLUMN (2)
#define ZX_SHELL_PATH_SIZE (0x80)
#define ZX_SHELL_FILES_PER_DIR (10000U)

typedef struct
{
    uint32_t size;
    uint8_t attr;
    uint8_t sel;
    uint16_t date;
    uint16_t time;
    char name[FF_MAX_LFN + 1];
} zx_shell_file_record_Struct;

static const uint8_t* zx_shell_char_table[ZX_FONT_LAST_ENTRY] = {zx_font1, zx_font2, zx_font3};
static zx_font_Enum zx_shell_current_font = ZX_FONT1;
static bool zx_shell_active = false;
static zx_shell_file_record_Struct zx_shell_files[ZX_SHELL_FILES_PER_DIR];
static int zx_shell_sel_files;
static int zx_shell_sel_file_number = 0;
static char zx_shell_path[ZX_SHELL_PATH_SIZE] = "";
static zx_shell_file_record_Struct* zx_shell_p_curr_record;
static int zx_shell_total_files = 0;
static bool zx_shell_too_many_files;
static uint32_t zx_shell_file_table_start;
static char zx_shell_file_last_name[FF_MAX_LFN + 1] = "";
static uint8_t selx = 0, sely = 0;

//! @brief Clear screen and fill it with a given color attribute
//! @param attr is the color attribure to fill with
static void zx_shell_clr_scr(uint8_t attr);

//! @brief Init the shell by activating a dedicated video page and activating shell browser
//! @param frame is the logical video page number to switch to
//! @return true if successully switched to a desired page or false otherwise
static bool zx_shell_init(uint32_t frame);

//! @brief Draw a character of a specified font at a specified location
//! @param x is the horizontal position
//! @param y is the vertical position
//! @param c is a character to be drawn
//! @param font_idx is a font index
static void zx_shell_write_char(uint8_t x, uint8_t y, char c, zx_font_Enum font_idx);

//! @brief Draw a horizontal line across the full width of the screen
//! @param y is the vertical position in characters
//! @param cy is the vertical offset within the character
static void zx_shell_write_line(uint8_t y, uint8_t cy);

//! @brief Write a number of color attributes starting from a specified location
//! @param x is the starting horizontal position
//! @param y is the starting vertical position
//! @param attr is an attribute to be written
//! @param n is the number of attributes to be consecutevely written
static void zx_shell_write_attr(uint8_t x, uint8_t y, uint8_t attr, uint8_t n);

//! @brief Draw a text string at a specified location
//! @param x is the horizontal position
//! @param y is the vertical position
//! @param *str is a pointer to a null terminated string to be drawn
//! @param size is the number of characters to be drawn
static void zx_shell_write_str(uint8_t x, uint8_t y, const char *str, size_t size);

//! @brief Draw a text string with a specified color attribute at a specified location
//! @param x is the horizontal position
//! @param y is the vertical position
//! @param *str is a pointer to a null terminated string to be drawn
//! @param attr is a color attribute for every character in the string
//! @param size is the number of characters to be drawn
static void zx_shell_write_str_attr(uint8_t x, uint8_t y, const char *str, uint8_t attr, uint8_t size);

//! @brief Low level function which manipulates file entries in two lists. Used for sorting
//! @param *p_fr is the destination
//! @param *p_file_table is the source
//! @param pos is the number of elements by which *p_file_table gets incremented 
static bool zx_shell_read(zx_shell_file_record_Struct* p_fr, zx_shell_file_record_Struct* p_file_table, uint32_t pos);

//! @brief Low level function which manipulates file entries in two lists. Used for sorting
//! @param *p_fr is the source
//! @param *p_file_table is the destination
//! @param pos is the number of elements by which *p_file_table gets incremented 
static bool zx_shell_write(zx_shell_file_record_Struct* p_fr, zx_shell_file_record_Struct* p_file_table, uint32_t pos);

//! @brief Read the current folder and fill the shell panel with list of files
static void zx_shell_read_dir(void);

//! @brief A top level function which initialises the shell, reads the current folder and
//!   highlights currently selected file
static void zx_shell_browser(void);


static bool zx_shell_read(zx_shell_file_record_Struct* p_fr, zx_shell_file_record_Struct* p_file_table, uint32_t pos)
{
    if (p_file_table == 0)
    {
        return false;
    }

    if (pos >= ZX_SHELL_FILES_PER_DIR)
    {
        return false;
    }

    p_file_table += pos;

    memcpy(p_fr, p_file_table, sizeof(zx_shell_files[0]));
    return true;
}

static bool zx_shell_write(zx_shell_file_record_Struct* p_fr, zx_shell_file_record_Struct* p_file_table, uint32_t pos)
{
    if (p_file_table == 0)
    {
        return false;
    }

    if (pos >= ZX_SHELL_FILES_PER_DIR)
    {
        return false;
    }

    p_file_table += pos;

    memcpy(p_file_table, p_fr, sizeof(zx_shell_files[0]));
    return true;
}

static void zx_shell_cycle_mark()
{
    const char marks[4] = {'/', '-', '\\', '|'};
    static int mark = 0;

    zx_shell_write_char(0, ZX_SHELL_FILES_PER_ROW + 4, marks[mark], zx_shell_current_font);
    mark = (mark + 1) & 3;
}

uint8_t zx_shell_comp_name(int a, int b)
{
    zx_shell_file_record_Struct ra, rb;
    zx_shell_read(&ra, zx_shell_files, a);
    zx_shell_read(&rb, zx_shell_files, b);

    strlwr(ra.name);
    strlwr(rb.name);

    if ((ra.attr & AM_DIR) && !(rb.attr & AM_DIR)) return true;
    else if (!(ra.attr & AM_DIR) && (rb.attr & AM_DIR)) return false;
    else return strcmp(ra.name, rb.name) <= 0;
}

void zx_shell_swap_name(int a, int b)
{
    zx_shell_file_record_Struct ra, rb;
    zx_shell_read(&ra, zx_shell_files, a);
    zx_shell_read(&rb, zx_shell_files, b);

    zx_shell_write(&ra, zx_shell_files, b);
    zx_shell_write(&rb, zx_shell_files, a);
}

void zx_shell_qsort(int l, int h)
{
    int i = l;
    int j = h;
    int k = (l + h) / 2;

    while (true)
    {
        while (i < k && zx_shell_comp_name(i, k)) i++;
        while (j > k && zx_shell_comp_name(k, j)) j--;

        if (i == j) break;
        zx_shell_swap_name(i, j);

        if (i == k) k = j;
        else if (j == k) k = i;
    }

    if (l < k - 1) zx_shell_qsort(l, k - 1);
    if (k + 1 < h) zx_shell_qsort(k + 1, h);
}

static void zx_shell_read_dir()
{
    zx_shell_total_files = 0;
    zx_shell_too_many_files = false;
    zx_shell_file_table_start = 0;
    zx_shell_p_curr_record = &zx_shell_files[0];
    zx_shell_sel_files = 0;
    zx_shell_sel_file_number = 0;

    zx_shell_file_record_Struct fr;

    if (strlen(zx_shell_path) != 0)
    {
        fr.attr = AM_DIR;
        fr.sel = 0;
        fr.size = 0;
        strcpy(fr.name, "..");
        zx_shell_write(&fr, zx_shell_p_curr_record, zx_shell_total_files++);
    }

    DIR dir;
    FRESULT r;

    int path_size = strlen(zx_shell_path);
    if (path_size > 0) zx_shell_path[path_size - 1] = 0;

    r = f_opendir(&dir, zx_shell_path);
    if (path_size > 0)
    {
        zx_shell_path[path_size - 1] = '/';
    }

    while (r == FR_OK)
    {
        FILINFO fi;
        r = f_readdir(&dir, &fi);

        if (r != FR_OK || fi.fname[0] == 0) break;
        if (fi.fattrib & ( AM_HID | AM_SYS )) continue;

        if (zx_shell_total_files >= ZX_SHELL_FILES_PER_DIR)
        {
            zx_shell_too_many_files = true;

            if (strlen(zx_shell_path) != 0) zx_shell_total_files = 1;
            else zx_shell_total_files = 0;

            break;
        }

        fr.sel = 0;
        fr.attr = fi.fattrib;
        fr.size = fi.fsize;
        fr.date = fi.fdate;
        fr.time = fi.ftime;
        strcpy(fr.name , fi.fname);

        zx_shell_write(&fr, zx_shell_p_curr_record, zx_shell_total_files);
        zx_shell_total_files++;
        if ((zx_shell_total_files & 0x3f) == 0) zx_shell_cycle_mark();
    }

    if (zx_shell_total_files > 0 && zx_shell_total_files < 0x100) zx_shell_qsort(0, zx_shell_total_files - 1);

    if (strlen(zx_shell_file_last_name) != 0)
    {
        zx_shell_file_record_Struct fr;
        for (int i = 0; i < zx_shell_total_files; i++)
        {
            zx_shell_read(&fr, zx_shell_files, i);
            if (strcmp(fr.name, zx_shell_file_last_name) == 0)
            {
                zx_shell_sel_files = i;
                break;
            }
        }
    }
}

static void zx_shell_clr_scr(uint8_t attr)
{
    uint8_t* shell_vram_address = zx_spectrum_shell_vpage_address(ZX_SHELL_DEFAULT_PAGE);
    if (shell_vram_address != NULL)
    {
        int i = 0;
        for (; i < ZX_PIXEL_DATA_REGION_SIZE; i++)
        {
            *shell_vram_address = 0;
            shell_vram_address++;
        }

        for (; i < ZX_SPECTRUM_VRAM_SIZE; i++)
        {
           *shell_vram_address = attr;
           shell_vram_address++;
        }
    }
}

static bool zx_shell_init(uint32_t frame)
{
    bool result;
    result = zx_spectrum_activate_shell_vpage(frame);

    if (result == true)
    {
        zx_border_color_set(0);
        zx_shell_clr_scr(0x07);

        char str[33];
        sniprintf(str, sizeof(str), " -= Speccy2021, v%d.%.2d, r%.4d =-\n", version_get_major(), version_get_minor(), version_get_rev());

        zx_shell_write_str(0, 0, str, 0);
        zx_shell_write_attr(0, 0, 0x44, strlen(str));

        zx_shell_write_attr(0, 1, 0x06, 32);
        zx_shell_write_line(1, 3);
        zx_shell_write_line(1, 5);

        zx_shell_write_attr(0, ZX_SHELL_FILES_PER_ROW + 2, 0x06, 32);
        zx_shell_write_line(ZX_SHELL_FILES_PER_ROW + 2, 3);
        zx_shell_write_line(ZX_SHELL_FILES_PER_ROW + 2, 5);
    }

    return result;
}

static void zx_shell_write_char(uint8_t x, uint8_t y, char c, zx_font_Enum font_idx)
{
    if (x < ZX_SHELL_TOTAL_CHAR_COLUMNS && y < ZX_SHELL_TOTAL_CHAR_ROWS)
    {
        uint8_t* shell_vram_address = zx_spectrum_shell_vpage_address(ZX_SHELL_DEFAULT_PAGE);
        shell_vram_address += x + (y & 0x07) * ZX_SHELL_TOTAL_CHAR_COLUMNS + (y & 0x18) * ZX_SHELL_TOTAL_CHAR_COLUMNS * ZX_SHELL_H_PIXELS_PER_CHAR;
        const uint8_t *table_pos = &zx_shell_char_table[font_idx][(uint8_t)c * ZX_SHELL_BYTES_PER_CHAR];

        for (uint8_t i = 0; i < ZX_SHELL_BYTES_PER_CHAR; i++)
        {
             *shell_vram_address = *table_pos++;
             shell_vram_address += ZX_SHELL_TOTAL_CHAR_COLUMNS * ZX_SHELL_H_PIXELS_PER_CHAR;
        }
    }
}

static void zx_shell_write_line(uint8_t y, uint8_t cy)
{
    y = y * ZX_SHELL_H_PIXELS_PER_CHAR + cy;

    if (y < ZX_SHELL_TOTAL_CHAR_ROWS * ZX_SHELL_H_PIXELS_PER_CHAR)
    {
        uint8_t* shell_vram_address = zx_spectrum_shell_vpage_address(ZX_SHELL_DEFAULT_PAGE);
        shell_vram_address += ((y & 0xc0) | ((y & 0x38) >> 3) | ((y & 0x07) << 3)) << 5;
        for (uint8_t i = 0; i < ZX_SHELL_TOTAL_CHAR_COLUMNS; i++ )
        {
            *shell_vram_address = 0xFF;
            shell_vram_address++;
        }
    }
}

static void zx_shell_write_attr(uint8_t x, uint8_t y, uint8_t attr, uint8_t n)
{
    if (x < ZX_SHELL_TOTAL_CHAR_COLUMNS && y < ZX_SHELL_TOTAL_CHAR_ROWS)
    {
        uint8_t* shell_vram_address = zx_spectrum_shell_vpage_address(ZX_SHELL_DEFAULT_PAGE);
        shell_vram_address += ZX_PIXEL_DATA_REGION_SIZE + x + y * ZX_SHELL_TOTAL_CHAR_COLUMNS;
        while (n--)
        {
            *shell_vram_address = attr;
            shell_vram_address++;
        }
    }
}

static void zx_shell_write_str(uint8_t x, uint8_t y, const char *str, size_t size)
{
    if (size == 0)
    {
        size = strlen(str);
    }

    while (size > 0)
    {
        if (*str)
        {
            zx_shell_write_char(x++, y, *str++, zx_shell_current_font);
        }
        else
        {
            zx_shell_write_char(x++, y, ' ', zx_shell_current_font);
        }
        size--;
    }
}

static void zx_shell_write_str_attr(uint8_t x, uint8_t y, const char *str, uint8_t attr, uint8_t size)
{
    if (size == 0)
    {
        size = strlen(str);
    }

    zx_shell_write_str(x, y, str, size);
    zx_shell_write_attr(x, y, attr, size);
}

uint8_t zx_shell_get_sel_attr(zx_shell_file_record_Struct* fr)
{
    uint8_t result = 007;

    if ((fr->attr & AM_DIR) == 0)
    {
        strlwr(fr->name);

        char *ext = fr->name + strlen(fr->name);
        while (ext > fr->name && *ext != '.')
        {
            ext--;
        }

        if ( strcmp( ext, ".trd" ) == 0 || strcmp( ext, ".fdi" ) == 0 || strcmp( ext, ".scl" ) == 0 ) result = 006;
        else if ( strcmp( ext, ".tap" ) == 0 || strcmp( ext, ".tzx" ) == 0 ) result = 004;
        else if ( strcmp( ext, ".sna" ) == 0 ) result = 0103;
        else if ( strcmp( ext, ".scr" ) == 0 ) result = 0102;
        else result = 005;
    }

    if (fr->sel) result = (result & 077) | 010;

    return result;
}

void zx_shell_make_short_name(char *sname, uint16_t size, const char* name)
{
    uint16_t n_size = strlen(name);

    if (n_size + 1 <= size)
    {
       strcpy(sname, name);
    }
    else
    {
        uint16_t size_a = (size - 2) / 2;
        uint16_t size_b = (size - 1) - (size_a + 1);

        memcpy(sname, name, size_a);
        sname[size_a] = '~';
        memcpy(sname + size_a + 1, name + n_size - size_b, size_b + 1);
    }
}

void zx_shell_display_path(char *str, int col, int row, uint8_t max_sz)
{
    char path_buff[ 33 ] = "/";
    char *path_short = str;

    if (strlen(str) > max_sz)
    {
        while (strlen(path_short) + 2 > max_sz)
        {
            path_short++;
            while (*path_short != '/') path_short++;
        }

        strcpy(path_buff, "...");
    }

    strcat(path_buff, path_short);
    zx_shell_write_str(col, row, path_buff, max_sz);
}

void zx_shell_show_table()
{
    zx_shell_display_path(zx_shell_path, 0, ZX_SHELL_FILES_PER_ROW + 3, 32);

    zx_shell_file_record_Struct fr;

    for (int i = 0; i < ZX_SHELL_FILES_PER_ROW; i++)
    {
        for (int j = 0; j < 2; j++)
        {
            int col = j * 16;
            int row = i + 2;
            int pos = i + j * ZX_SHELL_FILES_PER_ROW + zx_shell_file_table_start;

            zx_shell_read(&fr, zx_shell_files, pos);

            char sname[16];
            zx_shell_make_short_name(sname, sizeof( sname ), fr.name);

            if (pos < zx_shell_total_files)
            {
                zx_shell_write_attr(col, row, zx_shell_get_sel_attr(&fr), 16);

                if (fr.sel) zx_shell_write_char(col, row, 0x95, zx_shell_current_font);
                else zx_shell_write_char(col, row, ' ', zx_shell_current_font);

                zx_shell_write_str(col + 1, row, sname, 15);
            }
            else
            {
                zx_shell_write_attr(col, row, 0, 16);
                zx_shell_write_str(col, row, "", 16);
            }
        }
    }

    if (zx_shell_too_many_files)
    {
        zx_shell_write_str(3, 5, "too many files (>9999) !", 0);
        zx_shell_write_attr(3, 5, 0102, 24);
    }
    else if (zx_shell_total_files == 0)
    {
        zx_shell_write_str(10, 5, "no files !", 0);
        zx_shell_write_attr(10, 5, 0102, 10);
    }
}

bool zx_shell_calc_sel()
{
    if (zx_shell_total_files == 0) return false;

    if (zx_shell_sel_files >= zx_shell_total_files) zx_shell_sel_files = zx_shell_total_files - 1;
    else if (zx_shell_sel_files < 0) zx_shell_sel_files = 0;

    bool redraw = false;

    while (zx_shell_sel_files < zx_shell_file_table_start)
    {
        zx_shell_file_table_start -= ZX_SHELL_FILES_PER_ROW;
        redraw = true;
    }

    while (zx_shell_sel_files >= zx_shell_file_table_start + ZX_SHELL_FILES_PER_ROW * 2)
    {
        zx_shell_file_table_start += ZX_SHELL_FILES_PER_ROW;
        redraw = true;
    }

    selx = ((zx_shell_sel_files - zx_shell_file_table_start) / ZX_SHELL_FILES_PER_ROW);
    sely = ((zx_shell_sel_files - zx_shell_file_table_start) % ZX_SHELL_FILES_PER_ROW);

    return redraw;
}

void zx_shell_hide_sel()
{
    zx_shell_file_record_Struct fr;
    zx_shell_read(&fr, zx_shell_files, zx_shell_sel_files);

    if (zx_shell_total_files != 0)
    {
        zx_shell_write_attr(selx * 16, 2 + sely, zx_shell_get_sel_attr(&fr), 16);

        if (fr.sel) zx_shell_write_char(selx * 16, 2 + sely, 0x95, zx_shell_current_font);
        else zx_shell_write_char(selx * 16, 2 + sely, ' ', zx_shell_current_font);
    }

    zx_shell_write_str(0, ZX_SHELL_FILES_PER_ROW + 4, "", 32);
    zx_shell_write_str(0, ZX_SHELL_FILES_PER_ROW + 5, "", 32);
}

void zx_shell_show_sel(bool redraw)
{
    if (zx_shell_calc_sel() || redraw) zx_shell_show_table();

    if (zx_shell_total_files != 0)
    {
        zx_shell_file_record_Struct fr;
        zx_shell_read(&fr, zx_shell_files, zx_shell_sel_files);

        zx_shell_write_attr(selx * 16, 2 + sely, 071, 16);

        if (fr.sel) zx_shell_write_char(selx * 16, 2 + sely, 0x95, zx_shell_current_font);
        else zx_shell_write_char(selx * 16, 2 + sely, ' ', zx_shell_current_font);

        char sname[ZX_SHELL_PATH_SIZE];
        zx_shell_make_short_name(sname, 33, fr.name);
        zx_shell_write_str(0, ZX_SHELL_FILES_PER_ROW + 4, sname, 32);

        if (zx_shell_sel_file_number > 0)
        {
            sniprintf(sname, sizeof(sname), "selected %u item%s", zx_shell_sel_file_number, zx_shell_sel_file_number > 1 ? "s" : "");
            zx_shell_write_str(0, ZX_SHELL_FILES_PER_ROW + 5, sname, 32);
        }
        else
        {
            if (fr.date == 0)
            {
                zx_shell_write_str(0, ZX_SHELL_FILES_PER_ROW + 5, "", 15);
            }
            else
            {
                sniprintf(sname, sizeof(sname), "%.2u.%.2u.%.2u  %.2u:%.2u", fr.date & 0x1f,
                                                                            ( fr.date >> 5 ) & 0x0f,
                                                                            ( 80 + ( fr.date >> 9 ) ) % 100,
                                                                            (fr.time >> 11 ) & 0x1f,
                                                                            (fr.time >> 5 ) & 0x3f);
                zx_shell_write_str(0, ZX_SHELL_FILES_PER_ROW + 5, sname, 15);
            }

            if (( fr.attr & AM_DIR ) != 0) sniprintf(sname, sizeof(sname), "      Folder");
            else if(fr.size < 9999) sniprintf(sname, sizeof(sname), "%10lu B", fr.size);
            else if(fr.size < 0x100000) sniprintf(sname, sizeof(sname), "%6lu.%.2lu kB", fr.size >> 10, ((fr.size & 0x3ff) * 100) >> 10);
            else sniprintf(sname, sizeof(sname), "%6lu.%.2lu MB", fr.size >> 20, ((fr.size & 0xfffff) * 100) >> 20);

            zx_shell_write_str(20, ZX_SHELL_FILES_PER_ROW + 5, sname, 12);
        }
    }
}

static void zx_shell_browser()
{
    //zx_cpu_stop();
    zx_shell_init(ZX_SHELL_DEFAULT_PAGE);

    zx_shell_read_dir();
    zx_shell_show_sel(true);
}

void zx_shell_leave_dir()
{
    zx_shell_file_record_Struct fr;

    uint8_t i = strlen(zx_shell_path);
    char dir_name[FF_MAX_LFN + 1];

    if ( i != 0 )
    {
        i--;
        zx_shell_path[i] = 0;

        while (i != 0 && zx_shell_path[i - 1] != '/') i--;
        strcpy(dir_name, &zx_shell_path[i]);

        zx_shell_path[i] = 0;
        zx_shell_read_dir();

        for (zx_shell_sel_files = 0; zx_shell_sel_files < zx_shell_total_files; zx_shell_sel_files++)
        {
            zx_shell_read(&fr, zx_shell_files, zx_shell_sel_files);
            if (strcmp( fr.name, dir_name) == 0) break;
        }

        if ((zx_shell_file_table_start + ZX_SHELL_FILES_PER_ROW * 2 - 1 ) < zx_shell_sel_files)
        {
            zx_shell_file_table_start = zx_shell_sel_files;
        }

        selx = ((zx_shell_sel_files - zx_shell_file_table_start) / ZX_SHELL_FILES_PER_ROW);
        sely = ((zx_shell_sel_files - zx_shell_file_table_start) % ZX_SHELL_FILES_PER_ROW);

        zx_shell_show_table();
    }
}

bool zx_shell_active_get()
{
    return zx_shell_active;
}

bool zx_shell_hid_keycode_handle(uint8_t keycode)
{
    if (HID_KEY_F12 == keycode)
    {
        if (zx_shell_active == false)
        {
            zx_shell_browser();
        }
        else
        {
            zx_vdma_start_address_set(EMULATOR_MEMORY_AREA_START + EMULATOR_VDMA_AREA_OFFSET, 0);
        }
        zx_shell_active = !zx_shell_active;
    }
    else if (HID_KEY_ARROW_RIGHT == keycode && zx_shell_active == true)
    {
        zx_shell_hide_sel();
        zx_shell_sel_files += ZX_SHELL_FILES_PER_ROW;
        zx_shell_show_sel(false);
    }
    else if (HID_KEY_ARROW_LEFT == keycode && zx_shell_active == true)
    {
        zx_shell_hide_sel();
        zx_shell_sel_files -= ZX_SHELL_FILES_PER_ROW;
        zx_shell_show_sel(false);
    }
    else if (HID_KEY_ARROW_UP == keycode && zx_shell_active == true)
    {
        zx_shell_hide_sel();
        zx_shell_sel_files--;
        zx_shell_show_sel(false);
    }
    else if (HID_KEY_ARROW_DOWN == keycode && zx_shell_active == true)
    {
        zx_shell_hide_sel();
        zx_shell_sel_files++;
        zx_shell_show_sel(false);
    }
    else if ((HID_KEY_RETURN == keycode || (HID_KEY_ENTER == keycode)) && zx_shell_active == true)
    {
        zx_shell_file_record_Struct fr;
        zx_shell_read(&fr, zx_shell_files, zx_shell_sel_files);

        if ((fr.attr & AM_DIR) != 0)
        {
            zx_shell_hide_sel();

            if (strcmp(fr.name, "..") == 0)
            {
                zx_shell_leave_dir();
            }
            else if (strlen(zx_shell_path) + strlen(fr.name) + 1 < ZX_SHELL_PATH_SIZE)
            {
                strcpy(zx_shell_file_last_name, "");

                strcat(zx_shell_path, fr.name);
                strcat(zx_shell_path, "/");
                zx_shell_read_dir();

                selx = ((zx_shell_sel_files - zx_shell_file_table_start) / ZX_SHELL_FILES_PER_ROW);
                sely = ((zx_shell_sel_files - zx_shell_file_table_start) % ZX_SHELL_FILES_PER_ROW);

                zx_shell_show_table();
            }
            zx_shell_show_sel(false);
        }
        else
        {
            char full_name[ZX_SHELL_PATH_SIZE];
            sniprintf(full_name, sizeof(full_name), "%s%s", zx_shell_path, fr.name);

            // Switch the back to ZX video page
            zx_vdma_start_address_set(EMULATOR_MEMORY_AREA_START + EMULATOR_VDMA_AREA_OFFSET, 0);
            zx_shell_active = !zx_shell_active;

            strlwr(fr.name);

            char *ext = fr.name + strlen(fr.name);
            while (ext > fr.name && *ext != '.') ext--;

            if (strcmp(ext, ".tap") == 0 || strcmp(ext, ".tzx") == 0)
            {
                zx_tape_select_file(full_name);
            }
            else if (strcmp(ext, ".sna") == 0)
            {
                zx_snapshot_load(full_name);
            }
        }
    }
    return zx_shell_active;
}
