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
#     CMake for Corstone configuration
#

include(FetchContent)

get_filename_component(CORSTONE_SOURCE ${CHIP_ROOT}/third_party/corstone/sdk REALPATH)

include(profile)

# Corstone targets passed to CHIP build
list(APPEND CONFIG_CHIP_EXTERNAL_TARGETS project_profile)

# Additional Corstone build configuration
set(TFM_NS_APP_VERSION "0.0.0" CACHE STRING "TF-M non-secure application version (in the x.x.x format)")
set(CONFIG_CHIP_CORSTONE_LWIP_DEBUG NO CACHE BOOL "Enable LwIP debug logs")

# Default LwIP options directory (should contain user_lwipopts.h file)
if (NOT LWIP_PROJECT_OPTS_DIR)
    set(LWIP_PROJECT_OPTS_DIR ${CORSTONE_CONFIG}/lwip)
endif()

# Overwrite versions of Corstone components

# Add a Matter specific version of Mbedtls
FetchContent_Declare(
    mbedtls
    GIT_REPOSITORY https://github.com/ARMmbed/mbedtls
    GIT_TAG        v3.2.1
    GIT_SHALLOW    ON
    GIT_PROGRESS   ON
)

# Apply a patch to TF-M to support GCC 12
FetchContent_Declare(
    trusted-firmware-m
    GIT_REPOSITORY  https://git.trustedfirmware.org/TF-M/trusted-firmware-m.git
    GIT_TAG         TF-Mv1.8.0
    GIT_SHALLOW     OFF
    GIT_PROGRESS    ON
    # Note: This prevents FetchContent_MakeAvailable() from calling
    # add_subdirectory() on the fetched repository. TF-M needs a
    # standalone build because it relies on functions defined in its
    # own toolchain files and contains paths that reference the
    # top-level project instead of its own project.
    SOURCE_SUBDIR   NONE
    PATCH_COMMAND   git reset --hard --quiet && git clean --force -dx --quiet && git apply ${CMAKE_CURRENT_LIST_DIR}/tf-m.patch
)

# Corstone configuration
set(IOTSDK_FETCH_LIST
    mcu-driver-reference-platforms-for-arm
    mbed-critical
    cmsis-5
    cmsis-freertos
    mbedtls
    lwip
    trusted-firmware-m
)

set(MDH_PLATFORM ARM_AN552_MPS3)
set(VARIANT "FVP")
set(FETCHCONTENT_QUIET OFF)
set(TFM_CMAKE_ARGS
    -D TFM_PLATFORM=${CORSTONE_EXAMPLE_COMMON}/tf-m/targets/an552
    -D TFM_PROFILE=profile_medium
    -D CONFIG_TFM_ENABLE_FP=ON
    -D TFM_PARTITION_FIRMWARE_UPDATE=ON
    -D PLATFORM_HAS_FIRMWARE_UPDATE_SUPPORT=ON
    -D MCUBOOT_DATA_SHARING=ON
    -D MCUBOOT_IMAGE_VERSION_NS=${TFM_NS_APP_VERSION}
    -D TFM_EXCEPTION_INFO_DUMP=ON
    -D CONFIG_TFM_HALT_ON_CORE_PANIC=ON
    -D TFM_ISOLATION_LEVEL=1
    -D TFM_MBEDCRYPTO_PLATFORM_EXTRA_CONFIG_PATH=${CORSTONE_CONFIG}/mbedtls/mbedtls_config_psa.h
    -D MBEDCRYPTO_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
)

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    list(APPEND TFM_CMAKE_ARGS
        -D MCUBOOT_LOG_LEVEL=INFO
        -D TFM_SPM_LOG_LEVEL=TFM_SPM_LOG_LEVEL_DEBUG
        -D TFM_PARTITION_LOG_LEVEL=TFM_PARTITION_LOG_LEVEL_INFO
    )
else()
    list(APPEND TFM_CMAKE_ARGS
        -D MCUBOOT_LOG_LEVEL=ERROR
        -D TFM_SPM_LOG_LEVEL=TFM_SPM_LOG_LEVEL_DEBUG
        -D TFM_PARTITION_LOG_LEVEL=TFM_PARTITION_LOG_LEVEL_ERROR
    )
endif()
if(TFM_PROJECT_CONFIG_HEADER_FILE)
    list(APPEND TFM_CMAKE_ARGS
        -D PROJECT_CONFIG_HEADER_FILE=${TFM_PROJECT_CONFIG_HEADER_FILE}
    )
endif()

# Add Corstone source
add_subdirectory(${CORSTONE_SOURCE} ./corstone_build)

