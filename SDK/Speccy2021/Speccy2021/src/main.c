/*
 Speccy-2021, a ZX Spectrum Emulator on Arty-Z7 (Zynq7020)
 =========================================================

 This is the top module of the emulator


 Designed in Magictale Electronics.
 
 Copyright (c) 2021 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 
 This code is in the public domain.
*/

#include "speccy2021.h"

static StackType_t timer_task_stack_buf[configMINIMAL_STACK_SIZE];
static StackType_t idle_task_stack_buf[configMINIMAL_STACK_SIZE];
static StaticTask_t timer_task_tcb_buffer;
static StaticTask_t idle_task_tcb_buffer;

void vApplicationGetTimerTaskMemory( StaticTask_t **ppxTimerTaskTCBBuffer, StackType_t **ppxTimerTaskStackBuffer, uint32_t *pulTimerTaskStackSize )
{
    *ppxTimerTaskTCBBuffer = &timer_task_tcb_buffer;
    *ppxTimerTaskStackBuffer = timer_task_stack_buf;
    *pulTimerTaskStackSize = configMINIMAL_STACK_SIZE;
}

void vApplicationGetIdleTaskMemory( StaticTask_t **ppxIdleTaskTCBBuffer, StackType_t **ppxIdleTaskStackBuffer, uint32_t *pulIdleTaskStackSize )
{
    *ppxIdleTaskTCBBuffer = &idle_task_tcb_buffer;
    *ppxIdleTaskStackBuffer = idle_task_stack_buf;
    *pulIdleTaskStackSize = configMINIMAL_STACK_SIZE;
}

int main(int argc, char ** argv)
{
    sys_thread_new("main_thread", (void (*)(void*)) speccy_main_thread, 0, THREAD_STACKSIZE, DEFAULT_THREAD_PRIO);

    vTaskStartScheduler();

    /* If all is well, the scheduler will now be running, and the following line
     will never be reached.  If the following line does execute, then the scheduler
     excited for some error condition */
    xil_printf("FreeRTOS scheduler error\r\n");

    for (;;)
        ;

    return 0;
}

