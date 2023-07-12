# Matter Corstone Unit Tests Integration Test

The Corstone Unit Tests Integration Test validate the specific
[unit-tests](../../unit-tests/README.md) application.

## Setup-configure-execute

For information on how to setup, configure and execute test refer to
[Corstone integration tests](../../../../../docs/guides/corstone_integration_tests.md).

## Additional configuration

-   binary path fixture

> 💡 **Notes**:
>
> Application binary path passing is required. Use `--binaryPath` command-line
> argument with the correct path to the executable.

## Test cases

The test validates the correct launch of the application and waits for the
unit-test status output. It checks if any test failed.
