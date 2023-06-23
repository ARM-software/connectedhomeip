#
#   Copyright (c) 2023 Project CHIP Authors
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

#
#   @file
#     CMake helper to OIS mbedtls platform.
#

cmake_minimum_required(VERSION 3.21)

set(MBEDTLS_PLATFORM_BASE_DIR ${CMAKE_CURRENT_LIST_DIR})

# Add mbedtls platform specific sources to the specific target
# [Args]:
#   target - target name
# Available options are:
#   SCOPE   sources scope for the target, PRIVATE as default
macro(ois_add_mbedtls_platform target)
    set(SCOPE PRIVATE)
    cmake_parse_arguments(ARG "" "SCOPE" "" ${ARGN})
    if (ARG_SCOPE)
        set(SCOPE ${ARG_SCOPE})
    endif()

    target_include_directories(${target}
        ${SCOPE}
            ${MBEDTLS_PLATFORM_BASE_DIR}
    )

    target_sources(${target}
        ${SCOPE}
            ${MBEDTLS_PLATFORM_BASE_DIR}/platform_alt.c
            ${MBEDTLS_PLATFORM_BASE_DIR}/mbedtls_threading_cmsis_rtos.c
    )

    target_link_libraries(${target}
        ${SCOPE}
            mbedtls-config
            cmsis-rtos-api
    )
endmacro()
