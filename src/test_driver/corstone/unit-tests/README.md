# Matter Corstone Unit Tests Application

The Corstone Unit Tests Application executes all supported unit tests on the
`FVP Fast Model` target.

The Matter unit tests are included in a set of libraries and allow to validate
most of the components used by Matter examples applications. The main goal of
this project is to run registered tests on Corstone target and check the
results. The final result is the number of tests that failed.

## Build-run-test-debug

For information on how to setup, build, run, test and debug unit tests refer to
[Corstone unit tests](../../../../docs/guides/corstone_unit_tests.md).

## Application output

Expected output of each executed test application:

```
[ATM] Corstone unit-tests start
[ATM] Corstone unit-tests run...
...
[ATM] Test status: 0
[ATM] Corstone unit-tests completed
```

This means the test application launched correctly and executed all registered
test cases. The `Test status` value indicates the number of tests that failed.
