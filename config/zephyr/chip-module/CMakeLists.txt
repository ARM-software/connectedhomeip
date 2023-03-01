#
#   Copyright (c) 2022-2023 Project CHIP Authors
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
#     CMake sub-project defining 'chip' target which represents CHIP library
#     Since CHIP doesn't provide native CMake support, ExternalProject
#     module is used to build the required artifacts with GN meta-build
#     system. It is assumed that find_package(Zephyr) has been called before
#     including this file.
#

if (CONFIG_CHIP)

include(ExternalProject)
include(../zephyr-util.cmake)

#
# ==============================================================================
# Prepare CHIP configuration based on the project Kconfig configuration
# ==============================================================================
# Set paths
if (NOT CHIP_ROOT)
    get_filename_component(CHIP_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../.. REALPATH)
endif()
get_filename_component(GN_ROOT_TARGET ${CHIP_ROOT}/config/zephyr/chip-gn REALPATH)
get_filename_component(COMMON_CMAKE_SOURCE_DIR ${CHIP_ROOT}/config/common/cmake REALPATH)

# Additional configuration
if (CONFIG_CHIP_PW_RPC)
    set(CONFIG_CHIP_LIB_PW_RPC YES)
endif()

# Get common Cmake sources
include(${COMMON_CMAKE_SOURCE_DIR}/chip_gn_args.cmake)

# Prepare compiler flags
if (CONFIG_POSIX_API)
    list(APPEND CHIP_CFLAGS
        -D_SYS__PTHREADTYPES_H_
        -isystem${ZEPHYR_BASE}/include/zephyr/posix
    )
endif()

list(APPEND CHIP_CFLAGS -isystem${ZEPHYR_BASE}/../modules/crypto/mbedtls/include/)

zephyr_get_compile_flags(CHIP_CFLAGS_C C)
zephyr_get_compile_flags(CHIP_CFLAGS_CC CXX)
zephyr_get_gnu_cpp_standard(CHIP_CFLAGS_CC)

convert_list_of_flags_to_string_of_flags(CHIP_CFLAGS CHIP_CFLAGS)
convert_list_of_flags_to_string_of_flags(CHIP_CFLAGS_C CHIP_CFLAGS_C)
convert_list_of_flags_to_string_of_flags(CHIP_CFLAGS_CC CHIP_CFLAGS_CC)

# Set up custom OpenThread configuration

if (CONFIG_CHIP_OPENTHREAD_CONFIG)
    get_filename_component(CHIP_OPENTHREAD_CONFIG
        ${CONFIG_CHIP_OPENTHREAD_CONFIG}
        REALPATH
        BASE_DIR ${CMAKE_SOURCE_DIR}
    )
    zephyr_set_openthread_config(${CHIP_OPENTHREAD_CONFIG})
endif()

# ==============================================================================
# Generate configuration for CHIP GN build system
# ==============================================================================
generate_common_configuration()
chip_gn_arg_string("zephyr_ar"                              ${CMAKE_AR})
chip_gn_arg_string("zephyr_cc"                              ${CMAKE_C_COMPILER})
chip_gn_arg_string("zephyr_cxx"                             ${CMAKE_CXX_COMPILER})
chip_gn_arg_bool  ("is_debug"                               CONFIG_DEBUG)
chip_gn_arg_bool  ("chip_enable_openthread"                 CONFIG_NET_L2_OPENTHREAD)
chip_gn_arg_bool  ("chip_openthread_ftd"                    CONFIG_OPENTHREAD_FTD)
chip_gn_arg_bool  ("chip_inet_config_enable_ipv4"           CONFIG_NET_IPV4)
chip_gn_arg_bool  ("chip_inet_config_enable_tcp_endpoint"   CONFIG_CHIP_BUILD_TESTS)

if (CONFIG_CHIP_ENABLE_DNSSD_SRP)
    chip_gn_arg_string("chip_mdns" "platform")
endif()

generate_args_tmp_file()

# ==============================================================================
# Build chip library
# ==============================================================================
include(${COMMON_CMAKE_SOURCE_DIR}/chip_gn.cmake)
add_dependencies(chip-gn kernel)
set_property(GLOBAL APPEND PROPERTY ZEPHYR_INTERFACE_LIBS chip)

endif() # CONFIG_CHIP