# Add Corstone modules to path
list(APPEND CMAKE_MODULE_PATH ${open-iot-sdk_SOURCE_DIR}/cmake)
list(APPEND CMAKE_MODULE_PATH ${open-iot-sdk_SOURCE_DIR}/components/trusted-firmware-m)

# Configure component properties

if(TARGET mcu-driver-hal-api)
    # It is required to pass to mcu-driver-hal-api that it is compiled in NS mode
    target_compile_definitions(mcu-driver-hal-api
        INTERFACE
            DOMAIN_NS=1
    )
endif()

# Add RTOS configuration headers
# Link cmsis-rtos-api against a concrete implementation
if(TARGET cmsis-rtos-api)
    target_include_directories(cmsis-config
        INTERFACE
            cmsis-config
    )

    if(TARGET freertos-cmsis-rtos)
        target_include_directories(freertos-config
            INTERFACE
                freertos-config
        )

        target_link_libraries(freertos-config
            INTERFACE
                cmsis-config
        )
        target_link_libraries(cmsis-rtos-api
            PUBLIC
                freertos-cmsis-rtos
        )
    endif()
endif()

# LwIP configuration
if(TARGET lwip-cmsis-port)
    # lwipcore requires the config defined by lwip-cmsis-port
    target_link_libraries(lwipcore
        PUBLIC
            lwip-cmsis-port
    )

    # provide method to use for tracing by the lwip port (optional)
    target_compile_definitions(lwipopts
        INTERFACE
            DEBUG_PRINT=printf
            $<$<BOOL:${CONFIG_CHIP_CORSTONE_LWIP_DEBUG}>:LWIP_DEBUG>
            $<$<BOOL:${CONFIG_CHIP_LIB_TESTS}>:CHIP_LIB_TESTS>
    )

    target_include_directories(lwipopts
        INTERFACE
            ${LWIP_PROJECT_OPTS_DIR}
    )

    # Link the emac factory to LwIP port
    target_link_libraries(lwip-cmsis-port PUBLIC iotsdk-emac-factory)
endif()

# MDH configuration
if(TARGET ethernet-lan91c111)
    target_compile_definitions(ethernet-lan91c111
        INTERFACE
            LAN91C111_RFS_MULTICAST_SUPPORT
    )
endif()

# Mbedtls config
if(TARGET mbedtls-config)
    target_include_directories(mbedtls-config
        INTERFACE
            ${CORSTONE_CONFIG}/mbedtls
    )

    target_sources(mbedtls-config
        INTERFACE
            ${CORSTONE_CONFIG}/mbedtls/platform_alt.cpp
    )

    target_compile_definitions(mbedtls-config
        INTERFACE
            MBEDTLS_CONFIG_FILE="${CORSTONE_CONFIG}/mbedtls/mbedtls_config.h"
    )

    target_link_libraries(mbedtls-config
        INTERFACE
            mbedtls-threading-cmsis-rtos
    )
endif()

if("mcu-driver-reference-platforms-for-arm" IN_LIST IOTSDK_FETCH_LIST)
    list(APPEND CONFIG_CHIP_EXTERNAL_TARGETS
        mcu-driver-hal-api
        mdh-arm-hal-impl-an552
    )
endif()

if("cmsis-5" IN_LIST IOTSDK_FETCH_LIST)
    list(APPEND CONFIG_CHIP_EXTERNAL_TARGETS
        iotsdk-cmsis-core-device
        cmsis-rtos-api
        iotsdk-ip-network-api
    )
endif()

if("cmsis-freertos" IN_LIST IOTSDK_FETCH_LIST)
    list(APPEND CONFIG_CHIP_EXTERNAL_TARGETS
        freertos-cmsis-rtos
    )
endif()

if("lwip" IN_LIST IOTSDK_FETCH_LIST)
    list(APPEND CONFIG_CHIP_EXTERNAL_TARGETS
        lwipcore
        lwip-cmsis-port
        lwip-cmsis-sys
        lwip-cmsis-port-low-input-latency
        lwipopts
    )
endif()

if("trusted-firmware-m" IN_LIST IOTSDK_FETCH_LIST)
    list(APPEND CONFIG_CHIP_EXTERNAL_TARGETS
        tfm-ns-interface
        tfm-ns-interface-cmsis-rtos
    )
endif()

# Note: Mbed TLS must appear after TF-M otherwise psa from mbed TLS is used
if("mbedtls" IN_LIST IOTSDK_FETCH_LIST)
    list(APPEND CONFIG_CHIP_EXTERNAL_TARGETS
        mbedtls
        mbedtls-config
        mbedtls-threading-cmsis-rtos
    )
