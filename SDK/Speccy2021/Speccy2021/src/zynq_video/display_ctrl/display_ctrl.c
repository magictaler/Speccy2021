/************************************************************************/
/*                                                                      */
/*  display_ctrl.c    --    Digilent Display Controller Driver          */
/*                                                                      */
/*  Patched to work with ZX Spectrum Video Controller                   */
/*                                                                      */
/*  Copyright (c) 2021 Dmitry Pakhomenko.                               */
/*  dmitryp@magictale.com                                               */
/*  http://magictale.com                                                */
/*                                                                      */
/*  This code is in the public domain.                                  */
/*                                                                      */
/************************************************************************/
/*    Author: Sam Bobrowicz                                             */
/*    Copyright 2014, Digilent Inc.                                     */
/************************************************************************/
/*  Module Description:                                                 */
/*                                                                      */
/*        This module provides an easy to use API for controlling a     */
/*        Display attached to a Digilent system board via VGA or HDMI.  */
/*        run-time resolution setting and seamless framebuffer-swapping */
/*        for tear-free animation.                                      */
/*                                                                      */
/*        To use this driver, you must have a Xilinx Video Timing       */
/*        Controller core (vtc), Xilinx axi_vdma core, a Digilent       */
/*        axi_dynclk core, a Xilinx AXI Stream to Video core, and either*/
/*        a Digilent RGB2VGA or RGB2DVI core all present in your design.*/
/*        See the Video in or Display out reference projects for your   */
/*        system board to see how they need to be connected. Digilent   */
/*        reference projects and IP cores can be found at               */
/*        www.github.com/Digilent.                                      */
/*                                                                      */
/*        The following steps should be followed to use this driver:    */
/*        1) Create a DisplayCtrl object and pass a pointer to it to    */
/*           DisplayInitialize.                                         */
/*        2) Call DisplaySetMode to set the desired mode                */
/*        3) Call DisplayStart to begin outputting data to the display  */
/*        4) To create a seamless animation, draw the next image to a   */
/*           framebuffer currently not being displayed. Then call       */
/*           DisplayChangeFrame to begin displaying that frame.         */
/*           Repeat as needed, only ever modifying inactive frames.     */
/*        5) To change the resolution, call DisplaySetMode, followed by */
/*           DisplayStart again.                                        */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*       2/20/2014(SamB): Created                                       */
/*      11/25/2015(SamB): Changed from axi_dispctrl to Xilinx cores     */
/*                        Separated Clock functions into dynclk library */
/*                                                                      */
/************************************************************************/
/*
 * TODO: It would be nice to remove the need for users above this to access
 *       members of the DisplayCtrl struct manually. This can be done by
 *       implementing get/set functions for things like video mode, state,
 *       etc.
 */


/* ------------------------------------------------------------ */
/*                Include File Definitions                      */
/* ------------------------------------------------------------ */

/*
 * Uncomment for Debugging messages over UART
 */
//#define DEBUG

#include "display_ctrl.h"
#include "xdebug.h"
#include "xil_io.h"
#include "../../zx_spectrum_video/zx_spectrum_display_ctrl.h"

/* ------------------------------------------------------------ */
/*                Procedure Definitions                         */
/* ------------------------------------------------------------ */

