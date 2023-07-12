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

import asyncio
import logging
import re

from pyedmgr import TestDevice

from .device import Device

log = logging.getLogger(__name__)


class PyedmgrDevice(Device):

    def __init__(self, device: TestDevice, name=None):
        super(PyedmgrDevice, self).__init__(name)
        self.device = device

    async def _read_line(self):
        line = await asyncio.wait_for(self.device.channel.readline_async(), timeout=0.2)
        if isinstance(line, bytes) or isinstance(line, bytearray):
            line = line.decode("utf-8", errors="replace").strip()
        return re.sub(r'\033\[((?:\d|;)*)([a-zA-Z])', '', line)

    async def _write(self, data):
        # FVPs are not great at handling serial overflows. Send character per character
        for b in data.encode('utf-8'):
            await asyncio.sleep(0.05)
            await self.device.channel.write_async(b.to_bytes(1, 'little'))
