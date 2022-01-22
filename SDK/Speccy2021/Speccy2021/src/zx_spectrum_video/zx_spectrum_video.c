/*
 ZX Spectrum Video high level API
 ===================================================

 This API allows for high level ZX Spectrum Video 
 initialisation and switching between video pages

 Designed in Magictale Electronics.
 
 Copyright (c) 2021 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 
 This code is in the public domain.
*/

#include "zx_spectrum_video.h"
#include "../zynq_video/display_ctrl/display_ctrl.h"
#include "../zynq_misc/timer_ps/timer_ps.h"

#define SCU_TIMER_ID XPAR_SCUTIMER_DEVICE_ID
#define DYNCLK_BASEADDR XPAR_AXI_DYNCLK_0_BASEADDR
#define DISP_VTC_ID XPAR_VTC_0_DEVICE_ID
#define VID_VTC_IRPT_ID XPS_FPGA3_INT_ID
#define VID_GPIO_IRPT_ID XPS_FPGA4_INT_ID

// Display Driver structs
DisplayCtrl dispCtrl;

// Framebuffers for video data
static ZXFrameBufStruct zx_spectrum_frameBufs[DISPLAY_NUM_FRAMES];
uint8_t *pFrames[DISPLAY_NUM_FRAMES]; //array of pointers to the frame buffers

void zx_spectrum_video_init()
{
    int Status;

    // Initialize an array of pointers to the 3 frame buffers
    for (uint8_t frame_index = 0; frame_index < DISPLAY_NUM_FRAMES; frame_index++)
    {
        pFrames[frame_index] = zx_spectrum_frameBufs[frame_index].zx_spectrum_frameBuf;
    }

    // Initialize a timer used for a simple delay
    TimerInitialize(SCU_TIMER_ID);

    // Initialize the Display controller and start it
    Status = DisplayInitialize(&dispCtrl, DISP_VTC_ID, DYNCLK_BASEADDR, pFrames);
    if (Status != XST_SUCCESS)
    {
        xil_printf("Display Ctrl initialization failed during demo initialization%d\r\n", Status);
        return;
    }
    Status = DisplayStart(&dispCtrl);
    if (Status != XST_SUCCESS)
    {
        xil_printf("Couldn't start display during demo initialization%d\r\n", Status);
        return;
    }

    return;
}

bool zx_spectrum_activate_shell_vpage(uint32_t page)
{
    int result = XST_FAILURE;

    if (page < DISPLAY_NUM_FRAMES)
    {
        result = DisplayChangeFrame(&dispCtrl, page);
    }

    return result == XST_SUCCESS;
}

uint8_t* zx_spectrum_shell_vpage_address(uint32_t page)
{
    uint8_t* result = NULL;
    if (page < DISPLAY_NUM_FRAMES)
    {
        result = pFrames[page];
    }
    return result;
}
