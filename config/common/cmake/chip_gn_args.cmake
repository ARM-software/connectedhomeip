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
#     CMake file that allows collecting C/C++ compiler flags passed to 
#     the CHIP build system.
#

# ==============================================================================
# Configuration variables and define constants
# ==============================================================================

# C/C++ compiler flags passed to CHIP build system
if (NOT CHIP_CFLAGS)
    set(CHIP_CFLAGS PARENT_SCOPE)
endif()

# C compiler flags passed to CHIP build system
if (NOT CHIP_CFLAGS_C)
    set(CHIP_CFLAGS_C PARENT_SCOPE)
endif()

# C++ compiler flags passed to CHIP build system
if (NOT CHIP_CFLAGS_CC)
    set(CHIP_CFLAGS_CC PARENT_SCOPE)
endif()

# GN meta-build system arguments in the form of 'key1 = value1\nkey2 = value2...' string
if (NOT CHIP_GN_ARGS)
    set(CHIP_GN_ARGS PARENT_SCOPE)
endif()

# ==============================================================================
# Helper macros
# ==============================================================================
macro(chip_gn_arg_import FILE)
    string(APPEND CHIP_GN_ARGS "--module\n${FILE}\n")
endmacro()

macro(chip_gn_arg_string ARG STRING)
    string(APPEND CHIP_GN_ARGS "--arg-string\n${ARG}\n${STRING}\n")
endmacro()

macro(chip_gn_arg_bool ARG)
    if (${ARGN})
        string(APPEND CHIP_GN_ARGS "--arg\n${ARG}\ntrue\n")
    else()
        string(APPEND CHIP_GN_ARGS "--arg\n${ARG}\nfalse\n")
    endif()
endmacro()

macro(chip_gn_arg_cflags ARG CFLAGS)
    string(APPEND CHIP_GN_ARGS "--arg-cflags\n${ARG}\n${CFLAGS}\n")
endmacro()

macro(chip_gn_arg ARG VALUE)
    string(APPEND CHIP_GN_ARGS "--arg\n${ARG}\n${VALUE}\n")
endmacro()

# ==============================================================================
# Functions
# ==============================================================================

# Get compiler flags from listed targets.
# Collect common compile flags and save them in CHIP_CFLAGS
# Collect C/CXX compile flags and save them in CHIP_CFLAGS_C/CHIP_CFLAGS_CXX
# [Args]:
#   targets - list of targets
function(get_compiler_flags_from_targets targets)
    foreach(target ${targets})
        get_target_common_compile_flags(EXTERNAL_TARGET_CFLAGS ${target})
        get_lang_compile_flags(EXTERNAL_TARGET_CFLAGS_C ${target} C)
        get_lang_compile_flags(EXTERNAL_TARGET_CFLAGS_CXX ${target} CXX)
        list(APPEND CHIP_CFLAGS ${EXTERNAL_TARGET_CFLAGS})
        list(APPEND CHIP_CFLAGS_C ${EXTERNAL_TARGET_CFLAGS_C})
        list(APPEND CHIP_CFLAGS_CC ${EXTERNAL_TARGET_CFLAGS_CXX})
        # Reset between targets
        set(EXTERNAL_TARGET_CFLAGS "")
        set(EXTERNAL_TARGET_CFLAGS_C "")
        set(EXTERNAL_TARGET_CFLAGS_CXX "")
    endforeach()
    set(CHIP_CFLAGS ${CHIP_CFLAGS} PARENT_SCOPE)
    set(CHIP_CFLAGS_C ${CHIP_CFLAGS_C} PARENT_SCOPE)
    set(CHIP_CFLAGS_CC ${CHIP_CFLAGS_CC} PARENT_SCOPE)
endfunction()

# Generate the common GN configuration
function(generate_common_configuration)
    # Set up CHIP project configuration file
    if (CONFIG_CHIP_PROJECT_CONFIG)
        get_filename_component(CHIP_PROJECT_CONFIG
            ${CONFIG_CHIP_PROJECT_CONFIG}
            REALPATH
            BASE_DIR ${CMAKE_SOURCE_DIR}
        )
        set(CHIP_PROJECT_CONFIG "<${CHIP_PROJECT_CONFIG}>")
    else()
        set(CHIP_PROJECT_CONFIG "")
    endif()

    if (CHIP_CFLAGS)
        chip_gn_arg_cflags     ("target_cflags"                        ${CHIP_CFLAGS})
    endif() # CHIP_CFLAGS
    if (CHIP_CFLAGS_C)
        chip_gn_arg_cflags     ("target_cflags_c"                      ${CHIP_CFLAGS_C})
    endif() # CHIP_CFLAGS_C
    if (CHIP_CFLAGS_CC)
        chip_gn_arg_cflags     ("target_cflags_cc"                     ${CHIP_CFLAGS_CC})
    endif() # CHIP_CFLAGS_CC
    if (DEFINED CONFIG_CHIP_DEBUG)
        chip_gn_arg_bool       ("is_debug"                             CONFIG_CHIP_DEBUG)
    endif() # CONFIG_CHIP_DEBUG
    if (DEFINED CONFIG_CHIP_BUILD_TESTS)
        chip_gn_arg_bool       ("chip_build_tests"                     CONFIG_CHIP_BUILD_TESTS)
    endif() # CONFIG_CHIP_BUILD_TESTS
    if (DEFINED CONFIG_CHIP_LIB_SHELL)
        chip_gn_arg_bool       ("chip_build_libshell"                  CONFIG_CHIP_LIB_SHELL)
    endif() # CONFIG_CHIP_LIB_SHELL
    if (DEFINED CONFIG_CHIP_LIB_PW_RPC)
        chip_gn_arg_bool  ("chip_build_pw_rpc_lib"                     CONFIG_CHIP_LIB_PW_RPC)
    endif() # CONFIG_CHIP_LIB_PW_RPC
    if (CONFIG_CHIP_EXAMPLE_DEVICE_INFO_PROVIDER)
        chip_gn_arg_bool("chip_build_example_providers"                TRUE)
    endif() # CONFIG_CHIP_EXAMPLE_DEVICE_INFO_PROVIDER
    if (CHIP_PROJECT_CONFIG)
        chip_gn_arg_string("chip_project_config_include"               ${CHIP_PROJECT_CONFIG})
        chip_gn_arg_string("chip_system_project_config_include"        ${CHIP_PROJECT_CONFIG})
    endif() # CHIP_PROJECT_CONFIG
    set(CHIP_GN_ARGS ${CHIP_GN_ARGS} PARENT_SCOPE)
endfunction()

# Generate the temporary GUN arguments file from the settings
function(generate_args_tmp_file)
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/args.tmp" CONTENT ${CHIP_GN_ARGS})
endfunction()