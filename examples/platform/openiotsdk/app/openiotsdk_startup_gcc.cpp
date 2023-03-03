/*
 *    Copyright (c) 2006-2016 ARM Limited
 *    Copyright (c) 2023 Project CHIP Authors
 *    All rights reserved.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

#include <cmsis.h>
#include <errno.h>
#include <new>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "cmsis_os2.h"
#include "hal/serial_api.h"

#ifdef TFM_SUPPORT
extern "C" uint32_t tfm_ns_interface_init(void);
#endif // TFM_SUPPORT

#define CALLER_ADDR() __builtin_extract_return_addr(__builtin_return_address(0))

// Consider reducing the baudrate if the serial is used as input and characters are lost
extern "C" mdh_serial_t * get_example_serial();
#ifndef IOT_SDK_APP_SERIAL_BAUDRATE
#define IOT_SDK_APP_SERIAL_BAUDRATE 921600
#endif

// main thread declaration
// The thread object and associated stack are statically allocated
#ifndef IOT_SDK_APP_MAIN_STACK_SIZE
#define IOT_SDK_APP_MAIN_STACK_SIZE 16 * 1024
#endif
static void main_thread(void * argument);
alignas(8) char main_thread_stack[IOT_SDK_APP_MAIN_STACK_SIZE];
alignas(8) uint8_t main_thread_storage[100] __attribute__((section(".bss.os.thread.cb")));

// malloc mutex declaration
osMutexId_t malloc_mutex;
alignas(8) uint8_t malloc_mutex_obj[80];

// C runtime import: constructor initialization and main
extern "C" void __libc_init_array(void);
extern "C" int main(void);

/*
 * This function override startup sequence. Instead of releasing control to the C runtime
 * the following operations are performed:
 *
 * - initialize the serial (low level)
 * - initialize RTOS
 * - Start the RTOS with the main thread
 */
extern "C" void mbed_sdk_init(void)
{
    mdh_serial_set_baud(get_example_serial(), IOT_SDK_APP_SERIAL_BAUDRATE);

    int ret = osKernelInitialize();
    if (ret != osOK)
    {
        printf("osKernelInitialize failed: %d\r\n", ret);
        abort();
    }

    // Create main thread used to run the application
    {
        osThreadAttr_t main_thread_attr = {
            .name       = "main",
            .cb_mem     = &main_thread_storage,
            .cb_size    = sizeof(main_thread_storage),
            .stack_mem  = main_thread_stack,
            .stack_size = sizeof(main_thread_stack),
            .priority   = osPriorityNormal,
        };

        osThreadId_t main_thread_id = osThreadNew(main_thread, NULL, &main_thread_attr);
        if (main_thread_id == NULL)
        {
            printf("Main thread creation failed\r\n");
            abort();
        }
    }

    ret = osKernelStart();
    // Note osKernelStart should never return
    printf("Kernel failed to start: %d\r\n", ret);
    abort();
}

/**
 * Main thread
 * - Initialize TF-M
 * - Initialize the toolchain:
 *  - Setup mutexes for malloc and environment
 *  - Construct global objects
 * - Run the main
 */
static void main_thread(void * argument)
{
    // Create Malloc mutex
    {
        osMutexAttr_t malloc_mutex_attr = { .name      = "malloc_mutex",
                                            .attr_bits = osMutexRecursive | osMutexPrioInherit,
                                            .cb_mem    = &malloc_mutex_obj,
                                            .cb_size   = sizeof(malloc_mutex_obj) };

        malloc_mutex = osMutexNew(&malloc_mutex_attr);
        if (malloc_mutex == NULL)
        {
            printf("Failed to initialize malloc mutex\r\n");
            abort();
        }
    }

#ifdef TFM_SUPPORT
    {
        int ret = tfm_ns_interface_init();
        if (ret != 0)
        {
            printf("TF-M initialization failed: %d\r\n", ret);
            abort();
        }
    }
#endif

    /* Run the C++ global object constructors */
    __libc_init_array();

    int return_code = main();

    exit(return_code);
}

/*
 * Override of lock/unlock functions for malloc.
 */
extern "C" void __wrap___malloc_lock(struct _reent * reent)
{
    osMutexAcquire(malloc_mutex, osWaitForever);
}

extern "C" void __wrap___malloc_unlock(struct _reent * reent)
{
    osMutexRelease(malloc_mutex);
}

/*
 * Override of new/delete operators.
 * The override add a trace when a non-throwing new fails.
 */

void * operator new(std::size_t count)
{
    void * buffer = malloc(count);
    if (!buffer)
    {
        printf("operator new failure from %p\r\n", CALLER_ADDR());
        abort();
    }
    return buffer;
}

void * operator new[](std::size_t count)
{
    void * buffer = malloc(count);
    if (!buffer)
    {
        printf("operator new[] failure from %p\r\n", CALLER_ADDR());
        abort();
    }
    return buffer;
}

void * operator new(std::size_t count, const std::nothrow_t & tag)
{
    return malloc(count);
}

void * operator new[](std::size_t count, const std::nothrow_t & tag)
{
    return malloc(count);
}

void operator delete(void * ptr)
{
    free(ptr);
}

void operator delete(void * ptr, std::size_t)
{
    free(ptr);
}

void operator delete[](void * ptr)
{
    free(ptr);
}

void operator delete[](void * ptr, std::size_t)
{
    free(ptr);
}

/*
 * Override of _sbrk
 * It prints an error when the system runs out of memory in the heap segment.
 */

#undef errno
extern "C" int errno;

extern "C" char __end__;
extern "C" char __HeapLimit;

extern "C" void * _sbrk(int incr)
{
    static uint32_t heap = (uint32_t) &__end__;
    uint32_t prev_heap   = heap;
    uint32_t new_heap    = heap + incr;

    /* __HeapLimit is end of heap section */
    if (new_heap > (uint32_t) &__HeapLimit)
    {
        printf("_sbrk failure, incr = %d, new_heap = 0x%08lX\r\n", incr, new_heap);
        errno = ENOMEM;
        return (void *) -1;
    }

    heap = new_heap;
    return (void *) prev_heap;
}

// Override exit
extern "C" void _exit(int return_code)
{
    // display exit reason
    if (return_code)
    {
        printf("Application exited with %d\r\n", return_code);
    }

    // flush stdio
    fflush(stdout);
    fflush(stderr);

    // lock the kernel and go to sleep forever
    osKernelLock();
    while (1)
    {
        __WFE();
    }
}

// Calling a FreeRTOS API is illegal while scheduler is suspended.
// Therefore we provide this custom implementation which relies on underlying
// safety of malloc.
extern "C" void * pvPortMalloc(size_t size)
{
    return malloc(size);
}

extern "C" void vPortFree(void * ptr)
{
    free(ptr);
}
