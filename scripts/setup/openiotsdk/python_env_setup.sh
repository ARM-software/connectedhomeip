#!/bin/bash

#
#    Copyright (c) 2022 Project CHIP Authors
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

# Setup Python environment.

NAME="$(basename "$0")"
HERE="$(dirname "$0")"
CHIP_ROOT="$(realpath "$HERE"/../../..)"
VENV_PATH=""
CONTROLLER_INSTALL=0

function show_usage() {
    cat <<EOF
Usage: $0 [options]

Setup Open IoT SDK Python environment.

Options:
    -h,--help                           Show this help
    -p,--path    <venv_path>            Create a virtual environment in the <venv_path> directory <venv_path - default is empty which means extend Matter environment>
    --controller                        Install the Matter Python controller
EOF
}

function controller_install() {
    "$CHIP_ROOT"/scripts/build_python.sh --install_virtual_env "$VENV_PATH" --clean_virtual_env no
}

SHORT=p:,h
LONG=path:,controller,help
OPTS=$(getopt -n build --options "$SHORT" --longoptions "$LONG" -- "$@")

eval set -- "$OPTS"

while :; do
    case "$1" in
        -h | --help)
            show_usage
            exit 0
            ;;
        -p | --path)
            VENV_PATH=$2
            shift 2
            ;;
        --controller)
            CONTROLLER_INSTALL=1
            shift
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

source "$CHIP_ROOT/scripts/activate.sh"

if [ -n "$VENV_PATH" ]; then
    virtualenv "$VENV_PATH"
    source "$VENV_PATH/bin/activate"
else
    VENV_PATH=$VIRTUAL_ENV
fi

if [[ $CONTROLLER_INSTALL -ne 0 ]]; then
    echo "Install the Matter Python controller" >&2
    controller_install
fi

pip install -r "$CHIP_ROOT"/scripts/setup/requirements.openiotsdk.txt
