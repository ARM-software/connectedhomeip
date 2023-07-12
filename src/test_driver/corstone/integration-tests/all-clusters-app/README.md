# Matter Corstone All-Clusters-App Integration Test

The Corstone All-Clusters-App Integration Test validate the
[all-clusters-app](../../../../../examples/all-clusters-app/corstone/README.md)
example application.

## Setup-configure-execute

For information on how to setup, configure and execute test refer to
[Corstone integration tests](../../../../../docs/guides/corstone_integration_tests.md).

## Additional configuration

-   binary path fixture with the default value:
    `examples/all-clusters-app/corstone/build/chip-corstone-all-clusters-app-example.elf`
-   controller configuration fixture:
    ```
    {
        'vendorId': 0xFFF1,
        'fabricId': 1,
        'persistentStoragePath': '/tmp/corstone-test-storage.json'
    }
    ```

## Test cases

| Smoke test | Commissioning test | Shell command | Clusters               |
| ---------- | ------------------ | ------------- | ---------------------- |
| ✅         | ✅                 | ❌            | <li>AccessControl</li> |
