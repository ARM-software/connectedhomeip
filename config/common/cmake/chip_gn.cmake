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
#     CMake file defining 'chip' target which represents CHIP library
#     and other optional libraries like unit tests, built with specific
#     platform.
#     Since CHIP doesn't provide native CMake support, ExternalProject
#     module is used to build the required artifacts with GN meta-build
#     system.
#

# Check or set paths
if (NOT GN_ROOT_TARGET)
    message(FATAL_ERROR "GN_ROOT_TARGET not defined. Please provide the path to your CHIP GN project.")
endif()

if (NOT CHIP_ROOT)
    get_filename_component(CHIP_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../.. REALPATH)
endif()

set(CHIP_LIB_DIR ${CMAKE_CURRENT_BINARY_DIR}/lib)

# Prepare CHIP libraries that the application should be linked with
list(APPEND CHIP_LIBRARIES -lCHIP)

if (CONFIG_CHIP_LIB_SHELL)
    list(APPEND CHIP_LIBRARIES -lCHIPShell)
endif()

if (CONFIG_CHIP_LIB_PW_RPC)
    list(APPEND CHIP_LIBRARIES -lPwRpc)
endif(CONFIG_CHIP_LIB_PW_RPC)

if (CONFIG_CHIP_EXAMPLE_DEVICE_INFO_PROVIDER)
    list(APPEND CHIP_LIBRARIES -lMatterDeviceInfoProviderExample)
endif()

list(TRANSFORM CHIP_LIBRARIES REPLACE
    "-l(.*)"
    "${CHIP_LIB_DIR}/lib\\1.a"
)

# ==============================================================================
# Find required programs
# ==============================================================================
find_package(Python3 REQUIRED)
find_program(GN_EXECUTABLE gn REQUIRED)

# Parse the 'gn --version' output to find the installed version.
set(MIN_GN_VERSION 1851)
execute_process(
    COMMAND ${GN_EXECUTABLE} --version
    OUTPUT_VARIABLE GN_VERSION
    COMMAND_ERROR_IS_FATAL ANY
)
if (GN_VERSION VERSION_LESS MIN_GN_VERSION)
    message(FATAL_ERROR "Found unsupported version of gn: ${MIN_GN_VERSION}+ is required")
endif()

# ==============================================================================
# Define 'chip-gn' target that builds CHIP library(ies) with GN build system
# ==============================================================================
ExternalProject_Add(
    chip-gn
    PREFIX                  ${CMAKE_CURRENT_BINARY_DIR}
    SOURCE_DIR              ${CHIP_ROOT}
    BINARY_DIR              ${CMAKE_CURRENT_BINARY_DIR}
    CONFIGURE_COMMAND       ""
    CONFIGURE_HANDLED_BY_BUILD TRUE
    BUILD_COMMAND           ${CMAKE_COMMAND} -E echo "Starting Matter library build in ${CMAKE_CURRENT_BINARY_DIR}"
    COMMAND                 ${Python3_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/make_gn_args.py @args.tmp > args.gn.tmp
    # Replace the config only if it has changed to avoid triggering unnecessary rebuilds
    COMMAND                 bash -c "(! diff -q args.gn.tmp args.gn && mv args.gn.tmp args.gn) || true" 
    # Regenerate the ninja build system
    COMMAND                 ${GN_EXECUTABLE}
                                --root=${CHIP_ROOT}
                                --root-target=${GN_ROOT_TARGET}
                                --dotfile=${GN_ROOT_TARGET}/.gn
                                --script-executable=${Python3_EXECUTABLE}
                                gen --check --fail-on-unused-args ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND                 ninja
    COMMAND                 ${CMAKE_COMMAND} -E echo "Matter library build complete"
    INSTALL_COMMAND         ""
    # Byproducts are removed by the clean target removing config and .ninja_deps
    # allows a rebuild of the external project after the clean target has been run. 
    BUILD_BYPRODUCTS        ${CMAKE_CURRENT_BINARY_DIR}/args.gn
                            ${CMAKE_CURRENT_BINARY_DIR}/build.ninja
                            ${CMAKE_CURRENT_BINARY_DIR}/.ninja_deps
                            ${CMAKE_CURRENT_BINARY_DIR}/build.ninja.stamp
                            ${CHIP_LIBRARIES}
    BUILD_ALWAYS            TRUE
    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD     TRUE
)

# ==============================================================================
# Define 'chip' target that exposes CHIP headers & libraries to the application
# ==============================================================================
add_library(chip INTERFACE)
target_compile_definitions(chip INTERFACE CHIP_HAVE_CONFIG_H)
target_include_directories(chip INTERFACE
    ${CHIP_ROOT}/src
    ${CHIP_ROOT}/src/include
    ${CHIP_ROOT}/src/lib
    ${CHIP_ROOT}/third_party/nlassert/repo/include
    ${CHIP_ROOT}/third_party/nlio/repo/include
    ${CHIP_ROOT}/zzz_generated/app-common
    ${CMAKE_CURRENT_BINARY_DIR}/gen/include
)

# Link required CHIP libraries
if (CONFIG_CHIP_LIB_SHELL)
    target_link_options(chip INTERFACE -Wl,--whole-archive ${CHIP_LIB_DIR}/libCHIPShell.a -Wl,--no-whole-archive)
endif()

if (CONFIG_CHIP_BUILD_TESTS)
    target_link_options(chip INTERFACE -Wl,--whole-archive ${CHIP_LIB_DIR}/libCHIP_tests.a -Wl,--no-whole-archive)
endif()

if (CONFIG_CHIP_LIB_PW_RPC)
    target_link_options(chip INTERFACE -Wl,--whole-archive ${CHIP_LIB_DIR}/libPwRpc.a -Wl,--no-whole-archive)
endif(CONFIG_CHIP_LIB_PW_RPC)

target_link_directories(chip INTERFACE ${CHIP_LIB_DIR})
target_link_libraries(chip INTERFACE -Wl,--start-group ${CHIP_LIBRARIES} -Wl,--end-group)
add_dependencies(chip chip-gn)
