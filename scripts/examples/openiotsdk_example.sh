#!/bin/bash

#
#    Copyright (c) 2020 Project CHIP Authors
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

# Build and/or run Open IoT SDK examples.

IS_TEST=0
NAME="$(basename "$0")"
HERE="$(dirname "$0")"
CHIP_ROOT="$(realpath $HERE/../..)"
COMMAND=build
PLATFORM=corstone300
CLEAN=0
SCRATCH=0
EXAMPLE_PATH=""
BUILD_PATH=""
TOOLCHAIN=arm-none-eabi-gcc
DEBUG=false
EXAMPLE=""
FVP_BIN=FVP_Corstone_SSE-300_Ethos-U55
GDB_PLUGIN="${FAST_MODEL_PLUGINS_PATH}/GDBRemoteConnection.so"
FVP_EXAMPLE_COMMON="${CHIP_ROOT}/examples/platform/openiotsdk/fvp"
FVP_CONFIG_FILE="${FVP_EXAMPLE_COMMON}/cs300.conf"
EXAMPLE_TEST_PATH="${CHIP_ROOT}/src/test_driver/openiotsdk/integration-tests"
TELNET_TERMINAL_PORT=5000
FAILED_TESTS=0
FVP_NETWORK="user"

function show_usage {
    cat <<EOF
Usage: $0 [options] example

Build, run or test the Open IoT SDK example.

Options:
    -h,--help                       Show this help
    -c,--clean                      Clean target build
    -s,--scratch                    Remove build directory at all before building
    -C,--command    <command>       Action to execute <build-run | run | test | build - default>
    -d,--debug      <debug_enable>  Build in debug mode <true | false - default>
    -p,--path       <build_path>    Build path <build_path - default is example_dir/build>
    -n,--network    <network_name>  FVP network interface name <network_name - default is "user" which means user network mode>

Examples:
    shell
    lock-app
EOF
}

function build_with_cmake {
    CMAKE="$(which cmake)"
    if [[ ! -f "$CMAKE" ]]; then
        echo "${NAME}: cmake is not in PATH" >&2
        exit 1
    fi

    set -e

    mkdir -p $BUILD_PATH

    if [[ $CLEAN -ne 0 ]]; then
        echo "Clean build" >&2
        if compgen -G "${BUILD_PATH}/CMake*" >/dev/null; then
            cmake --build $BUILD_PATH --target clean
            rm -rf $BUILD_PATH/CMake*
        fi
    fi

    if [[ $SCRATCH -ne 0 ]]; then
        echo "Remove building directory" >&2
        rm -rf $BUILD_PATH
    fi

    BUILD_OPTIONS="-DCMAKE_SYSTEM_PROCESSOR=cortex-m55"
    if $DEBUG; then
        BUILD_OPTIONS="${BUILD_OPTIONS} -DCMAKE_BUILD_TYPE=Debug"
    fi

    # Remove old artifacts to force linking
    rm -rf "$BUILD_PATH/chip-"*

    cmake -G Ninja -S $EXAMPLE_PATH -B $BUILD_PATH --toolchain=$TOOLCHAIN_PATH $BUILD_OPTIONS
    cmake --build $BUILD_PATH
}

function run_fvp {

    set -e

    # Check if FVP exists
    if ! [ -x "$(command -v ${FVP_BIN})" ]; then
        echo "Error: $FVP_BIN not installed." >&2
        exit 1
    fi

    EXAMPLE_EXE_PATH="$BUILD_PATH/chip-openiotsdk-$EXAMPLE-example.elf"

    # Check if executable file exists
    if ! [ -f "$EXAMPLE_EXE_PATH" ]; then
        echo "Error: $EXAMPLE_EXE_PATH does not exist." >&2
        exit 1
    fi

    OPTIONS="-C mps3_board.telnetterminal0.start_port=$TELNET_TERMINAL_PORT --quantum=25"

    if $DEBUG; then
        OPTIONS="${OPTIONS} --allow-debug-plugin --plugin $GDB_PLUGIN"
    fi

    if [[ $FVP_NETWORK == "user" ]]; then
        OPTIONS="${OPTIONS} -C mps3_board.hostbridge.userNetworking=1"
    else
        OPTIONS="${OPTIONS} -C mps3_board.hostbridge.interfaceName=${FVP_NETWORK}"
    fi

    echo "Running $EXAMPLE_EXE_PATH with options: ${OPTIONS}"

    $FVP_BIN $OPTIONS -f $FVP_CONFIG_FILE --application $EXAMPLE_EXE_PATH >/dev/null 2>&1 &
    FVP_PID=$!
    sleep 1
    telnet localhost ${TELNET_TERMINAL_PORT}

    # stop the fvp
    kill -9 $FVP_PID || true
    sleep 1
}

