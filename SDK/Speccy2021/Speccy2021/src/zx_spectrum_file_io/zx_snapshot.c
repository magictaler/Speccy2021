/*
 SNA file loader
 ===============

 This logic allows for loading shapshot files in SNA format

 Originally designed by SYD as part of Speccy2010 project

 Code cleanup and documenting by Dmitry Pakhomenko (Magictale Electronics) in 2021
*/

#include "zx_snapshot.h"
#include "zx_loader.h"

#define ZX_SNAPSHOT_INIT_DATA_LENGTH (0x1B)
#define ZX_SNAPSHOT_48K_SIZE (0xC01B)
#define ZX_SNAPSHOT_TOTAL_PAGES (8)
#define ZX_SNAPSHOT_OPCODE_RET (0xC9)
#define ZX_SNAPSHOT_HEADER_LOADER_OFFSET (0x40)

static reg_ZX_Spectrum_io_ports_Struct zx_io_ports;
static reg_ZX_Spectrum_cpu_control_Struct zx_cpu_control;

bool zx_cpu_stopped()
{
    return (zx_cpu_control.bits.cpu_halt_req == 1);
}

void zx_cpu_stop()
{
    zx_cpu_control.bits.cpu_halt_req = 1;
    zx_spectrum_control_reg_write(&zx_cpu_control);
}

void zx_cpu_reset(bool reset)
{
    if (reset == false)
    {
        // TODO: configure the ports
        //zx_io_ports.bits.zx_port_7ffd = 0x30; // hardcoded for Spectrum 48
        zx_io_ports.bits.zx_port_7ffd = 0x0;
        zx_io_ports.bits.zx_port_1ffd = 0x0;
        zx_spectrum_io_ports_reg_write(&zx_io_ports);
    }

    if (!zx_cpu_stopped())
    {
        zx_cpu_control.bits.cpu_reset = reset;
    }

    zx_cpu_control.bits.trdos_flag = 0; // hardcoded for now
    zx_cpu_control.bits.cpu_restore_pc_n = 1;
    zx_spectrum_control_reg_write(&zx_cpu_control);

}

void zx_cpu_start()
{
    zx_cpu_control.bits.cpu_halt_req = 0;
    zx_cpu_control.bits.cpu_trace_req = 0; //revisit this
    zx_spectrum_control_reg_write(&zx_cpu_control);
}

static void zx_cpu_modify_pc(uint16_t pc, uint8_t istate)
{
    zx_cpu_stop();

    zx_cpu_control.bits.cpu_pc = pc;
    zx_cpu_control.bits.cpu_int = istate;
    zx_cpu_control.bits.cpu_reset = 0;
    zx_cpu_control.bits.magic_button = 0;
    zx_cpu_control.bits.cpu_one_cycle_wait_req = 0;
    zx_cpu_control.bits.cpu_restore_pc_n = 1;
    zx_spectrum_control_reg_write(&zx_cpu_control);
    vTaskDelay(10);

    zx_cpu_control.bits.cpu_restore_pc_n = 0;
    zx_spectrum_control_reg_write(&zx_cpu_control);
    vTaskDelay(10);

    zx_cpu_control.bits.cpu_restore_pc_n = 1;
    zx_spectrum_control_reg_write(&zx_cpu_control);

    zx_cpu_start();
}

static void zx_snapshot_load_page(FIL *file, uint8_t page)
{
    uint32_t addr = (EMULATOR_MEMORY_AREA_START | ((page + EMULATOR_ROM_PAGES_COUNT) << EMULATOR_PAGE_LEFT_SHIFT_BITS));

    uint8_t data;
    UINT res;

    uint8_t* emulator_memory_area = (uint8_t*)addr;

    for (int i = 0; i < EMULATOR_PAGE_SIZE; i++)
    {
        if (f_read(file, &data, 1, &res) != FR_OK) break;
        if (res == 0) break;

        *emulator_memory_area = data;
        emulator_memory_area++;
    }

    Xil_DCacheFlushRange(addr, EMULATOR_PAGE_SIZE);
}

