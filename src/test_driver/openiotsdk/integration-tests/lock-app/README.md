# Matter Open IoT SDK Lock-App Integration Test

The Open IoT SDK Lock-App Integration Test validate the
[lock-app](../../../../../examples/lock-app/openiotsdk/README.md) example
application.

## Setup-configure-execute

For information on how to setup, configure and execute test refer to
[Open IoT SDK integration tests](../../../../../docs/guides/openiotsdk_integration_tests.md).

## Additional configuration

-   binary path fixture with the default value:
    `examples/lock-app/openiotsdk/build/chip-openiotsdk-lock-app-example.elf`
-   controller configuration fixture:
    ```
    {
        'vendorId': 0xFFF1,
        'fabricId': 1,
        'persistentStoragePath': '/tmp/openiotsdk-test-storage.json'
    }
    ```

## Test cases

| Smoke test | Commissioning test | Shell command | Clusters          |
| ---------- | ------------------ | ------------- | ----------------- |
| ✅         | ✅                 | ❌            | <li>DoorLock</li> |
