/*
 *
 *    Copyright (c) 2021 Project CHIP Authors
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

#include <stdio.h>
#include <stdlib.h>

#include "corstone_platform.h"
#include <NlTestLogger.h>
#include <lib/support/UnitTestRegistration.h>
#include <platform/CHIPDeviceLayer.h>

constexpr nl_test_output_logger_t NlTestLogger::nl_test_logger;

using namespace ::chip;

int main()
{
    if (corstone_platform_init())
    {
        ChipLogAutomation("ERROR: Corstone platform initialization failed");
        return EXIT_FAILURE;
    }

    nlTestSetLogger(&NlTestLogger::nl_test_logger);

    ChipLogAutomation("Corstone unit-tests start");

    if (corstone_network_init(true))
    {
        ChipLogAutomation("ERROR: Network initialization failed");
        return EXIT_FAILURE;
    }

    ChipLogAutomation("Corstone unit-tests run...");
    int status = RunRegisteredUnitTests();
    ChipLogAutomation("Test status: %d", status);
    ChipLogAutomation("Corstone unit-tests completed");

    return EXIT_SUCCESS;
}
