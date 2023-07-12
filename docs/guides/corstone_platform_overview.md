# Corstone platform port

[ARM Corstone](https://www.arm.com/products/silicon-ip-subsystems) is a family
of semiconductor IP, which provides a foundation for developing SoCs
(System-on-Chips). The `Corstone IP` includes features such as the CPU core,
system controllers, memory interfaces, and peripherals, allowing developers to
build complex embedded systems. It is designed to provide a robust and scalable
platform for developing a wide range of applications, from low-power IoT devices
to high-performance automotive systems. `Corstone IPs` are highly configurable,
allowing system designers to tailor the IP blocks to meet their specific
requirements.

### Fixed Virtual Platforms

[Fixed Virtual Platforms (FVPs)](https://www.arm.com/products/development-tools/simulation/fixed-virtual-platforms)
are pre-configured, functionally accurate simulations of popular system
configurations, built with `Arm Fast Models`. They include all the key
components to enable development of large portions of software ahead of hardware
availability.

## Targets

Currently the [Corstone-300](https://developer.arm.com/Processors/Corstone-300)
is supported. The
[Arm Corstone SSE-300 FVP](https://developer.arm.com/documentation/100966/1122/Arm--Corstone-SSE-300-FVP)
model is used to simulate the real hardware target on the host machine.

## Building

Corstone examples uses CMake as its build system. To integrate with Matter's GN
build system our top level CMakeLists.txt generates GN configuration files that
pass on the required configs required by the GN build.

## Fixed Virtual Platforms network

The `FVP` has two network modes:

-   user mode networking - emulates a built-in IP router and DHCP server, and
    routes TCP and UDP traffic between the guest and host. It uses the user mode
    socket layer of the host to communicate with other hosts. See more details:
    [User mode networking](https://developer.arm.com/documentation/100964/1116/Introduction-to-the-Fast-Models-Reference-Manual/User-mode-networking)

-   TAP/TUN networking mode - set fast model to host bridge component which acts
    as a networking gateway to exchange Ethernet packets with the TAP device on
    the host, and to forward packets to model. See more details
    [TAP/TUN networking mode](https://developer.arm.com/documentation/100964/1116/Introduction-to-the-Fast-Models-Reference-Manual/TAP-TUN-networking)

Due the user mode limitations, the **TAP/TUN networking mode** is preferred for
implementing IP communication for a Matter project.

## Drivers

Drivers are provided by
[Reference MCU-Driver-HAL driver implementation for Arm platforms](https://gitlab.arm.com/iot/open-iot-sdk/mcu-driver-hal/mcu-driver-reference-platforms-for-arm).

## Clocks

Corstone `FVP` target does not currently offer an RTC. Matter configuration has
been set accordingly and real time cannot be read from the system.

Monotonic clocks are available and are based on system tick count. They are
limited by the target configuration. The current targets set the tick to 1 ms.
This becomes the lower bound for timers.

## RTOS

The Corstone platform uses
[CMSIS-RTOS2 API](https://www.keil.com/pack/doc/cmsis/RTOS2/html/group__CMSIS__RTOS.html)
as its RTOS API. It offers the choice of implementation between FreeRTOS or
CMSIS RTX but this is hidden below the API so your choice has no bearing on this
port and indeed your application may provide your own implementation entirely.

## Connectivity

The Corstone platform implementation currently only offers connectivity through
the Ethernet interface.

This means that commissioning is simplified since no provisioning is required to
provide the device with network credentials.

LWIP is used in the implementation of endpoints as the IP stack.

## Storage

The Corstone application uses
[Trusted Firmware-M](https://tf-m-user-guide.trustedfirmware.org) and
[TF-M Protected Storage Service](https://tf-m-user-guide.trustedfirmware.org/integration_guide/services/tfm_ps_integration_guide.html)
is used for persistence in secure memory. The `key-value` objects are stored in
a secure part of flash memory and the Protected Storage Service takes care of
their encryption and authentication.

---

**NOTE**

On `FVP` targets, memory content is lost after the program exits. To achieve
persistence memory regions used for the key-value storage must be saved when the
execution ends.

---

### Fixed Virtual Platforms persistent memory via files

Two command lines options can be used to achieve persistence of a specific
memory regions:

-   `--dump` store the content of a memory region into a file when the model
    ends its execution
-   `--data` load the content of a file into a specific memory region at startup

Use the `--list-memory` flag to see the list of instances and memory spaces for
your `FVP` model.

Visit the
[FVP command line documentation](https://developer.arm.com/documentation/100966/1116/Getting-Started-with-Fixed-Virtual-Platforms/FVP-command-line-options)
for more details about these flags.

Depending on your application, choose the right memory instance, memory space,
address and size.

## Trusted Firmware-M

[Trusted Firmware-M](https://tf-m-user-guide.trustedfirmware.org) (`TF-M`)
implements the Secure Processing Environment (`SPE`) for `Armv8-M`, `Armv8.1-M`
architectures and dual-core platforms. It is the platform security architecture
reference implementation aligning with `PSA` Certified guidelines, enabling
chips, Real Time Operating Systems and devices to become `PSA` Certified. `TF-M`
relies on an isolation boundary between the Non-secure Processing Environment
(`NSPE`) and the Secure Processing Environment (`SPE`).

`TF-M` consists of:

-   Secure Boot to authenticate `NSPE` and `SPE` images

-   `TF-M Core` for controlling the isolation, communication and execution
    within `SPE` and with `NSPE`

-   Crypto, Internal Trusted Storage (`ITS`), Protected Storage (`PS`), Firmware
    Update and Attestation secure services

### Crypto

The Corstone platform supports two crypto backend implementations:

-   [Mbed TLS](../../third_party/mbedtls/repo/README.md)
-   [PSA crypto service](https://tf-m-user-guide.trustedfirmware.org/integration_guide/services/tfm_crypto_integration_guide.html)
    from the [TrustedFirmware-M (TF-M)](#trusted-firmware-m) component
