/*
 *
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

#include "mbedtls_threading_cmsis_rtos.h"

#include "mbedtls/threading.h"

static const osMutexAttr_t mutex_attr = {
    "mbedtls",                             // human readable mutex name
    osMutexRecursive | osMutexPrioInherit, // attr_bits
    NULL,                                  // memory for control block
    0U                                     // size for control block
};

static void threading_mutex_init_cmsis_rtos(mbedtls_threading_mutex_t * mutex)
{
    if (mutex == NULL || mutex->mutex != NULL)
    {
        return;
    }

    mutex->mutex = osMutexNew(&mutex_attr);
}

static void threading_mutex_free_cmsis_rtos(mbedtls_threading_mutex_t * mutex)
{
    if (mutex == NULL || mutex->mutex == NULL)
    {
        return;
    }

    osStatus_t status = osMutexDelete(mutex->mutex);
    if (status == osOK)
    {
        mutex->mutex = NULL;
    }
}

static int threading_mutex_lock_cmsis_rtos(mbedtls_threading_mutex_t * mutex)
{
    if (mutex == NULL || mutex->mutex == NULL)
    {
        return MBEDTLS_ERR_THREADING_BAD_INPUT_DATA;
    }

    osStatus_t status = osMutexAcquire(mutex->mutex, 0U);
    if (status != osOK)
    {
        return MBEDTLS_ERR_THREADING_MUTEX_ERROR;
    }

    return 0;
}

static int threading_mutex_unlock_cmsis_rtos(mbedtls_threading_mutex_t * mutex)
{
    if (mutex == NULL || mutex->mutex == NULL)
    {
        return MBEDTLS_ERR_THREADING_BAD_INPUT_DATA;
    }

    osStatus_t status = osMutexRelease(mutex->mutex);
    if (status != osOK)
    {
        return MBEDTLS_ERR_THREADING_MUTEX_ERROR;
    }

    return 0;
}

void mbedtls_threading_set_cmsis_rtos()
{
    mbedtls_threading_set_alt(threading_mutex_init_cmsis_rtos, threading_mutex_free_cmsis_rtos, threading_mutex_lock_cmsis_rtos,
                              threading_mutex_unlock_cmsis_rtos);
}
