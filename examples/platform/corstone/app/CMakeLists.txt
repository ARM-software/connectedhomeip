#
#   Copyright (c) 2022 Project CHIP Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

cmake_minimum_required(VERSION 3.21)

# Declare Corstone startup target
add_library(corstone-startup
    OBJECT
        corstone_startup_gcc.cpp
)

target_link_libraries(corstone-startup
    PUBLIC
        # iotsdk-serial-retarget contains the UART but we don't need the retarget part
        $<FILTER:$<TARGET_OBJECTS:iotsdk-serial-retarget>,EXCLUDE,.*gcc_retarget.*>
        cmsis-rtos-api
        mcu-driver-hal-api
        mbed-critical
        tfm-ns-interface
)

target_link_options(corstone-startup
    PUBLIC
        "-Wl,--wrap,__malloc_lock"
        "-Wl,--wrap,__malloc_unlock"
)

# Declare Corstone app interface target
add_library(corstone-app
    corstone_platform.cpp
    ${CHIP_ROOT}/examples/providers/DeviceInfoProviderImpl.cpp
)

target_include_directories(corstone-app
    PUBLIC
        .
        ${CHIP_ROOT}/examples/providers
)

target_link_libraries(corstone-app
    PUBLIC
        chip
)

if(CONFIG_CHIP_CORSTONE_OTA_ENABLE)
    target_include_directories(corstone-app
        PUBLIC
            dfu
    )

    target_sources(corstone-app
        PUBLIC
            dfu/corstone_dfu_manager.cpp
    )

    target_compile_definitions(corstone-app
        PUBLIC
            CHIP_CORSTONE_OTA_ENABLE
    )
endif()
