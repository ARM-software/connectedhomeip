# Copyright (c) 2020-2021 Arm Limited
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Sets profile options
function(set_profile_options target)
    set(profile_link_options "")

    if(${CMAKE_C_COMPILER_ID} STREQUAL GNU)
        list(APPEND profile_c_compile_options
            "-c"
            "-O2"
            "-g3"
        )
        target_compile_options(${target}
            INTERFACE
                $<$<COMPILE_LANGUAGE:C>:${profile_c_compile_options}>
        )

        list(APPEND profile_cxx_compile_options
            "-c"
            "-fno-rtti"
            "-Wvla"
            "-O2"
            "-g3"
        )
        target_compile_options(${target}
            INTERFACE
                $<$<COMPILE_LANGUAGE:CXX>:${profile_cxx_compile_options}>
        )

        list(APPEND profile_asm_compile_options
            "-c"
            "-x" "assembler-with-cpp"
        )
        target_compile_options(${target}
            INTERFACE
                $<$<COMPILE_LANGUAGE:ASM>:${profile_asm_compile_options}>
        )

        list(APPEND profile_link_options
            "-Wl,--gc-sections"
            "-Wl,-n"
        )

        target_link_options(${target}
            INTERFACE
                "-Wl,--gc-sections"
                "-Wl,-n"
        )
    else()
        message(FATAL_ERROR "Invalid compiler type '${CMAKE_C_COMPILER_ID}'. Possible values:\n GNU")
    endif()

    target_compile_definitions(${target}
        INTERFACE
            NDEBUG
    )
endfunction()
