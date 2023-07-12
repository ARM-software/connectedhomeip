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

cmake_minimum_required(VERSION 3.21)

get_filename_component(CHIP_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../../.. REALPATH)
get_filename_component(OPEN_IOT_SDK_CONFIG ${CHIP_ROOT}/config/openiotsdk REALPATH)
get_filename_component(OPEN_IOT_SDK_EXAMPLE_COMMON ${CHIP_ROOT}/examples/platform/openiotsdk REALPATH)

list(APPEND CMAKE_MODULE_PATH ${OPEN_IOT_SDK_CONFIG}/cmake)

# Application CHIP build configuration
set(CONFIG_CHIP_LIB_TESTS YES)
set(CONFIG_CHIP_DETAIL_LOGGING NO)
set(CONFIG_CHIP_PROGRESS_LOGGING NO)
set(CONFIG_CHIP_AUTOMATION_LOGGING YES)
set(CONFIG_CHIP_ERROR_LOGGING NO)

# Toolchain files need to exist before first call to project
include(toolchain)

project(chip-open-iot-sdk-unit-tests LANGUAGES C CXX ASM)

include(sdk)
include(chip)
include(linker)

add_subdirectory(${OPEN_IOT_SDK_EXAMPLE_COMMON}/app ./app_build)

# Read test cases file and parse it content to create cmake variable
file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/test_components.txt ConfigContents)
set(COMPONENTS_LIST)
foreach(NameAndValue ${ConfigContents})
    # Strip leading spaces
    string(REGEX REPLACE "^[ ]+" "" NameAndValue ${NameAndValue})
    # Find variable name
    string(REGEX MATCH "^[^=]+" Name ${NameAndValue})
    # Find the value
    string(REPLACE "${Name}=" "" Value ${NameAndValue})
    # Set the variable
    set(${Name}_SOURCES "${Value}")
    list(APPEND COMPONENTS_LIST ${Name})
endforeach()

target_compile_definitions(openiotsdk-startup
    PRIVATE
        IOT_SDK_APP_MAIN_STACK_SIZE=20480
)

foreach(TEST_COMPONENT IN LISTS COMPONENTS_LIST)
    string(STRIP ${${TEST_COMPONENT}_SOURCES} ${TEST_COMPONENT}_SOURCES)
    string(REPLACE "," ";"  ${TEST_COMPONENT}_SOURCES_LIST ${${TEST_COMPONENT}_SOURCES})
    foreach(TEST_CASE IN LISTS ${TEST_COMPONENT}_SOURCES_LIST)
        set(TEST_CASE_OBJECTS_TO_REMOVE ${${TEST_COMPONENT}_SOURCES_LIST})
        set(TEST_CASE_OBJECTS_FILE_TO_REMOVE)
        list(REMOVE_ITEM TEST_CASE_OBJECTS_TO_REMOVE "${TEST_CASE}")
        foreach(item IN LISTS TEST_CASE_OBJECTS_TO_REMOVE)
            list(APPEND TEST_CASE_OBJECTS_FILE_TO_REMOVE "lib${TEST_COMPONENT}.${item}.cpp.o")
        endforeach()

        set(APP_TARGET ${TEST_CASE}_ns)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${TEST_COMPONENT})
        add_executable(${APP_TARGET})
        target_include_directories(${APP_TARGET}
            PRIVATE
                main/include
                ${CHIP_ROOT}/third_party/nlunit-test/repo/src
        )

        target_sources(${APP_TARGET}
            PRIVATE
                main/main_ns.cpp
        )

        add_custom_target(${TEST_CASE}_generate_lib
            COMMAND
                ${CMAKE_COMMAND} -E copy
                    ${CMAKE_CURRENT_BINARY_DIR}/chip_build/lib/lib${TEST_COMPONENT}.a
                    ${CMAKE_CURRENT_BINARY_DIR}/chip_build/lib/${TEST_COMPONENT}/lib${TEST_CASE}.a
            COMMAND
                arm-none-eabi-ar dv ${CMAKE_CURRENT_BINARY_DIR}/chip_build/lib/${TEST_COMPONENT}/lib${TEST_CASE}.a ${TEST_CASE_OBJECTS_FILE_TO_REMOVE}
            VERBATIM
        )
        add_dependencies(${TEST_CASE}_generate_lib chip)
        add_dependencies(${APP_TARGET} ${TEST_CASE}_generate_lib)

        target_link_libraries(${APP_TARGET}
            openiotsdk-startup
            openiotsdk-app
        )
        # Link the *whole-archives* to keep the static test objects.
        target_link_options(${APP_TARGET}
            PUBLIC
            -Wl,--whole-archive "${CMAKE_CURRENT_BINARY_DIR}/chip_build/lib/${TEST_COMPONENT}/lib${TEST_CASE}.a"
            -Wl,--no-whole-archive
        )

        set_target_link(${APP_TARGET})
        sdk_post_build(${APP_TARGET})
    endforeach()
endforeach()