/***    DisplayStop(DisplayCtrl *dispPtr)
**
**    Parameters:
**        dispPtr - Pointer to the initialized DisplayCtrl struct
**
**    Return Value: int
**        XST_SUCCESS if successful.
**        XST_DMA_ERROR if an error was detected on the DMA channel. The
**            Display is still successfully stopped, and the error is
**            cleared so that subsequent DisplayStart calls will be
**            successful. This typically indicates insufficient bandwidth
**            on the AXI Memory-Map Interconnect (VDMA<->DDR)
**
**    Description:
**        Halts output to the display
**
*/
int DisplayStop(DisplayCtrl *dispPtr)
{
    /*
     * If already stopped, do nothing
     */
    if (dispPtr->state == DISPLAY_STOPPED)
    {
        return XST_SUCCESS;
    }

    /*
     * Disable the disp_ctrl core, and wait for the current frame to finish (the core cannot stop
     * mid-frame)
     */
    XVtc_DisableGenerator(&dispPtr->vtc);

    /*
     * Stop the VDMA core
     */
    zx_vdma_enable_set(0);

    /*
     * Update Struct state
     */
    dispPtr->state = DISPLAY_STOPPED;

    //TODO: consider stopping the clock here, perhaps after a check to see if the VTC is finished

    //TODO: get errors from the VDMA and return non-success status if this is the case?

    return XST_SUCCESS;
}
/* ------------------------------------------------------------ */

/***    DisplayStart(DisplayCtrl *dispPtr)
**
**    Parameters:
**        dispPtr - Pointer to the initialized DisplayCtrl struct
**
**    Return Value: int
**        XST_SUCCESS if successful, XST_FAILURE otherwise
**
**    Errors:
**
**    Description:
**        Starts the display.
**
*/
int DisplayStart(DisplayCtrl *dispPtr)
{
    ClkConfig clkReg;
    ClkMode clkMode;
    XVtc_Timing vtcTiming;
    XVtc_SourceSelect SourceSelect;

    xdbg_printf(XDBG_DEBUG_GENERAL, "display start entered\n\r");
    /*
     * If already started, do nothing
     */
    if (dispPtr->state == DISPLAY_RUNNING)
    {
        return XST_SUCCESS;
    }

    /*
     * Calculate the PLL divider parameters based on the required pixel clock frequency
     */
    ClkFindParams(dispPtr->vMode.freq, &clkMode);

    /*
     * Store the obtained frequency to pxlFreq. It is possible that the PLL was not able to
     * exactly generate the desired pixel clock, so this may differ from vMode.freq.
     */
    dispPtr->pxlFreq = clkMode.freq;

    /*
     * Write to the PLL dynamic configuration registers to configure it with the calculated
     * parameters.
     */
    if (!ClkFindReg(&clkReg, &clkMode))
    {
        xdbg_printf(XDBG_DEBUG_GENERAL, "Error calculating CLK register values\n\r");
        return XST_FAILURE;
    }
    ClkWriteReg(&clkReg, dispPtr->dynClkAddr);

    /*
     * Enable the dynamically generated clock
    */
    ClkStop(dispPtr->dynClkAddr);
    ClkStart(dispPtr->dynClkAddr);

    /*
     * Configure the vtc core with the display mode timing parameters
     */
    vtcTiming.HActiveVideo = dispPtr->vMode.width;    /**< Horizontal Active Video Size */
    vtcTiming.HFrontPorch = dispPtr->vMode.hps - dispPtr->vMode.width;    /**< Horizontal Front Porch Size */
    vtcTiming.HSyncWidth = dispPtr->vMode.hpe - dispPtr->vMode.hps;        /**< Horizontal Sync Width */
    vtcTiming.HBackPorch = dispPtr->vMode.hmax - dispPtr->vMode.hpe + 1;        /**< Horizontal Back Porch Size */
    vtcTiming.HSyncPolarity = dispPtr->vMode.hpol;    /**< Horizontal Sync Polarity */
    vtcTiming.VActiveVideo = dispPtr->vMode.height;    /**< Vertical Active Video Size */
    vtcTiming.V0FrontPorch = dispPtr->vMode.vps - dispPtr->vMode.height;    /**< Vertical Front Porch Size */
    vtcTiming.V0SyncWidth = dispPtr->vMode.vpe - dispPtr->vMode.vps;    /**< Vertical Sync Width */
    vtcTiming.V0BackPorch = dispPtr->vMode.vmax - dispPtr->vMode.vpe + 1;;    /**< Horizontal Back Porch Size */
    vtcTiming.V1FrontPorch = dispPtr->vMode.vps - dispPtr->vMode.height;    /**< Vertical Front Porch Size */
    vtcTiming.V1SyncWidth = dispPtr->vMode.vpe - dispPtr->vMode.vps;    /**< Vertical Sync Width */
    vtcTiming.V1BackPorch = dispPtr->vMode.vmax - dispPtr->vMode.vpe + 1;;    /**< Horizontal Back Porch Size */
    vtcTiming.VSyncPolarity = dispPtr->vMode.vpol;    /**< Vertical Sync Polarity */
    vtcTiming.Interlaced = 0;        /**< Interlaced / Progressive video */


    /* Setup the VTC Source Select config structure. */
    /* 1=Generator registers are source */
    /* 0=Detector registers are source */
    memset((void *)&SourceSelect, 0, sizeof(SourceSelect));
    SourceSelect.VBlankPolSrc = 1;
    SourceSelect.VSyncPolSrc = 1;
    SourceSelect.HBlankPolSrc = 1;
    SourceSelect.HSyncPolSrc = 1;
    SourceSelect.ActiveVideoPolSrc = 1;
    SourceSelect.ActiveChromaPolSrc= 1;
    SourceSelect.VChromaSrc = 1;
    SourceSelect.VActiveSrc = 1;
    SourceSelect.VBackPorchSrc = 1;
    SourceSelect.VSyncSrc = 1;
    SourceSelect.VFrontPorchSrc = 1;
    SourceSelect.VTotalSrc = 1;
    SourceSelect.HActiveSrc = 1;
    SourceSelect.HBackPorchSrc = 1;
    SourceSelect.HSyncSrc = 1;
    SourceSelect.HFrontPorchSrc = 1;
    SourceSelect.HTotalSrc = 1;

    XVtc_SelfTest(&(dispPtr->vtc));

    XVtc_RegUpdateEnable(&(dispPtr->vtc));
    XVtc_SetGeneratorTiming(&(dispPtr->vtc), &vtcTiming);
    XVtc_SetSource(&(dispPtr->vtc), &SourceSelect);
    /*
     * Enable VTC core, releasing backpressure on VDMA
     */
    XVtc_EnableGenerator(&dispPtr->vtc);

    /*
     * Configure the VDMA to access a frame with the same dimensions as the
     * current mode
     */
    zx_resolution_set(dispPtr->vMode.width, dispPtr->vMode.height);
    zx_vdma_start_address_set((uint32_t)dispPtr->framePtr[dispPtr->curFrame], 1);

    dispPtr->state = DISPLAY_RUNNING;

    return XST_SUCCESS;
}

