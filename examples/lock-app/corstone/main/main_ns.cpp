/*
 *
 *    Copyright (c) 2022 Project CHIP Authors
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

#include <stdio.h>
#include <stdlib.h>

#include <lib/support/logging/CHIPLogging.h>

#include "corstone_platform.h"

int main()
{
    if (corstone_platform_init())
    {
        ChipLogError(NotSpecified, "Corstone platform initialization failed");
        return EXIT_FAILURE;
    }

    if (corstone_chip_init())
    {
        ChipLogError(NotSpecified, "Corstone CHIP stack initialization failed");
        return EXIT_FAILURE;
    }

    ChipLogProgress(NotSpecified, "Corstone lock-app example application start");

    if (corstone_network_init(true))
    {
        ChipLogError(NotSpecified, "Network initialization failed");
        return EXIT_FAILURE;
    }

    if (corstone_chip_run())
    {
        ChipLogError(NotSpecified, "CHIP stack run failed");
        return EXIT_FAILURE;
    }

    ChipLogProgress(NotSpecified, "Corstone lock-app example application run");

    while (true)
    {
        // Add forever delay to ensure proper workload for this thread
        osDelay(osWaitForever);
    }

    corstone_chip_shutdown();

    return EXIT_SUCCESS;
}