endif()

function(sdk_post_build target)
    string(REPLACE "_ns" "" APP_NAME ${target})
    include(ConvertElfToBin)
    include(SignTfmImage)
    ExternalProject_Get_Property(trusted-firmware-m-build BINARY_DIR)
    target_elf_to_bin(${target})
    add_custom_command(
        TARGET
            ${target}
        POST_BUILD
        DEPENDS
            $<TARGET_FILE_DIR:${target}>/${target}.bin
        COMMAND
            # Sign the non-secure (application) image for TF-M bootloader (BL2)"
            python3 ${BINARY_DIR}/install/image_signing/scripts/wrapper/wrapper.py
                --layout ${BINARY_DIR}/install/image_signing/layout_files/signing_layout_ns.o
                -v ${TFM_NS_APP_VERSION}
                -k ${BINARY_DIR}/install/image_signing/keys/root-RSA-3072_1.pem
                --public-key-format full
                --align 1 --pad --pad-header -H 0x400 -s auto -d "(0, 0.0.0+0)"
                $<TARGET_FILE_DIR:${target}>/${target}.bin
                --overwrite-only
                --measured-boot-record
                $<TARGET_FILE_DIR:${target}>/${target}_signed.bin
        VERBATIM
    )
    iotsdk_tf_m_merge_images(${target} 0x10000000 0x38000000 0x28060000)
if(CONFIG_CHIP_CORSTONE_OTA_ENABLE)
    add_custom_command(
        TARGET
            ${target}
        POST_BUILD
        DEPENDS
            $<TARGET_FILE_DIR:${target}>/${target}.bin
        COMMAND
            # Sign the update image
            python3 ${BINARY_DIR}/install/image_signing/scripts/wrapper/wrapper.py
                --layout ${BINARY_DIR}/install/image_signing/layout_files/signing_layout_ns.o
                -v ${TFM_NS_APP_VERSION}
                -k ${BINARY_DIR}/install/image_signing/keys/root-RSA-3072_1.pem
                --public-key-format full
                --align 1 --pad-header -H 0x400 -s auto -d "(0, 0.0.0+0)"
                $<TARGET_FILE_DIR:${target}>/${target}.bin
                --overwrite-only
                --measured-boot-record
                $<TARGET_FILE_DIR:${target}>/${target}_signed.ota
        COMMAND
            # Create OTA udpate file
            ${CHIP_ROOT}/src/app/ota_image_tool.py
                create
                -v 0xfff1 -p 0x8001
                -vn ${CONFIG_CHIP_CORSTONE_SOFTWARE_VERSION}
                -vs "${CONFIG_CHIP_CORSTONE_SOFTWARE_VERSION_STRING}"
                -da sha256
                $<TARGET_FILE_DIR:${target}>/${target}_signed.ota
                $<TARGET_FILE_DIR:${target}>/${APP_NAME}.ota
        # Cleanup
        COMMAND rm
        ARGS -Rf
                $<TARGET_FILE_DIR:${target}>/${target}_signed.ota
        VERBATIM
    )
endif()
    # Cleanup
    add_custom_command(
        TARGET
            ${target}
        POST_BUILD
        DEPENDS
            $<TARGET_FILE_DIR:${target}>/${target}.bin
            $<TARGET_FILE_DIR:${target}>/${target}_signed.bin
            $<TARGET_FILE_DIR:${target}>/${target}_merged.hex
            $<TARGET_FILE_DIR:${target}>/${target}_merged.elf
        COMMAND
            # Copy the bootloader and TF-M secure image for debugging purposes
            ${CMAKE_COMMAND} -E copy
                ${BINARY_DIR}/install/outputs/bl2.elf
                ${BINARY_DIR}/install/outputs/tfm_s.elf
                $<TARGET_FILE_DIR:${target}>/
        COMMAND
            # Rename output file
            ${CMAKE_COMMAND} -E copy
                $<TARGET_FILE_DIR:${target}>/${target}_merged.elf
                $<TARGET_FILE_DIR:${target}>/${APP_NAME}.elf
        COMMAND rm
        ARGS -Rf
            $<TARGET_FILE_DIR:${target}>/${target}.bin
            $<TARGET_FILE_DIR:${target}>/${target}_signed.bin
            $<TARGET_FILE_DIR:${target}>/${target}_merged.hex
            $<TARGET_FILE_DIR:${target}>/${target}_merged.elf
        VERBATIM
    )
endfunction()
