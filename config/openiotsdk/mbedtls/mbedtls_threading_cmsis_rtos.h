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

#ifndef MBEDTLS_THREADING_CMSIS_RTOS_H
#define MBEDTLS_THREADING_CMSIS_RTOS_H

#include "cmsis_os2.h"

/** This is an internal Mbed TLS structure used by the threading module.
 *  It's required in alternative threading support.
 */
typedef struct
{
    osMutexId_t mutex;
} mbedtls_threading_mutex_t;

/** Set CMSIS RTOS as alternative threading implemenation. */
void mbedtls_threading_set_cmsis_rtos(void);

#endif // ! MBEDTLS_THREADING_CMSIS_RTOS_H
