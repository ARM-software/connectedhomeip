#
#    Copyright (c) 2022 Project CHIP Authors
#    All rights reserved.
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

import asyncio
import logging
import os
import pathlib
import shutil

import chip.CertificateAuthority
import chip.native
import nest_asyncio
import pytest
import pytest_asyncio
from chip import exceptions
from common.pyedmgr_device import PyedmgrDevice
from common.terminal_device import TerminalDevice
from pyedmgr import TestCase, TestCaseContext

log = logging.getLogger(__name__)

nest_asyncio.apply()


def pytest_addoption(parser):
    """
    Function for pytest to enable own custom commandline arguments
    :param parser: argparser
    :return:
    """
    parser.addoption('--binaryPath', action='store',
                     help='Application binary path')
    parser.addoption('--fvp', action='store',
                     help='FVP instance path')
    parser.addoption('--fvpConfig', action='store',
                     help='FVP configuration file path')
    parser.addoption('--telnetPort', action='store',
                     help='Telnet terminal port number.', default="5000")
    parser.addoption('--networkInterface', action='store',
                     help='FVP network interface name')
    parser.addoption('--updateBinaryPath', action='store',
                     help='Application update binary path')
    parser.addoption('--otaProvider', action='store',
                     help='Path to OTA provider application')
    parser.addoption('--softwareVersion', action='store',
                     help='Software version of update image in the format <number>:<x.x.x> eg. 1:0.0.01')


# Note redefine fixture from pytest-syncio to have scope session
@pytest.fixture(scope="session")
def event_loop():
    policy = asyncio.get_event_loop_policy()
    loop = policy.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
def rootDir():
    return pathlib.Path(__file__).parents[4].absolute()


@pytest.fixture(scope="session")
def fvp(request):
    if request.config.getoption('fvp'):
        return request.config.getoption('fvp')
    else:
        return shutil.which('FVP_Corstone_SSE-300_Ethos-U55')


@pytest.fixture(scope="session")
def fvpConfig(request, rootDir):
    if request.config.getoption('fvpConfig'):
        return request.config.getoption('fvpConfig')
    else:
        return os.path.join(rootDir, 'config/openiotsdk/fvp/cs300.conf')


@pytest.fixture(scope="session")
def networkInterface(request):
    if request.config.getoption('networkInterface'):
        return request.config.getoption('networkInterface')
    else:
        return None


@pytest.fixture(scope="session")
def otaProvider(request, rootDir):
    if request.config.getoption('otaProvider'):
        return request.config.getoption('otaProvider')
    else:
        return os.path.join(rootDir, 'out/chip-ota-provider-app')


@pytest.fixture(scope="session")
def softwareVersion(request):
    if request.config.getoption('softwareVersion'):
        version = request.config.getoption('softwareVersion')
        params = version.split(':')
        return (params[0], params[1])
    else:
        return ("1", "0.0.1")


@pytest.fixture
def pyedmgrConfig(
    fvp,
    fvpConfig,
    networkInterface,
    binaryPath,
):
    args = ["-C", "mps3_board.telnetterminal0.mode=raw"]

    if networkInterface in (None, "", "user"):
        args.extend(("-C", "mps3_board.hostbridge.userNetworking=1"))
    else:
        args.extend(("-C", f"mps3_board.hostbridge.interfaceName={networkInterface}"))

    return {
        fvp: {
            "firmware": [binaryPath],
            "args": args,
            "config": fvpConfig,
        }
    }


@pytest.mark.asyncio
@pytest_asyncio.fixture(scope="function")
async def pyedmgrContext(pyedmgrConfig) -> TestCaseContext:
    for case in TestCase.parse(pyedmgrConfig):
        async with case as context:
            yield context


@pytest.mark.asyncio
@pytest_asyncio.fixture(scope="function")
async def device(pyedmgrContext: TestCaseContext) -> PyedmgrDevice:
    device: PyedmgrDevice = PyedmgrDevice(pyedmgrContext.allocated_devices[0], name="FVPdev")
    await device.start()
    yield device
    await device.stop()


@pytest.fixture(scope="session")
def controller(controllerConfig):
    try:
        chip.native.Init()
        chipStack = chip.ChipStack.ChipStack(
            persistentStoragePath=controllerConfig['persistentStoragePath'], enableServerInteractions=False)
        certificateAuthorityManager = chip.CertificateAuthority.CertificateAuthorityManager(
            chipStack, chipStack.GetStorageManager())
        certificateAuthorityManager.LoadAuthoritiesFromStorage()
        if (len(certificateAuthorityManager.activeCaList) == 0):
            ca = certificateAuthorityManager.NewCertificateAuthority()
            ca.NewFabricAdmin(vendorId=controllerConfig['vendorId'], fabricId=controllerConfig['fabricId'])
        elif (len(certificateAuthorityManager.activeCaList[0].adminList) == 0):
            certificateAuthorityManager.activeCaList[0].NewFabricAdmin(
                vendorId=controllerConfig['vendorId'], fabricId=controllerConfig['fabricId'])

        caList = certificateAuthorityManager.activeCaList

        devCtrl = caList[0].adminList[0].NewController()

    except exceptions.ChipStackException as ex:
        log.error("Controller initialization failed {}".format(ex))
        return None
    except Exception:
        log.error("Controller initialization failed")
        return None

    yield devCtrl

    devCtrl.Shutdown()
    certificateAuthorityManager.Shutdown()
    chipStack.Shutdown()
    os.remove(controllerConfig['persistentStoragePath'])


@pytest.mark.asyncio
@pytest_asyncio.fixture(scope="session")
async def ota_provider(otaProvider, otaProviderConfig):
    args = [
        '--discriminator', otaProviderConfig['discriminator'],
        '--secured-device-port',  otaProviderConfig['port'],
        '-c',
        '--KVS', otaProviderConfig['persistentStoragePath'],
        '--filepath', otaProviderConfig['filePath'],
    ]

    device = TerminalDevice(otaProvider, args, "OTAprovider")
    await device.start()

    yield device

    await device.stop()
    os.remove(otaProviderConfig['persistentStoragePath'])
