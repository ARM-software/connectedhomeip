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

#
#   @file
#     CMake sub-project to configure and build the chip library.
#

include(ExternalProject)

# ==============================================================================
# Prepare CHIP configuration based on the project configuration
# ==============================================================================
# Set paths
if (NOT CHIP_ROOT)
    get_filename_component(CHIP_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../.. REALPATH)
endif()
get_filename_component(GN_ROOT_TARGET ${CHIP_ROOT}/config/openiotsdk/chip-gn REALPATH)
get_filename_component(COMMON_CMAKE_SOURCE_DIR ${CHIP_ROOT}/config/common/cmake REALPATH)

# Get common Cmake sources
include(${COMMON_CMAKE_SOURCE_DIR}/util.cmake)
include(${COMMON_CMAKE_SOURCE_DIR}/chip_gn_args.cmake)

# Prepare compiler flags
list(APPEND CHIP_CFLAGS_C  ${CMAKE_C_FLAGS})
list(APPEND CHIP_CFLAGS_CC ${CMAKE_CXX_FLAGS})

get_compiler_flags_from_targets("${CONFIG_CHIP_EXTERNAL_TARGETS}")

get_gnu_cpp_standard(CHIP_CFLAGS_CC)

convert_list_of_flags_to_string_of_flags(CHIP_CFLAGS CHIP_CFLAGS)
convert_list_of_flags_to_string_of_flags(CHIP_CFLAGS_C CHIP_CFLAGS_C)
convert_list_of_flags_to_string_of_flags(CHIP_CFLAGS_CC CHIP_CFLAGS_CC)

# ==============================================================================
# Generate configuration for CHIP GN build system
# ==============================================================================
generate_common_configuration()
chip_gn_arg_string("target_cpu"                           "${CMAKE_SYSTEM_PROCESSOR}")
chip_gn_arg_string("openiotsdk_ar"                        ${CMAKE_AR})
chip_gn_arg_string("openiotsdk_cc"                        ${CMAKE_C_COMPILER})
chip_gn_arg_string("openiotsdk_cxx"                       ${CMAKE_CXX_COMPILER})
chip_gn_arg_bool  ("chip_monolithic_tests"                CONFIG_CHIP_BUILD_TESTS)
chip_gn_arg_bool  ("chip_detail_logging"                  CONFIG_CHIP_DETAIL_LOGGING)
chip_gn_arg_bool  ("chip_progress_logging"                CONFIG_CHIP_PROGRESS_LOGGING)
chip_gn_arg_bool  ("chip_automation_logging"              CONFIG_CHIP_AUTOMATION_LOGGING)
chip_gn_arg_bool  ("chip_error_logging"                   CONFIG_CHIP_ERROR_LOGGING)
chip_gn_arg_bool  ("chip_openiotsdk_use_tfm"              TFM_SUPPORT)
chip_gn_arg_bool  ("chip_openiotsdk_use_psa_ps"           CONFIG_CHIP_OPEN_IOT_SDK_USE_PSA_PS)
chip_gn_arg_string("chip_crypto"                          "${CONFIG_CHIP_CRYPTO}")
chip_gn_arg_string("chip_openiotsdk_software_version"           "${CONFIG_CHIP_OPEN_IOT_SDK_SOFTWARE_VERSION}")
chip_gn_arg_string("chip_openiotsdk_software_version_string"    "${CONFIG_CHIP_OPEN_IOT_SDK_SOFTWARE_VERSION_STRING}")
chip_gn_arg_bool  ("chip_enable_ota_requestor"            CONFIG_CHIP_OPEN_IOT_SDK_OTA_ENABLE)
chip_gn_arg_bool  ("chip_system_config_use_iot_socket"    CONFIG_CHIP_OPEN_IOT_SDK_USE_IOT_SOCKET)
if (TARGET cmsis-rtos-api)
    chip_gn_arg_string("target_os"                        "cmsis-rtos")
endif()
chip_gn_arg_string("optimize_debug_level"                 "s")

generate_args_tmp_file()

# ==============================================================================
# Build chip library
# ==============================================================================
include(${COMMON_CMAKE_SOURCE_DIR}/chip_gn.cmake)
target_link_libraries(chip INTERFACE
    ${CONFIG_CHIP_EXTERNAL_TARGETS}
)
