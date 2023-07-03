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

import logging
import os
import pathlib
import shutil

import chip.CertificateAuthority
import chip.native
import pytest
import pytest_asyncio
import nest_asyncio

from chip import exceptions

from .pyedmgr_device import PyedmgrDevice
from pyedmgr import TestCase, TestCaseContext

from .terminal_device import TerminalDevice

log = logging.getLogger(__name__)

nest_asyncio.apply()


@pytest.fixture(scope="session")
def rootDir():
    return pathlib.Path(__file__).parents[5].absolute()


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
def gdbPlugin(pytestconfig):
    yield pytestconfig.getoption("--gdbPlugin")


@pytest.fixture
def kvsFile(pytestconfig):
    yield pytestconfig.getoption("--kvsFile")


@pytest.fixture
def storageParam():
    yield dict(instance="qspi_sram", memspace=0, address=0x660000, size=0x12000)


@pytest.fixture
def pyedmgrConfig(
    fvp,
    fvpConfig,
    networkInterface,
    gdbPlugin,
    kvsFile,
    storageParam,
    binaryPath,
):
    args = []

    if gdbPlugin:
        args.extend(("--allow-debug-plugin", "--plugin", gdbPlugin))

    if networkInterface in (None, "", "user"):
        args.extend(("-C", "mps3_board.hostbridge.userNetworking=1"))
    else:
        args.extend(("-C", f"mps3_board.hostbridge.interfaceName={networkInterface}"))

    if kvsFile:
        if os.path.isfile(kvsFile):
            args.extend(
                (
                    "--data",
                    "mps3_board.{}={}@{}:{}".format(
                        storageParam["instance"],
                        kvsFile,
                        storageParam["memspace"],
                        storageParam["address"],
                    ),
                )
            )
        args.extend(
            (
                "--dump",
                "mps3_board.{}={}@{}:{},{}".format(
                    storageParam["instance"],
                    kvsFile,
                    storageParam["memspace"],
                    storageParam["address"],
                    storageParam["size"],
                ),
            )
        )

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
