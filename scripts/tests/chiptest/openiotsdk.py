#
#    Copyright (c) 2023 Project CHIP Authors
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

"""
Handles OIS-specific functionality for running test cases
"""

import logging
import os
import subprocess
import sys
import time
from typing import Optional
import netifaces

from .test_definition import ApplicationPaths

test_environ = os.environ.copy()

TEST_NETWORK_NAME="OIStest"
NETWORK_SETUP_SCRIPT_PATH=os.path.join(os.path.dirname(__file__), "../../setup/openiotsdk/network_setup.sh")


def _ensureNetworkNamespaceAvailability():
    if os.getuid() == 0:
        logging.debug("Current user is root")
        logging.warn("Running as root and this will change global namespaces.")
        return

    os.execvpe(
        "unshare", ["unshare", "--map-root-user", "-n", "-m", "python3",
                    sys.argv[0], '--internal-inside-unshare'] + sys.argv[1:],
        test_environ)


def _ensurePrivateState():
    logging.info("Ensuring /run is privately accessible")

    logging.debug("Making / private")
    if os.system("mount --make-private /") != 0:
        logging.error("Failed to make / private")
        logging.error("Are you using --privileged if running in docker?")
        sys.exit(1)

    logging.debug("Remounting /run")
    if os.system("mount -t tmpfs tmpfs /run") != 0:
        logging.error("Failed to mount /run as a temporary filesystem")
        logging.error("Are you using --privileged if running in docker?")
        sys.exit(1)


def _runCommands(*commands, stopOnFail=True):
    """Run a series of commands with os.system"""
    for command in commands:
        logging.debug("Executing '%s'" % command)
        if os.system(command) != 0:
            logging.error("Failed to execute '%s'" % command)
            logging.error("Are you using --privileged if running in docker?")
            if stopOnFail:
                sys.exit(1)


def _createNamespacesForAppTest():
    """
    Creates appropriate namespaces for a tool and app binaries in a simulated
    isolated network.
    """
    _runCommands("{} -n {} up".format(NETWORK_SETUP_SCRIPT_PATH, TEST_NETWORK_NAME))


def _destroyNamespaceForAppTest():
    """Revert the changes made by CreateNamespacesForAppTest"""
    _runCommands("{} -n {} down".format(NETWORK_SETUP_SCRIPT_PATH, TEST_NETWORK_NAME))


def PrepareNamespacesForTestExecution(in_unshare: bool):
    if not in_unshare:
        _ensureNetworkNamespaceAvailability()
    elif in_unshare:
        _ensurePrivateState()

    _createNamespacesForAppTest()


def ShutdownNamespaceForTestExecution():
    _destroyNamespaceForAppTest()


def _Prefixify(prefix:str, path:Optional[str]) -> str:
    '''Return path with prefix if path is not None, else return None.'''
    return prefix + path if path else None


def PathsWithNetworkNamespaces(paths: ApplicationPaths) -> ApplicationPaths:
    """
    Returns a copy of paths with updated command arrays to invoke the
    commands in an appropriate network namespace.
    """
    prefix = 'ip netns exec {}ns'.format(TEST_NETWORK_NAME).split()
    return ApplicationPaths(
        chip_tool=_Prefixify(prefix, paths.chip_tool),
        all_clusters_app=_Prefixify(prefix, paths.all_clusters_app),
        lock_app=_Prefixify(prefix, paths.lock_app),
        ota_provider_app=_Prefixify(prefix, paths.ota_provider_app),
        ota_requestor_app=_Prefixify(prefix, paths.ota_requestor_app),
        tv_app=_Prefixify(prefix, paths.tv_app),
        bridge_app=_Prefixify(prefix, paths.bridge_app),
        chip_repl_yaml_tester_cmd=_Prefixify(prefix, paths.chip_repl_yaml_tester_cmd),
    )


def GetInterfaceIpAddress() -> str:
    return netifaces.ifaddresses('{}hveth'.format(TEST_NETWORK_NAME))[netifaces.AF_INET][0]['addr']
