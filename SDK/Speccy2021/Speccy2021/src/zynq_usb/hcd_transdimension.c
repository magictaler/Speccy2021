/*
 This is the glue layer between USBTiny stack and
 Zynq7020 USB peripheral along with Zynq7020 interrupt system and
 TUSB1210 ULPI tranceiver. The last one is specific to the Arty Z20 boards

 Designed in Magictale Electronics.
 
 Copyright (c) 2021 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 
 This code is in the public domain.
*/


#include "tinyusb/tusb_option.h"

// NXP Trans-Dimension USB IP implement EHCI for host functionality

#if TUSB_OPT_HOST_ENABLED && CFG_TUSB_MCU == OPT_MCU_ZYNQ70XX

//--------------------------------------------------------------------+
// INCLUDE
//--------------------------------------------------------------------+
#include <FreeRTOS.h>
#include <task.h>
#include "usb_zynq70XX.h"
#include "tinyusb/host/usbh.h"
#include "tinyusb/common/tusb_common.h"
#include "common_transdimension.h"
#include "ehci/ehci_api.h"
#include "ulpi.h"
#include "xusbps_hw.h"

//--------------------------------------------------------------------+
// MACRO CONSTANT TYPEDEF
//--------------------------------------------------------------------+

// TODO can be merged with dcd_controller_t
typedef struct
{
    uint32_t regs_base;     // registers base
    uint32_t irqnum;
}hcd_controller_t;

static const hcd_controller_t _hcd_controller[] =
{
    { .regs_base = ZYNQ_USB0_BASE, .irqnum = ZYNQ_USB0_INT_ID },
    { .regs_base = ZYNQ_USB1_BASE, .irqnum = ZYNQ_USB0_INT_ID }
};

static XUsbPs_Config *usb_config_p;
static XUsbPs usb_instance;
static reg_PORTSCR1_Struct port_scr1;

// Interrupt controller structure defined in FreeRTOS
extern XScuGic xInterruptController;

static uint8_t hcd_read_ulpi_viewport(uint32_t addr)
{
    reg_ULPI_Viewport_Struct ulpi_viewport_reg;
    ulpi_viewport_reg.bits.data_address = addr;
    ulpi_viewport_reg.bits.data_read = 0;
    ulpi_viewport_reg.bits.data_write = 0;
    ulpi_viewport_reg.bits.execute_transaction = 1;
    ulpi_viewport_reg.bits.write_select = 0;
    XUsbPs_WriteReg(usb_config_p->BaseAddress, XUSBPS_ULPIVIEW_OFFSET, ulpi_viewport_reg.u32);

    ulpi_viewport_reg.u32 = XUsbPs_ReadReg(usb_config_p->BaseAddress, XUSBPS_ULPIVIEW_OFFSET);
    while (ulpi_viewport_reg.bits.execute_transaction == 1)
    {
        vTaskDelay(10);
        ulpi_viewport_reg.u32 = XUsbPs_ReadReg(usb_config_p->BaseAddress, XUSBPS_ULPIVIEW_OFFSET);
    }

    return ulpi_viewport_reg.bits.data_read;
}


static void hcd_write_ulpi_viewport(uint32_t addr, uint8_t wdata)
{
    reg_ULPI_Viewport_Struct ulpi_viewport_reg;
    ulpi_viewport_reg.bits.data_address = addr;
    ulpi_viewport_reg.bits.data_read = 0;
    ulpi_viewport_reg.bits.data_write = wdata;
    ulpi_viewport_reg.bits.execute_transaction = 1;
    ulpi_viewport_reg.bits.write_select = 1;
    XUsbPs_WriteReg(usb_config_p->BaseAddress, XUSBPS_ULPIVIEW_OFFSET, ulpi_viewport_reg.u32);

    ulpi_viewport_reg.u32 = XUsbPs_ReadReg(usb_config_p->BaseAddress, XUSBPS_ULPIVIEW_OFFSET);
    while (ulpi_viewport_reg.bits.execute_transaction == 1)
    {
        ulpi_viewport_reg.u32 = XUsbPs_ReadReg(usb_config_p->BaseAddress, XUSBPS_ULPIVIEW_OFFSET);
    }
}


//--------------------------------------------------------------------+
// Controller API
//--------------------------------------------------------------------+

