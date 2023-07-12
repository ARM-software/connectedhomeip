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
from asyncio.subprocess import Process

from .device import Device

log = logging.getLogger(__name__)


class TerminalDevice(Device):

    def __init__(self, app, args, name=None):
        super(TerminalDevice, self).__init__(name)
        self.cmd = [app] + args

    async def _start(self):
        self.proc: Process = await asyncio.create_subprocess_exec(*self.cmd, stdout=asyncio.subprocess.PIPE, stdin=asyncio.subprocess.PIPE)

    async def _stop(self):
        self.proc.stdin.close()
        self.proc.terminate()
        await self.proc.wait()

    async def _read_line(self):
        line = await asyncio.wait_for(self.proc.stdout.readline(), timeout=0.2)
        return line.decode('utf8')

    async def _write(self, data):
        await self.proc.stdin.write(data)
