/*
 *
 *    Copyright (c) 2022 Project CHIP Authors
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

/**
 *    @file
 *      Source implementation of an input / output stream for Corstone platform.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/unistd.h>

#include <lib/shell/streamer.h>

namespace chip {
namespace Shell {

int streamer_corstone_init(streamer_t * streamer)
{
    (void) streamer;
    return 0;
}

ssize_t streamer_corstone_read(streamer_t * streamer, char * buf, size_t len)
{
    (void) streamer;
    return read(STDIN_FILENO, buf, len);
}

ssize_t streamer_corstone_write(streamer_t * streamer, const char * buf, size_t len)
{
    (void) streamer;
    return write(STDOUT_FILENO, buf, len);
}

static streamer_t streamer_corstone = {
    .init_cb  = streamer_corstone_init,
    .read_cb  = streamer_corstone_read,
    .write_cb = streamer_corstone_write,
};

streamer_t * streamer_get()
{
    return &streamer_corstone;
}

} // namespace Shell
} // namespace chip