bool hcd_init(uint8_t rhport)
{
    int32_t status;
    uint32_t mode_value;
    uint16_t interrupt_id;
    usb_config_p = XUsbPs_LookupConfig(XPAR_XUSBPS_0_DEVICE_ID);
    if (NULL == usb_config_p)
    {
        return false;
    }

    status = XUsbPs_CfgInitialize(&usb_instance, usb_config_p, usb_config_p->BaseAddress);
    if (XST_SUCCESS != status)
    {
        return false;
    }

    interrupt_id = _hcd_controller[rhport].irqnum;
    // FIXME: probably will need to experiment with priorities
    XScuGic_SetPriorityTriggerType(&xInterruptController, interrupt_id, 0xA0, 0x3);
    status = XScuGic_Connect(&xInterruptController, interrupt_id,
        (Xil_ExceptionHandler)hcd_int_zynq_handler, (void *)(uint32_t)rhport);
    if (status != XST_SUCCESS)
    {
        return false;
    }
    XScuGic_Enable(&xInterruptController, interrupt_id);

    hcd_registers_t* hcd_reg = (hcd_registers_t*) _hcd_controller[rhport].regs_base;

    status = XUsbPs_Reset(&usb_instance);
    if (status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    mode_value = XUSBPS_MODE_CM_HOST_MASK;
    XUsbPs_WriteReg(usb_config_p->BaseAddress, XUSBPS_MODE_OFFSET, mode_value);

    // Enabling PTS
    port_scr1.u32 = 0;
    port_scr1.bits.phy_type_status = 2; // or 3?
    port_scr1.bits.parallel_transceiver_select = 0;
    port_scr1.bits.parallel_transceiver_width = 0;
    XUsbPs_WriteReg(usb_config_p->BaseAddress, XUSBPS_PORTSCR1_OFFSET, port_scr1.u32);

    // Before enabling the port in host mode voltage for FS/LS tranceiver must for set through IC_USB
    reg_IC_USB_Struct ic_usb;
    ic_usb.u32 = 0;
    ic_usb.bits.ic_vdd1 = XUSBPS_IC_VDD1_1V8;
    ic_usb.bits.inter_chip_tranceiver_enable = 1;
    XUsbPs_WriteReg(usb_config_p->BaseAddress, XUSBPS_IC_USB_OFFSET, ic_usb.u32);

    bool ulpi_chip_found = false;
    for (uint8_t attempts = 0; attempts < 10; attempts++)
    {
        uint8_t ulpi_vendor_id = hcd_read_ulpi_viewport(XUSBPS_ULPI_VENDOR_ID_REG_OFFSET);
        if (ulpi_vendor_id == ULPI_TUSB1210_VENDOR_ID)
        {
            ulpi_chip_found = true;
            break;
        }
    }

    if (ulpi_chip_found == false)
    {
        return XST_FAILURE;
    }

    reg_ULPI_OTG_CTRL_Struct ulpi_otg_ctrl;
    ulpi_otg_ctrl.u8 = hcd_read_ulpi_viewport(XUSBPS_ULPI_OTG_CTRL_REG_OFFSET);

    // Forcing ULPI to enable VBUS - this is the reason why we need to communicate to
    // ULPI chip as Zynq7020 doesn't know anything about its vbus_external bit
    // ulpi_otg_ctrl.bits.drv_vbus is already set to 1 by now by the host controller
    ulpi_otg_ctrl.bits.drv_vbus_external = 1;
    hcd_write_ulpi_viewport(XUSBPS_ULPI_OTG_CTRL_REG_OFFSET, ulpi_otg_ctrl.u8);

    return ehci_init(rhport, (uint32_t) &hcd_reg->CAPLENGTH, (uint32_t) &hcd_reg->USBCMD);
}

void hcd_int_zynq_handler(void *CallBackRef, u32 IrqMask)
{
    hcd_int_handler((uint8_t)(uint32_t)CallBackRef);
}

void hcd_int_enable(uint8_t rhport)
{
    XUsbPs_IntrEnable(&usb_instance, XUSBPS_IXR_ALL);
}

void hcd_int_disable(uint8_t rhport)
{
    XUsbPs_IntrDisable(&usb_instance, XUSBPS_IXR_ALL);
}

#endif