bool zx_snapshot_load(const char *file_name)
{
    bool result = false;

    bool stopped = zx_cpu_stopped();
    if (!stopped)
    {
        zx_cpu_stop();
    }

    zx_spectrum_io_ports_reg_read(&zx_io_ports);
    uint16_t spec_pc = 0;

    FIL sna_file;
    if (f_open(&sna_file, file_name, FA_READ ) == FR_OK)
    {
        if (f_size(&sna_file) >= ZX_SNAPSHOT_48K_SIZE)
        {
            zx_cpu_start();
            zx_cpu_reset(false);
            vTaskDelay(10);
            zx_cpu_reset(true);
            zx_cpu_stop();

            uint32_t addr;
            uint16_t i;

            uint8_t header[0x1c];

            UINT res;
            f_lseek(&sna_file, 0);
            f_read(&sna_file, header, ZX_SNAPSHOT_INIT_DATA_LENGTH, &res);

            zx_io_ports.bits.zx_port_fe = header[26] & 0x07;

            if (f_size(&sna_file) == ZX_SNAPSHOT_48K_SIZE)
            {
                zx_io_ports.bits.zx_port_7ffd = ( 1 << 4 ) | ( 1 << 5 );// -- 48K mode
                zx_cpu_control.bits.trdos_flag = 0;
            }
            else
            {
                uint8_t header2[4];
                f_lseek(&sna_file, ZX_SNAPSHOT_INIT_DATA_LENGTH + EMULATOR_THREE_PAGE_SIZE);
                f_read(&sna_file, header2, 0x04, &res);

                spec_pc = header2[0] | ( header2[1] << 8 );
                zx_io_ports.bits.zx_port_7ffd = header2[2];
                zx_cpu_control.bits.trdos_flag = header2[3];
            }
            zx_spectrum_control_reg_write(&zx_cpu_control);
            zx_spectrum_io_ports_reg_write(&zx_io_ports);

            // Copy SNA header into page 2
            addr = EMULATOR_MEMORY_AREA_START | ((EMULATOR_PAGE_2 + EMULATOR_ROM_PAGES_COUNT) << EMULATOR_PAGE_LEFT_SHIFT_BITS);
            uint8_t* emulator_memory_area = (uint8_t*)addr;
            for (i = 0; i < ZX_SNAPSHOT_INIT_DATA_LENGTH; i++)
            {
                *emulator_memory_area = header[i];
                emulator_memory_area++;
            }
            Xil_DCacheFlushRange(addr, ZX_SNAPSHOT_INIT_DATA_LENGTH);

            // Now copy the loader which will initialise CPU registers from the header and then will simply spin in infinite loop until we stop it
            addr = EMULATOR_MEMORY_AREA_START | ((EMULATOR_PAGE_2 + EMULATOR_ROM_PAGES_COUNT) << EMULATOR_PAGE_LEFT_SHIFT_BITS) | ZX_SNAPSHOT_HEADER_LOADER_OFFSET;
            emulator_memory_area = (uint8_t*)addr;
            for (i = 0; i < zx_loader_size; i++)
            {
                *emulator_memory_area = zx_loader[i];
                emulator_memory_area++;
            }
            Xil_DCacheFlushRange(addr, zx_loader_size);

            zx_cpu_modify_pc(addr, 0);
            //zx_cpu_start();
            vTaskDelay(10);
            zx_cpu_stop();

            f_lseek(&sna_file, ZX_SNAPSHOT_INIT_DATA_LENGTH);

            zx_snapshot_load_page(&sna_file, 0x05);
            zx_snapshot_load_page(&sna_file, 0x02);
            zx_snapshot_load_page(&sna_file, zx_io_ports.bits.zx_port_7ffd & 0x07);

            f_lseek(&sna_file, ZX_SNAPSHOT_INIT_DATA_LENGTH + EMULATOR_THREE_PAGE_SIZE + 0x04);

            for (uint8_t page = 0; page < ZX_SNAPSHOT_TOTAL_PAGES; page++)
            {
                if (page != 0x05 && page != 0x02 && page != (zx_io_ports.bits.zx_port_7ffd & 0x07))
                {
                    zx_snapshot_load_page(&sna_file, page);
                }
            }

            zx_spectrum_io_ports_reg_write(&zx_io_ports);

            if (f_size(&sna_file) == ZX_SNAPSHOT_48K_SIZE)
            {
                uint8_t rom_page = 0;
                if ((zx_io_ports.bits.zx_port_7ffd & 0x10) != 0) rom_page |= 0x01;

                // TODO: uncomment when full emulation of Beta Disk Interface is added
                //if (zx_cpu_control.bits.trdos_flag == 0) rom_page |= 0x02;

                // This piece of logic is extraordinary - the program counter is not
                // saved in SNA files, instead, its value is in stack. So once
                // the stack is initialised PC needs to be pushed out of it and
                // this can be done by executing RET (0xC9) opcode. At this moment there
                // is no place in RAM anymore because we have just restored the full
                // snapshot so we simply look for this opcode in ROM and then jump
                // to that address.
                addr = EMULATOR_MEMORY_AREA_START + rom_page * EMULATOR_PAGE_SIZE;
                emulator_memory_area = (uint8_t*)addr;
                for (i = 0; i < EMULATOR_PAGE_SIZE; i++)
                {
                    uint8_t data = *emulator_memory_area;
                    if (data == ZX_SNAPSHOT_OPCODE_RET)
                    {
                        spec_pc = i;
                        break;
                    }
                    emulator_memory_area++;
                }
            }

            zx_cpu_modify_pc(spec_pc, (header[25] & 0x03) | 0x08 | (header[19] & 0x04));
            result = true;
        }
    }

    if (!zx_cpu_stopped())
    {
        zx_cpu_start();
    }
    return result;
}

