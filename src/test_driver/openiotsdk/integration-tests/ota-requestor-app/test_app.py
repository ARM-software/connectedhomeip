#
#    Copyright (c) 2023 Project CHIP Authors
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

import pytest
from time import sleep

from common.utils import *
import asyncio

from chip.clusters.Types import NullValue
from chip.clusters.Objects import OtaSoftwareUpdateRequestor
import chip.interaction_model as IM

from chip.clusters import Objects as GeneratedObjects

import logging
log = logging.getLogger(__name__)


@pytest.fixture(scope="session")
def binaryPath(request, rootDir):
    if request.config.getoption('binaryPath'):
        return request.config.getoption('binaryPath')
    else:
        return os.path.join(rootDir, 'examples/ota-requestor-app/openiotsdk/build/chip-openiotsdk-ota-requestor-app-example.elf')


@pytest.fixture(scope="session")
def updateBinaryPath(request, rootDir):
    if request.config.getoption('updateBinaryPath'):
        return request.config.getoption('updateBinaryPath')
    else:
        return os.path.join(rootDir, 'examples/ota-requestor-app/openiotsdk/build/chip-openiotsdk-ota-requestor-app-example.ota')


@pytest.fixture(scope="session")
def controllerConfig(request):
    config = {
        'vendorId': 0xFFF1,
        'fabricId': 1,
        'persistentStoragePath': '/tmp/openiotsdk-test-storage.json'
    }
    return config


@pytest.fixture(scope="session")
def otaProviderConfig(request, updateBinaryPath):
    config = {
        'discriminator': '3841',
        'port': '5580',
        'filePath': f'{updateBinaryPath}',
        'persistentStoragePath': '/tmp/openiotsdk-test-ota-provider.json'
    }
    return config


@pytest.mark.smoketest
def test_smoke_test(device):
    ret = device.wait_for_output("Open IoT SDK ota-requestor-app example application start")
    assert ret != None and len(ret) > 0
    ret = device.wait_for_output("Open IoT SDK ota-requestor-app example application run")
    assert ret != None and len(ret) > 0


@pytest.mark.commissioningtest
def test_commissioning(device, controller):
    assert controller != None
    devCtrl = controller

    setupPayload = get_setup_payload(device)
    assert setupPayload != None

    commissionable_device = discover_device(devCtrl, setupPayload)
    assert commissionable_device != None

    assert commissionable_device.vendorId == int(setupPayload.attributes['VendorID'])
    assert commissionable_device.productId == int(setupPayload.attributes['ProductID'])
    assert commissionable_device.addresses[0] != None

    nodeId = connect_device(devCtrl, setupPayload, commissionable_device)
    assert nodeId != None
    log.info("Device {} connected".format(commissionable_device.addresses[0]))

    ret = device.wait_for_output("Commissioning completed successfully")
    assert ret != None and len(ret) > 0

    assert disconnect_device(devCtrl, nodeId)


OTA_REQUESTOR_CTRL_TEST_ENDPOINT_ID = 0


@pytest.mark.ctrltest
def test_update_ctrl(device, controller, ota_provider, softwareVersion):
    assert controller != None
    devCtrl = controller
    version_number, version_str = softwareVersion

    log.info("Setup OTA provider...")

    # Get OTA provider setup payload
    setupPayloadProvider = get_setup_payload(ota_provider)
    assert setupPayloadProvider != None

    # Discover and commission the OTA provider
    commissionable_provider_device = discover_device(devCtrl, setupPayloadProvider)
    assert commissionable_provider_device != None

    providerNodeId = connect_device(devCtrl, setupPayloadProvider, commissionable_provider_device)
    assert providerNodeId != None

    ret = ota_provider.wait_for_output("Commissioning completed successfully")
    assert ret != None and len(ret) > 0

    log.info("OTA provider ready")
    log.info("Setup OTA requestor...")

    # Get OTA requestor setup payload
    setupPayload = get_setup_payload(device)
    assert setupPayload != None

    # Discover and commission the OTA requestor
    commissionable_requestor_device = discover_device(devCtrl, setupPayload)
    assert commissionable_requestor_device != None

    requestorNodeId = connect_device(devCtrl, setupPayload, commissionable_requestor_device)
    assert requestorNodeId != None

    ret = device.wait_for_output("Commissioning completed successfully")
    assert ret != None and len(ret) > 0

    log.info("OTA requestor ready")
    log.info("Install ACL entries")

    #  Install necessary ACL entries in OTA provider to enable access by OTA requestor
    err, res = write_zcl_attribute(devCtrl, "AccessControl", "Acl", providerNodeId,  OTA_REQUESTOR_CTRL_TEST_ENDPOINT_ID,
                                   [{"fabricIndex": 1, "privilege": 5, "authMode": 2, "subjects": [requestorNodeId], "targets": NullValue},
                                    {"fabricIndex": 1, "privilege": 3, "authMode": 2, "subjects": NullValue, "targets": [{"cluster": 41, "endpoint": NullValue, "deviceType": NullValue}]}])
    assert err == 0
    assert res[0].Status == IM.Status.Success

    ota_provider.set_verbose(False)

    log.info("Announce the OTA provider and start the firmware update process")

    # Announce the OTA provider and start the firmware update process
    err, res = send_zcl_command(devCtrl, "OtaSoftwareUpdateRequestor", "AnnounceOtaProvider", requestorNodeId, OTA_REQUESTOR_CTRL_TEST_ENDPOINT_ID,
                                dict(providerNodeId=providerNodeId, vendorId=int(setupPayloadProvider.attributes['VendorID']),
                                     announcementReason=OtaSoftwareUpdateRequestor.Enums.OTAAnnouncementReason.kUrgentUpdateAvailable,
                                     metadataForNode=None, endpoint=0))

    ret = device.wait_for_output("New version of the software is available")
    assert ret != None and len(ret) > 1

    version = ret[-1].split()[-1]
    assert version_number == version

    device.set_verbose(False)

    log.info("New software image downloading and installing...")

    ret = device.wait_for_output("Open IoT SDK ota-requestor-app example application start", timeout=600)
    assert ret != None and len(ret) > 0

    device.set_verbose(True)

    ret = device.wait_for_output("Current software version")
    assert ret != None and len(ret) > 1

    version_app = ret[-1].split()[-2:]
    assert version_number == re.sub(r"[\[\]]", "", version_app[0])
    assert version_str == version_app[1]

    assert disconnect_device(devCtrl, requestorNodeId)
    assert disconnect_device(devCtrl, providerNodeId)