/* ------------------------------------------------------------ */

/***    DisplayInitialize(DisplayCtrl *dispPtr, XAxiVdma *vdma, u16 vtcId, u32 dynClkAddr, u8 *framePtr[DISPLAY_NUM_FRAMES])
**
**    Parameters:
**        dispPtr - Pointer to the struct that will be initialized
**        vdma - Pointer to initialized VDMA struct
**        vtcId - Device ID of the VTC core as found in xparameters.h
**        dynClkAddr - BASE ADDRESS of the axi_dynclk core
**        framePtr - array of pointers to the framebuffers. The framebuffers must be instantiated above this driver, and there must be 3
**
**    Return Value: int
**        XST_SUCCESS if successful, XST_FAILURE otherwise
**
**    Errors:
**
**    Description:
**        Initializes the driver struct for use.
**
*/
int DisplayInitialize(DisplayCtrl *dispPtr, u16 vtcId, u32 dynClkAddr, u8 *framePtr[DISPLAY_NUM_FRAMES])
{
    int Status;
    int i;
    XVtc_Config *vtcConfig;
    ClkConfig clkReg;
    ClkMode clkMode;


    /*
     * Initialize all the fields in the DisplayCtrl struct
     */
    dispPtr->curFrame = 0;
    dispPtr->dynClkAddr = dynClkAddr;
    for (i = 0; i < DISPLAY_NUM_FRAMES; i++)
    {
        dispPtr->framePtr[i] = framePtr[i];
    }
    dispPtr->state = DISPLAY_STOPPED;
    dispPtr->vMode = VMODE_1280x720;

    ClkFindParams(dispPtr->vMode.freq, &clkMode);

    /*
     * Store the obtained frequency to pxlFreq. It is possible that the PLL was not able to
     * exactly generate the desired pixel clock, so this may differ from vMode.freq.
     */
    dispPtr->pxlFreq = clkMode.freq;

    /*
     * Write to the PLL dynamic configuration registers to configure it with the calculated
     * parameters.
     */
    if (!ClkFindReg(&clkReg, &clkMode))
    {
        xdbg_printf(XDBG_DEBUG_GENERAL, "Error calculating CLK register values\n\r");
        return XST_FAILURE;
    }
    ClkWriteReg(&clkReg, dispPtr->dynClkAddr);

    /*
     * Enable the dynamically generated clock
    */
    ClkStart(dispPtr->dynClkAddr);

    /* Initialize the VTC driver so that it's ready to use look up
     * configuration in the config table, then initialize it.
     */
    vtcConfig = XVtc_LookupConfig(vtcId);
    /* Checking Config variable */
    if (NULL == vtcConfig) {
        return (XST_FAILURE);
    }
    Status = XVtc_CfgInitialize(&(dispPtr->vtc), vtcConfig, vtcConfig->BaseAddress);
    /* Checking status */
    if (Status != (XST_SUCCESS)) {
        return (XST_FAILURE);
    }

    return XST_SUCCESS;
}
/* ------------------------------------------------------------ */

