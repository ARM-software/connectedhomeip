# Matter Open IoT SDK All-Clusters-App Integration Test

The Open IoT SDK All-Clusters-App Integration Test validate the
[all-clusters-app](../../../../../examples/all-clusters-app/openiotsdk/README.md)
example application.

## Setup-configure-execute

For information on how to setup, configure and execute test refer to
[Open IoT SDK integration tests](../../../../../docs/guides/openiotsdk_integration_tests.md).

## Additional configuration

-   binary path fixture with the default value:
    `examples/all-clusters-app/openiotsdk/build/chip-openiotsdk-all-clusters-app-example.elf`
-   controller configuration fixture:
    ```
    {
        'vendorId': 0xFFF1,
        'fabricId': 1,
        'persistentStoragePath': '/tmp/openiotsdk-test-storage.json'
    }
    ```

## Test cases

| Smoke test | Commissioning test | Shell command | Clusters               |
| ---------- | ------------------ | ------------- | ---------------------- |
| ✅         | ✅                 | ❌            | <li>AccessControl</li> |
