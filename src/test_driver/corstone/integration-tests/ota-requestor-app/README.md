# Matter Corstone OTA-Requestor-App Integration Test

The Corstone OTA-Requestor-App Integration Test validate the
[ota-requestor-app](../../../../../examples/ota-requestor-app/corstone/README.md)
example application.

## Setup-configure-execute

For information on how to setup, configure and execute test refer to
[Corstone integration tests](../../../../../docs/guides/corstone_integration_tests.md).

## Additional configuration

-   binary path fixture with the default value:
    `examples/lock-app/corstone/build/chip-corstone-lock-app-example.elf`
-   update binary path fixture with the default value:
    `'examples/ota-requestor-app/corstone/build/chip-corstone-ota-requestor-app-example.ota'`
-   controller configuration fixture:
    ```
    {
        'vendorId': 0xFFF1,
        'fabricId': 1,
        'persistentStoragePath': '/tmp/corstone-test-storage.json'
    }
    ```
-   OTA provider configuration fixture:
    ```
    {
        'discriminator': '3841',
        'port': '5580',
        'filePath': f'{updateBinaryPath}',
        'persistentStoragePath': '/tmp/corstone-test-ota-provider.json'
    }
    ```

## Test cases

| Smoke test | Commissioning test | Shell command | Clusters                            |
| ---------- | ------------------ | ------------- | ----------------------------------- |
| ✅         | ✅                 | ❌            | <li>OtaSoftwareUpdateRequestor</li> |

> 💡 **Notes**:
>
> The cluster test case triggers the entire firmware update process of
> downloading and installing a new software image.
