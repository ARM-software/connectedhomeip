# Copyright (c) 2022 Project CHIP Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import shlex
from enum import Enum, auto

from .builder import Builder


class CorstoneApp(Enum):
    SHELL = auto()
    LOCK = auto()

    @property
    def ExampleName(self):
        if self == CorstoneApp.SHELL:
            return 'shell'
        elif self == CorstoneApp.LOCK:
            return 'lock-app'
        else:
            raise Exception('Unknown app type: %r' % self)

    @property
    def AppNamePrefix(self):
        if self == CorstoneApp.SHELL:
            return 'chip-corstone-shell-example'
        elif self == CorstoneApp.LOCK:
            return 'chip-corstone-lock-app-example'
        else:
            raise Exception('Unknown app type: %r' % self)


class CorstoneCryptoBackend(Enum):
    PSA = auto()
    MBEDTLS = auto()

    @property
    def CryptoBackendName(self):
        if self == CorstoneCryptoBackend.PSA:
            return 'psa'
        elif self == CorstoneCryptoBackend.MBEDTLS:
            return 'mbedtls'
        else:
            raise Exception('Unknown crypto backend type: %r' % self)


class CorstoneBuilder(Builder):
    def __init__(self,
                 root,
                 runner,
                 app: CorstoneApp = CorstoneApp.SHELL,
                 crypto: CorstoneCryptoBackend = CorstoneCryptoBackend.MBEDTLS):
        super(CorstoneBuilder, self).__init__(root, runner)
        self.app = app
        self.crypto = crypto
        self.toolchain_path = os.path.join(
            'toolchains', 'toolchain-arm-none-eabi-gcc.cmake')
        self.system_processor = 'cortex-m55'

    @property
    def ExamplePath(self):
        return os.path.join(self.root, 'examples', self.app.ExampleName, 'corstone')

    def generate(self):
        if not os.path.exists(self.output_dir):
            self._Execute(['cmake', '-GNinja', '-S', shlex.quote(self.ExamplePath), '-B', shlex.quote(self.output_dir),
                           '--toolchain={}'.format(
                               shlex.quote(self.toolchain_path)),
                           '-DCMAKE_SYSTEM_PROCESSOR={}'.format(
                               self.system_processor),
                           '-DCMAKE_BUILD_TYPE=Release',
                           '-DCONFIG_CHIP_CRYPTO={}'.format(
                               self.crypto.CryptoBackendName),
                           ], title='Generating ' + self.identifier)

    def _build(self):
        self._Execute(['cmake', '--build', shlex.quote(self.output_dir)],
                      title='Building ' + self.identifier)

    def build_outputs(self):
        return {
            self.app.AppNamePrefix + '.elf':
                os.path.join(self.output_dir, self.app.AppNamePrefix + '.elf'),
            self.app.AppNamePrefix + '.map':
                os.path.join(self.output_dir,
                             self.app.AppNamePrefix + '.map'),
        }