function run_test {

    EXAMPLE_EXE_PATH="$BUILD_PATH/chip-openiotsdk-$EXAMPLE-example.elf"
    # Check if executable file exists
    if ! [ -f "$EXAMPLE_EXE_PATH" ]; then
        echo "Error: $EXAMPLE_EXE_PATH does not exist." >&2
        exit 1
    fi

    # Check if FVP exists
    if ! [ -x "$(command -v ${FVP_BIN})" ]; then
        echo "Error: $FVP_BIN not installed." >&2
        exit 1
    fi

    # Activate Matter environment with pytest
    source "$CHIP_ROOT"/scripts/activate.sh

    # Check if pytest exists
    if ! [ -x "$(command -v pytest)" ]; then
        echo "Error: pytest not installed." >&2
        exit 1
    fi

    OPTIONS=""

    if [[ $FVP_NETWORK ]]; then
        OPTIONS="${OPTIONS} --networkInterface=${FVP_NETWORK}"
    fi

    if [[ -f $EXAMPLE_TEST_PATH/$EXAMPLE/test_report.json ]]; then
        rm -rf $EXAMPLE_TEST_PATH/$EXAMPLE/test_report.json
    fi

    set +e
    pytest --json-report --json-report-summary --json-report-file=$EXAMPLE_TEST_PATH/$EXAMPLE/test_report.json --binaryPath=$EXAMPLE_EXE_PATH --fvp=$FVP_BIN --fvpConfig=$FVP_CONFIG_FILE $OPTIONS $EXAMPLE_TEST_PATH/$EXAMPLE/test_app.py
    set -e

    if [[ ! -f $EXAMPLE_TEST_PATH/$EXAMPLE/test_report.json ]]; then
        exit 1
    else
        if [[ $(jq '.summary | has("failed")' $EXAMPLE_TEST_PATH/$EXAMPLE/test_report.json) == true ]]; then
            FAILED_TESTS=$(jq '.summary.failed' $EXAMPLE_TEST_PATH/$EXAMPLE/test_report.json)
        fi
    fi
}

SHORT=C:,p:,d:.n:,c,s,h
LONG=command:,path:,debug:.network:,clean,scratch,help
OPTS=$(getopt -n build --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :; do
    case "$1" in
    -h | --help)
        show_usage
        exit 0
        ;;
    -c | --clean)
        CLEAN=1
        shift
        ;;
    -s | --scratch)
        SCRATCH=1
        shift
        ;;
    -C | --command)
        COMMAND=$2
        shift 2
        ;;
    -d | --debug)
        DEBUG=$2
        shift 2
        ;;
    -p | --path)
        BUILD_PATH=$CHIP_ROOT/$2
        shift 2
        ;;
    -n | --network)
        FVP_NETWORK=$2
        shift 2
        ;;
    -* | --*)
        shift
        break
        ;;
    *)
        echo "Unexpected option: $1"
        show_usage
        exit 2
        ;;
    esac
done

if [[ $# -lt 1 ]]; then
    show_usage >&2
    exit 1
fi

case "$1" in
shell | lock-app)
    EXAMPLE=$1
    ;;
*)
    echo "Wrong example name"
    show_usage
    exit 2
    ;;
esac

case "$COMMAND" in
build | run | test | build-run) ;;
*)
    echo "Wrong command definition"
    show_usage
    exit 2
    ;;
esac

TOOLCHAIN_PATH="toolchains/toolchain-$TOOLCHAIN.cmake"
EXAMPLE_PATH="$CHIP_ROOT/examples/$EXAMPLE/openiotsdk"

if [ -z "${BUILD_PATH}" ]; then
    BUILD_PATH="$EXAMPLE_PATH/build"
fi

if [[ "$COMMAND" == *"build"* ]]; then
    build_with_cmake
fi

if [[ "$COMMAND" == *"run"* ]]; then
    run_fvp
fi

if [[ "$COMMAND" == *"test"* ]]; then
    IS_TEST=1
    run_test
fi

if [[ $IS_TEST -eq 1 ]]; then
    exit $FAILED_TESTS
fi