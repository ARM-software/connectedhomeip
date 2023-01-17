# Matter Open IoT SDK OTA-Requestor-App Example Application

The Open IoT SDK OTA-Requestor Example demonstrates how to remotely trigger
update image downloading and apply it if needed. It provides the service for
Matter's `OTA` clusters. This application plays both roles: the server for the
`OTA Requestor` cluster, and the client of the `OTA Provider` cluster. It can
initiate a software update with a given `OTA Provider` node, download a binary
file and apply it.

The application is configured to support:

-   [TF-M](../../../docs/examples/openiotsdk_examples.md#trusted-firmware-m)
-   [Device Firmware Update](../../../docs/examples/openiotsdk_examples.md#device-firmware-update)

The example behaves as a Matter accessory, device that can be paired into an
existing Matter network and can be controlled by it.

## Build and run

For information on how to build and run this example and further information
about the platform it is run on see
[Open IoT SDK examples](../../../docs/examples/openiotsdk_examples.md).

The example name to use in the scripts is `ota-requestor-app`.

## Using the example

Communication with the application goes through the active telnet session. When
the application runs these lines should be visible:

```
[INF] [-] Open IoT SDK ota-requestor-app example application start
...
[INF] [-] Open IoT SDK ota-requestor-app example application run
```

The ota-requestor-app application launched correctly and you can follow traces
in the terminal.

### Commissioning

Read the
[Open IoT SDK commissioning guide](../../../docs/guides/openiotsdk_commissioning.md)
to see how to use the Matter controller to commission and control the
application.

### OtaSoftwareUpdateRequestor cluster usage

The application fully supports the `OTA Requestor` cluster. Use its commands to
trigger actions on the device. You can issue commands through the same Matter
controller you used to perform the commissioning step above.

Example command:

```
zcl OtaSoftwareUpdateRequestor AnnounceOtaProvider 1234 1 providerNodeId=4321 vendorId=65521 announcementReason=2 metadataForNode=str: endpoint=0
```

The `OTA Requestor` application with node ID 1234 will process this command and
send a `QueryImage` command to the `OTA Provider` with node ID 4321. This starts
the `OTA` process. On receiving the `QueryImageResponse` from the `OTA Provider`
application, the `OTA Requestor` application will verify that the software
version specified in the `SoftwareVersion` field of the response contains a
value newer than the current running version. If the update supplied does not
pass the update will not proceed. The next step is downloading the update image.
If this step is completed, a new image will be installed and the application
will be reboot.
