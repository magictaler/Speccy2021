//! @file usb_zynq70XX.h
//! @brief glue logic for TinyUSB stack

#ifndef USB_ZYNQ70XX_H
#define USB_ZYNQ70XX_H

#include <stdint.h>
#include <xusbps.h>
#include <xparameters.h>
#include <xscugic.h>
#include <xil_exception.h>

#define ZYNQ_USB0_BASE XPAR_XUSBPS_0_BASEADDR
#define ZYNQ_USB1_BASE XPAR_XUSBPS_0_BASEADDR

#define ZYNQ_USB0_INT_ID XPAR_XUSBPS_0_INTR
#define ZYNQ_USB1_INT_ID XPAR_XUSBPS_1_INTR

#define XUSBPS_IC_USB_OFFSET 0x0000016C  /**< IC USB */

#define XUSBPS_IC_VDD1_1V8 4

//!@brief C structure representing IC_USB register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t ic_vdd1 : 3;
        uint32_t inter_chip_tranceiver_enable : 1;
        uint32_t reserved1 : 3;

    } bits;

} reg_IC_USB_Struct;

//!@brief C structure representing ULPI Viewport register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t data_write : 8;
        uint32_t data_read : 8;
        uint32_t data_address : 8;
        uint32_t reserved1 : 3;
        uint32_t synchronous_state : 1;
        uint32_t reserved2 : 1;
        uint32_t write_select : 1;
        uint32_t execute_transaction : 1;
        uint32_t wake_up : 1;

    } bits;

} reg_ULPI_Viewport_Struct;

//!@brief C structure representing PORTSCR1 register.
typedef union
{
    uint32_t u32;

    struct
    {
        uint32_t device_present : 1;
        uint32_t connect_status_change : 1;
        uint32_t port_enabled :1;
        uint32_t port_enabled_change : 1;
        uint32_t overcurrent : 1;
        uint32_t overcurrent_change : 1;
        uint32_t force_port_resume : 1;
        uint32_t suspend : 1;
        uint32_t port_reset : 1;
        uint32_t high_speed_mode : 1;
        uint32_t line_state : 2;
        uint32_t port_power_enable : 1;
        uint32_t port_owner_handoff : 1;
        uint32_t port_indicator_control_outputs : 2;
        uint32_t port_test_control : 4;
        uint32_t wake_on_connect : 1;
        uint32_t wake_on_disconnect : 1;
        uint32_t wake_on_overcurrent : 1;
        uint32_t phy_low_power_clk_disable : 1;
        uint32_t port_force_full_speed_connect : 1;
        uint32_t parallel_transceiver_select : 1;
        uint32_t port_speed_operating_mode : 2;
        uint32_t parallel_transceiver_width : 1;
        uint32_t serial_transceiver_select : 1;
        uint32_t phy_type_status : 2;
    } bits;

} reg_PORTSCR1_Struct;


#endif
