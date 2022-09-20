# Matter Open IoT SDK Example Application

These examples are built using
[Open IoT SDK](https://gitlab.arm.com/iot/open-iot-sdk) and runs inside an
emulated target through the
[Arm FVP model for the Corstone-300 MPS3](https://developer.arm.com/downloads/-/arm-ecosystem-fvps).

You can use these example as a reference for creating your own applications.

## Environment setup

Before building the examples, check out the Matter repository and sync
submodules using the following command:

```
$ git submodule update --init
```

The VSCode devcontainer has all dependencies pre-installed. Using the VSCode
devcontainer is the recommended way to interact with Open IoT SDK port of the
Matter Project. Please read this
[README.md](../../..//docs/VSCODE_DEVELOPMENT.md) for more information.

### Networking setup

Running ARM Fast Model with TAP/TUN device networking mode requires setup proper
network interfaces. Depending on development environment the following steps
should be performed:

-   host environment - follow steps from
    [Reference Manual](https://developer.arm.com/documentation/100964/1116/Introduction-to-the-Fast-Models-Reference-Manual/TAP-TUN-networking)
    to configuring the networking environment

-   Docker container environment

    Before running project inside the Docker container create a
    [macvlan network](https://docs.docker.com/network/macvlan/) in bridge mode.
    It is important that the subnet and gateway values need to match those of
    the Docker host network interface. Simply put, the subnet and default
    gateway for your macvlan network should mirror that of your Docker host.
    Also, remember about IPv6 support in your macvlan network.

    Example:

    ```
    docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 --ipv6 --subnet=fd12:41:e237:6905::/64 --gateway=fd12:41:e237:6905::11 -o parent=eth0 macvlan`
    ```

    The next step is to run Docker container and attach the macvlan network to
    it using the `--network` option. We can also assign the IP address to our
    container with `--ip`. Be sure to specify an IP that is not within your DHCP
    IP range to avoid instances of an IP conflict.

    It is also recommended to add IPv6 traffic forwarding configuration with
    `--sysctl` option.

    The Vscode devcontainer users should edit the
    `.devcontainer/devcontainer.json` file and add run options.

    Example:

    ```
    ...
    "runArgs": [
        ...
        "--network=macvlan",
        "--ip=192.168.1.110",
        "--sysctl",
        "net.ipv6.conf.all.disable_ipv6=0 net.ipv4.conf.all.forwarding=1 net.ipv6.conf.all.forwarding=1",
        ...
    ],
    ...
    ```

    If you launch the Docker container directly from CLI, use the above
    arguments with `docker run` command.

    To set up proper network interfaces inside Docker container use the designed
    script `scripts/setup/openiotsdk/network_setup.sh`. Select the main Ethernet
    interface that TAP device should be linked with `--network` option (the
    default value is **eth0**). To keep Internet access use the DHCP client
    `--dhcp`.

    To enable Open IoT SDK networking environment:

    ```
    ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh --network eth0 --dhcp up
    ```

    To disable Open IoT SDK networking environment:

    ```
    ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh --network eth0 --dhcp down
    ```

    Use `--help` to get more information about the script options.

    **NOTE**

    This option is limited to a Docker running on a Linux host as creating
    macvlan interface is not properly supported on other systems.

### Debugging setup

Debugging Matter application running on ARM FVP model requires GDB Remote
Connection Plugin for Fast Model. More details
[GDBRemoteConnection](https://developer.arm.com/documentation/100964/1116/Plug-ins-for-Fast-Models/GDBRemoteConnection).

The Third-Party IP add-on package can be downloaded from ARM developer website
[Fast models](https://developer.arm.com/downloads/-/fast-models). Currently
required version is `11.16`.

To install Fast Model Third-Party IP package:

-   unpack the installation package in a temporary location
-   execute the command `./setup.bin` (Linux) or `Setup.exe` (Windows), and
    follow the installation instructions.

After installation the GDB Remote Connection Plugin should be visible in
`FastModelsPortfolio_11.16/plugins` directory.

Then add the GDB plugin to your development environment:

-   host environment - add GDB plugin path to environment variable as
    FAST_MODEL_PLUGINS_PATH.

    Example

    ```
    export FAST_MODEL_PLUGINS_PATH=/opt/FastModelsPortfolio_11.16/plugins/Linux64_GCC-9.3
    ```

-   Docker container environment - mount the Fast Model Third-Party IP directory
    into the `/opt/FastModelsPortfolio_11.16` directory in container.

    The Vscode devcontainer users should edit the
    `.devcontainer/devcontainer.json` file and add run options.

    Example:

    ```
    ...
    "runArgs": [
        ...
        "-v",
        "/opt/FastModelsPortfolio_11.16:/opt/FastModelsPortfolio_11.16:ro",
        ...
    ],
    ...
    ```

    In this case, the FAST MODEL PLUGINS PATH environment variable is already
    created.

    If you launch the Docker container directly from CLI, use the above
    arguments with `docker run` command. Remember add GDB plugin path to
    environment variable as FAST_MODEL_PLUGINS_PATH inside container.

## Building

You build using a vscode task or call the script directly from the command line.

### Building using vscode task

```
Command Palette (F1) => Run Task... => Build Open IoT SDK example => (debug on/off) => <example name>
```

This will call the scripts with the selected parameters.

### Building using CLI

You can call the script directly yourself.

```
${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh <example name>
```

Use `--help` to get more information about the script options.

## Running

The application runs in the background and opens a telnet session. The script
will open telnet for you and connect to the port used by the FVP. When the
telnet process is terminated it will also terminate the FVP instance.

You can run the application script from a vscode task or call the script
directly.

### Running using vscode task

```
Command Palette (F1) => Run Task... => Run Open IoT SDK example => (network name) => <example name>
```

This will call the scripts with the selected example name.

### Running using CLI

You can call the script directly yourself.

```
${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -C run <example name>
```

### Commissioning

Once booted the application can be commissioned, please refer to
[docs/guides/openiotsdk_commissioning.md](/../guides/openiotsdk_commissioning.md)
for further instructions.

## Testing

Run the Pytest integration test for specific application.

The test result can be found in
`src/test_driver/openiotsdk/integration-tests/<example name>/test_report.json`
file.

You run testing using a vscode task or call the script directly from the command
line.

### Testing using vscode task

```
Command Palette (F1) => Run Task... => Test Open IoT SDK example => (network name) => <example name>
```

This will call the scripts with the selected example name.

### Testing using CLI

You can call the script directly yourself.

```
${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -C test <example name>
```

## Debugging

Debugging can be started using a VS code launch task:

```
Run and Debug (Ctrl+Shift+D) => Debug Open IoT SDK example application => Start Debugging (F5) => <example name> => (network name) => <example name>
```

As you can see above, you will need to select the name of the example twice.
This is because the debug task needs to launch the run task and currently VS
code has no way of passing parameters between tasks.
