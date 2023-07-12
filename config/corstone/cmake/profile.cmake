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
#     CMake profile configuration for target
#

# Set the default build type if none is specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE
        STRING "The build type" FORCE
    )
endif()

set(SUPPORTED_BUILD_TYPES Debug Release)

# Force the build types to be case-insensitive for checking
set(LOWERCASE_SUPPORTED_BUILD_TYPES ${SUPPORTED_BUILD_TYPES})
list(TRANSFORM LOWERCASE_SUPPORTED_BUILD_TYPES TOLOWER)
string(TOLOWER ${CMAKE_BUILD_TYPE} LOWERCASE_CMAKE_BUILD_TYPE)

if(NOT LOWERCASE_CMAKE_BUILD_TYPE IN_LIST LOWERCASE_SUPPORTED_BUILD_TYPES)
    message(FATAL_ERROR "Invalid build type '${CMAKE_BUILD_TYPE}'. Possible values:\n ${SUPPORTED_BUILD_TYPES}")
endif()

include(profiles/${LOWERCASE_CMAKE_BUILD_TYPE})

add_library(project_profile INTERFACE)
set_profile_options(project_profile)
