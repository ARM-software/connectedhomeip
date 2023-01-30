# Matter Open IoT SDK Example Application

These examples are built using
[Open IoT SDK](https://gitlab.arm.com/iot/open-iot-sdk) and runs inside an
emulated target through the
[Arm FVP model for the Corstone-300 MPS3](https://developer.arm.com/downloads/-/arm-ecosystem-fvps).

You can use these examples as a reference for creating your own applications.

## Environment setup

Before building the examples, check out the Matter repository and sync
submodules using the following command:

```
$ git submodule update --init
```

The VSCode devcontainer has all the dependencies pre-installed. Using the VSCode
devcontainer is the recommended way to interact with the Open IoT SDK port of
the Matter Project. Please read this
[README.md](../../..//docs/VSCODE_DEVELOPMENT.md) for more information.

There are also some python packages that are required which are not provided as
part of the VSCode devcontainer. To install these run the following command from
the CLI:

```
${MATTER_ROOT}/scripts/run_in_build_env.sh './scripts/build_python.sh --install_wheel
build-env'
```

### Networking setup

Running ARM Fast Model with the TAP/TUN device networking mode requires the
setting up of proper network interfaces. Special scripts were designed to make
the setup easy. In the `scripts/setup/openiotsdk` directory you can find:

-   **network_setup.sh** - script to create the specific network namespace and
    Virtual Ethernet interface to connect with the host network. Both host and
    namespace sides have linked IP addresses. Inside the network namespace the
    TAP device interface is created and bridged with a Virtual Ethernet peer.
    There is also an option to enable an Internet connection in the namespace by
    forwarding traffic to the host default interface.

    To enable the Open IoT SDK networking environment:

    ```
    ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh up
    ```

    To disable the Open IoT SDK networking environment:

    ```
    ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh down
    ```

    To restart the Open IoT SDK networking environment:

    ```
    ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh restart
    ```

    The default scripts settings are:

    -   `ARM` - network base name
    -   `current session user` - network namespace user
    -   `fe00::1` - host side IPv6 address
    -   `fe00::2` - namespace side IPv6 address
    -   `10.200.1.1` - host side IPv4 address
    -   `10.200.1.2` - namespace side IPv4 address
    -   no Internet connection support to network namespace

    Example of the `OIS` network environment settings:

    ```
    ARMns namespace configuration
    ARMbr: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
            inet 10.200.1.2  netmask 255.255.255.0  broadcast 0.0.0.0
            inet6 fe00::2  prefixlen 64  scopeid 0x0<global>
            inet6 fe80::1809:17ff:fe6c:f566  prefixlen 64  scopeid 0x20<link>
            ether 1a:09:17:6c:f5:66  txqueuelen 1000  (Ethernet)
            RX packets 1  bytes 72 (72.0 B)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 0  bytes 0 (0.0 B)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

    ARMnveth: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
            ether 46:66:29:a6:91:4b  txqueuelen 1000  (Ethernet)
            RX packets 2  bytes 216 (216.0 B)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 3  bytes 270 (270.0 B)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

    ARMtap: flags=4419<UP,BROADCAST,RUNNING,PROMISC,MULTICAST>  mtu 1500
            ether 1a:09:17:6c:f5:66  txqueuelen 1000  (Ethernet)
            RX packets 0  bytes 0 (0.0 B)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 0  bytes 0 (0.0 B)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

    lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
            inet 127.0.0.1  netmask 255.0.0.0
            inet6 ::1  prefixlen 128  scopeid 0x10<host>
            loop  txqueuelen 1000  (Local Loopback)
            RX packets 0  bytes 0 (0.0 B)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 0  bytes 0 (0.0 B)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

    Host configuration
    ARMhveth: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
            inet 10.200.1.1  netmask 255.255.255.0  broadcast 0.0.0.0
            inet6 fe80::147c:c9ff:fe4a:c6d2  prefixlen 64  scopeid 0x20<link>
            inet6 fe00::1  prefixlen 64  scopeid 0x0<global>
            ether 16:7c:c9:4a:c6:d2  txqueuelen 1000  (Ethernet)
            RX packets 3  bytes 270 (270.0 B)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 2  bytes 216 (216.0 B)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
    ```

    Use `--help` to get more information about the script options.

-   **connect_if.sh** - script that connects specified network interfaces with
    the default route interface. It creates a bridge and links all interfaces to
    it. The bridge becomes the default interface.

    Example:

    ```
    ${MATTER_ROOT}/scripts/setup/openiotsdk/connect_if.sh ARMhveth
    ```

    Use `--help` to get more information about the script options.

Open IoT SDK network setup scripts contain commands that require root
permissions. Use `sudo` to run the scripts in a user account with root
privileges.

After setting up the Open IoT SDK network environment the user will be able to
run Matter examples on `FVP` in an isolated network namespace in TAP device
mode.

To execute a command in a specific network namespace use the helper script
`scripts/run_in_ns.sh`.

Example:

```
${MATTER_ROOT}/scripts/run_in_ns.sh ARMns <command to run>
```

Use `--help` to get more information about the script options.

**NOTE**

For Docker environment users it's recommended to use the
[default bridge network](https://docs.docker.com/network/bridge/#use-the-default-bridge-network)
for a running container. This guarantees full isolation of the Open IoT SDK
network from host settings.

### Debugging setup

Debugging the Matter application running on `FVP` model requires GDB Remote
Connection Plugin for Fast Model. More details
[GDBRemoteConnection](https://developer.arm.com/documentation/100964/1116/Plug-ins-for-Fast-Models/GDBRemoteConnection).

The Third-Party IP add-on package can be downloaded from the ARM developer
website [Fast models](https://developer.arm.com/downloads/-/fast-models). THe
currently required version is `11.16`.

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
    into the `/opt/FastModelsPortfolio_11.16` directory in the container.

    The Vscode devcontainer users should add a volume bound to this directory
    [Add local file mount](https://code.visualstudio.com/remote/advancedcontainers/add-local-file-mount).

    You can edit the `.devcontainer/devcontainer.json` file, for example:

    ```
    ...
    "mounts": [
        ...
        "source=/opt/FastModelsPortfolio_11.16,target=/opt/FastModelsPortfolio_11.16,type=bind,consistency=cached"
        ...
    ],
    ...
    ```

    In this case, the FAST MODEL PLUGINS PATH environment variable is already
    created.

    If you launch the Docker container directly from CLI, use the above
    arguments with `docker run` command. Remember to add the GDB plugin path to
    the environment variable as FAST_MODEL_PLUGINS_PATH inside container.

## Building

You can build by using a VSCode task or by calling the script directly from the
command line.

### Building using the VSCode task

```
Command Palette (F1)
=> Run Task...
=> Build Open IoT SDK example
=> Use debug mode (True/False)
=> Choose crypto algorithm (mbedtls/psa)
=> Choose socket API (iotsocket/lwip)
=> <example name>
```

This will call the script with the selected parameters.

### Building using CLI

You can call the script directly yourself.

```
${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh <example name>
```

Use `--help` to get more information about the script options.

## Running

The application runs in the background and opens a telnet session. The script
will open telnet for you and connect to the port used by the `FVP`. When the
telnet process is terminated it will also terminate the `FVP` instance.

You can run the application script from a VSCode task or call the script
directly.

### Running using the VSCode task

```
Command Palette (F1)
=> Run Task...
=> Run Open IoT SDK example
=> (network namespace)
=> (network interface)
=> <example name>
```

This will call the script with the selected example name.

### Running using CLI

You can call the script directly yourself.

```
${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -C run <example name>
```

Run example in specific network namespace with TAP device mode:

```
${MATTER_ROOT}/scripts/run_in_ns.sh ARMns ${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -C run -n ARMtap <example name>
```

### Commissioning

Once booted the application can be commissioned, please refer to
[docs/guides/openiotsdk_commissioning.md](/../guides/openiotsdk_commissioning.md)
for further instructions.

## Testing

Run the Pytest integration test for the specific application.

The test result can be found in the
`src/test_driver/openiotsdk/integration-tests/<example name>/test_report.json`
file.

You can run the tests using a VSCode task or call the script directly from the
command line.

### Testing using the VSCode task

```
Command Palette (F1)
=> Run Task...
=> Test Open IoT SDK example
=> (network namespace)
=> (network interface)
=> <example name>
```

This will call the scripts with the selected example name.

### Testing using CLI

You can call the script directly yourself.

```
${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -C test <example name>
```

Testing an example in a specific network namespace with TAP device mode:

```
${MATTER_ROOT}/scripts/run_in_ns.sh ARMns ${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -C test -n ARMtap <example name>
```

## Debugging

Before debugging ensure the following:

1. You have set up the debug environment correctly [Debugging setup](#debugging
   -setup).

2. The example you wish to debug has been compiled with debug symbols enabled:

    For CLI:

```
   `${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -d true <example name>`
```

For the VSCode task:

```
    `=> Use debug mode (True)`
```

3. You have set up the test network (if required) correctly
   [Networking setup](#networking-setup).

### General instructions

```
1. Click 'Run and Debug' from the primary side menu or press (Ctrl+Shift+D)
2. Select 'Debug Open IoT SDK example application' from the drop down list
3. Click 'Start Debugging'(green triangle) or press (F5)
4. Enter:
=> <example name>
=> (GDB target address)
=> (network namespace)
=> (network interface)
=> <example name>
```

For debugging remote targets (i.e. run in other network namespaces) you need to
pass the hostname/IP address of the external GDB target that you want to connect
to (_GDB target address_). In the case of using the
[Open IoT SDK network environment](#networking-setup) the GDB server runs inside
a namespace and has the same IP address as the bridge interface.

```
${MATTER_ROOT}/scripts/run_in_ns.sh <namespace_name> ifconfig <bridge_name>
```

**NOTES**

As you can see above, you will need to select the name of the example twice.
This is because the debug task needs to launch the run task and currently VS
code has no way of passing parameters between tasks.

There are issues with debugging examples if you happen to be using
"--network=host" in your docker container configuration and you are trying to
debug while connected to a VPN. The easiest solution is just to come off the VPN
while debugging.

## Specific examples

### Build and run the lock-app example using the CLI

```
${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -s -b psa -S lwip lock-app
```

```
export TEST_NETWORK_NAME=OIStest
```

```
sudo ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh -n $TEST_NETWORK_NAME restart
```

```
${MATTER_ROOT}/scripts/examples/scripts/run_in_ns.sh ${TEST_NETWORK_NAME}ns
scripts/examples/openiotsdk_example.sh -C run -n ${TEST_NETWORK_NAME}tap
lock-app
```

### Build and run the lock-app example using the VSCode task

```
Command Palette (F1), type: tasks <return>
=> Build Open IoT SDK example
=> Use debug mode (False)
=> Crypto algorithm to use (psa)
=> Socket API to use (iotsocket)
=> Example application to use (lock-app)
```

In CLI:

```
export TEST_NETWORK_NAME=OIStest
```

```
sudo ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh -n $TEST_NETWORK_NAME restart
```

```
Command Palette (F1), type: tasks <return>
=> Run Open IoT SDK example
=> Network namespace:  OIStestns
=> Network interface name: OIStesttap
=> Example application to use (lock-app)
```

The example output should be seen in the terminal window.

### Build and test the lock-app example using the VSCode task

In CLI:

```
export TEST_NETWORK_NAME=OIStest
```

```
sudo ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh -n $TEST_NETWORK_NAME restart
```

```
Command Palette (F1), type: tasks <return>
=> Test Open IoT SDK example
=> Network namespace:  OIStestns
=> Network interface name: OIStesttap
=> Example application to use (lock-app)
```

### Build and test the lock-app example using the CLI

In CLI:

```
export TEST_NETWORK_NAME=OIStest
```

```
sudo ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh -n $TEST_NETWORK_NAME restart
```

```
${MATTER_ROOT}/scripts/examples/openiotsdk_example.sh -C test lock-app
```

### Build and debug the lock-app example using the VSCode task

```
Command Palette (F1), type: tasks <return>
=> Build Open IoT SDK example
=> Use debug mode (True)
=> Crypto algorithm to use (psa)
=> Socket API to use (iotsocket)
=> Example application to use (lock-app)
```

In CLI:

```
export TEST_NETWORK_NAME=OIStest
```

```
sudo ${MATTER_ROOT}/scripts/setup/openiotsdk/network_setup.sh -n $TEST_NETWORK_NAME restart
```

```
Click 'Run and Debug' from the primary side menu or press (Ctrl+Shift+D)
Select 'Debug Open IoT SDK example application' from the drop down list
Click 'Start Debugging'(green triangle) or press (F5)
Enter:
=> lock-app
=> GDB target address: 10.200.1.2
=> Network namespace: OIStestns
=> Network interface name: OIStesttap
=> Example application to use (lock-app)

Use debug controls
```