/***    DisplaySetMode(DisplayCtrl *dispPtr, const VideoMode *newMode)
**
**    Parameters:
**        dispPtr - Pointer to the initialized DisplayCtrl struct
**        newMode - The VideoMode struct describing the new mode.
**
**    Return Value: int
**        XST_SUCCESS if successful, XST_FAILURE otherwise
**
**    Errors:
**
**    Description:
**        Changes the resolution being output to the display. If the display
**        is currently started, it is automatically stopped (DisplayStart must
**        be called again).
**
*/
int DisplaySetMode(DisplayCtrl *dispPtr, const VideoMode *newMode)
{
    int Status;

    /*
     * If currently running, stop
     */
    if (dispPtr->state == DISPLAY_RUNNING)
    {
        Status = DisplayStop(dispPtr);
        if (Status != XST_SUCCESS)
        {
            xdbg_printf(XDBG_DEBUG_GENERAL, "Cannot change mode, unable to stop display %d\r\n", Status);
            return XST_FAILURE;
        }
    }

    dispPtr->vMode = *newMode;

    return XST_SUCCESS;
}
/* ------------------------------------------------------------ */

/***    DisplayChangeFrame(DisplayCtrl *dispPtr, u32 frameIndex)
**
**    Parameters:
**        dispPtr - Pointer to the initialized DisplayCtrl struct
**        frameIndex - Index of the framebuffer to change to (must
**                be between 0 and (DISPLAY_NUM_FRAMES - 1))
**
**    Return Value: int
**        XST_SUCCESS if successful, XST_FAILURE otherwise
**
**    Errors:
**
**    Description:
**        Changes the frame currently being displayed.
**
*/

int DisplayChangeFrame(DisplayCtrl *dispPtr, u32 frameIndex)
{
    dispPtr->curFrame = frameIndex;
    /*
     * If currently running, then the DMA needs to be told to start reading from the desired frame
     * at the end of the current frame
     */
    if (dispPtr->state == DISPLAY_RUNNING)
    {
        zx_vdma_start_address_set((uint32_t)dispPtr->framePtr[frameIndex], 1);
    }
    return XST_SUCCESS;
}


/************************************************************************/

