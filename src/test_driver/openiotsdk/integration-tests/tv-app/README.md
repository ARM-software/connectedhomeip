# Matter Open IoT SDK TV-App Integration Test

The Open IoT SDK TV-App Integration Test validate the
[tv-app](../../../../../examples/tv-app/openiotsdk/README.md) example
application.

## Setup-configure-execute

For information on how to setup, configure and execute test refer to
[Open IoT SDK integration tests](../../../../../docs/guides/openiotsdk_integration_tests.md).

## Additional configuration

-   binary path fixture with the default value:
    `examples/tv-app/openiotsdk/build/chip-openiotsdk-tv-app-example.elf`
-   controller configuration fixture:
    ```
    {
        'vendorId': 0xFFF1,
        'fabricId': 1,
        'persistentStoragePath': '/tmp/openiotsdk-test-storage.json'
    }
    ```

## Test cases

| Smoke test | Commissioning test | Shell command | Clusters                                                                                                                                   |
| ---------- | ------------------ | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| ✅         | ✅                 | ✅            | <li>ApplicationLauncher</li><li>Channel</li><li> ContentLauncher</li><li> KeypadInput</li><li> TargetNavigator</li><li> MediaPlayback</li> |