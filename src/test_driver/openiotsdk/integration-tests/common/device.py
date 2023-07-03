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
import asyncio
from time import time
import traceback
from typing import List, Optional

log = logging.getLogger(__name__)


class Device:

    def __init__(self, name: Optional[str] = None):
        """
        Base Device runner class containing device handling functions and logging
        :param name: Logging name for the client
        """
        self.verbose = True
        self.run = False
        self.iq = asyncio.Queue()
        self.oq = asyncio.Queue()
        if name is None:
            self.name = str(hex(id(self)))
        else:
            self.name = name

    async def send(self, command, expected_output=None, wait_before_read=None, wait_for_response=10, assert_output=True, suffix='\n'):
        """
        Send command for client
        :param command: Command
        :param expected_output: Reply to wait from the client
        :param wait_before_read: Timeout after write
        :param wait_for_response: Timeout waiting the response
        :param assert_output: Assert the fail situations to end the test run
        :return: If there's expected output then the response line is returned
        """
        log.debug('{}: Sending command to client: "{}"'.format(
            self.name, command))
        await self.flush(0)
        await self._push_data(f"{command}{suffix}")
        if expected_output is not None:
            if wait_before_read is not None:
                await asyncio.sleep(wait_before_read)
            return await self.wait_for_output(expected_output, wait_for_response, assert_output)

    async def flush(self, timeout: float = 0) -> List[str]:
        """
        Flush the lines in the input queue
        :param timeout: The timeout before flushing starts
        :type timeout: float
        :return: The lines removed from the input queue
        :rtype: list of str
        """
        await asyncio.sleep(timeout)
        lines = []
        while True:
            try:
                lines.append(self.iq.get_nowait())
            except asyncio.queues.QueueEmpty:
                return lines

    async def wait_for_output(self, search: str, timeout: float = 10, assert_timeout: bool = True, verbose: bool = False) -> [str]:
        """
        Wait for expected output response
        :param search: Expected response string
        :type search: str
        :param timeout: Response waiting time
        :type timeout: float
        :param assert_timeout: Assert on timeout situations
        :type assert_timeout: bool
        :return: Line received before a match
        :rtype: list of str
        """
        lines = []
        start = time()
        now = 0
        timeout_error_msg = '{}: Didn\'t find {} in {} s'.format(
            self.name, search, timeout)

        while time() - start <= timeout:
            try:
                line = await self._get_line(1)
                if line:
                    lines.append(line)
                    if search in line:
                        return lines

            except asyncio.exceptions.TimeoutError:
                last = now
                now = time()
                if now - start >= timeout:
                    if assert_timeout:
                        log.error(timeout_error_msg)
                        assert False, timeout_error_msg
                    else:
                        log.warning(timeout_error_msg)
                        return []
                if verbose and (now - last > 1):
                    log.info('{}: Waiting for "{}" string... Timeout in {:.0f} s'.format(self.name, search,
                                                                                         abs(now - start - timeout)))

    async def _push_data(self, data):
        await self.oq.put(data)

    async def _get_line(self, timeout):
        ret = await asyncio.wait_for(self.iq.get(), timeout=timeout)
        return ret

    async def start(self):
        """
        Start the device
        """
        await self._start()
        self.run = True
        self.input_task = asyncio.create_task(self._input_task())
        self.output_task = asyncio.create_task(self._output_task())

    async def _start(self):
        """
        start() customization point
        """
        pass

    async def stop(self):
        """
        Stop the the device
        """
        self.run = False
        self.input_task.cancel()
        self.input_task = None
        self.output_task.cancel()
        self.output_task = None
        await self._stop()

    async def _stop(self):
        """
        stop() customization point
        """
        pass

    def set_verbose(self, state: bool):
        self.verbose = state

    async def _input_task(self):
        while self.run:
            try:
                line = await self._read_line()
                if line:
                    if self.verbose:
                        log.info('<--|{}| {}'.format(self.name, line.strip()))
                    await self.iq.put(line)
                else:
                    pass
            except asyncio.exceptions.TimeoutError:
                continue
            except Exception as e:
                log.error(f"input thread ({self.name}) loop exception: {traceback.format_exception(e)}")
                continue

    async def _read_line(self):
        """
        Read a line out of the device. This is called from the input task
        """
        raise NotImplementedError("_read_line must be implemented for each device subclass")

    async def _output_task(self):
        while self.run:
            try:
                data: str = await asyncio.wait_for(self.oq.get(), timeout=0.2)
                if data:
                    await self._write(data)
                else:
                    log.debug('Nothing sent')
            except asyncio.exceptions.TimeoutError:
                continue
            except Exception as e:
                log.error(f"output thread ({self.name}) loop exception: {traceback.format_exception(e)}")
                continue

    async def _write(self, data):
        raise NotImplementedError("_write must be implemented for each device subclass")
