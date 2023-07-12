# Matter Corstone integration tests

The integration testing approach is to run an application under test inside an
emulated target through the
[Arm FVP model for the Corstone-300 MPS3](https://developer.arm.com/downloads/-/arm-ecosystem-fvps).
We open a communication channel for capturing application output and sending
data to its input. The
[Matter Python control](../../src/controller/python/README.md) is used to
communicate with the device over the network.

Integration tests are written using the [pytest](https://docs.pytest.org)
framework. Additionally, for discovering, flashing and communicating with the
`ARM FVP model` target, the
[pyedmgr](https://iot.sites.arm.com/open-iot-sdk/tools/pyedmgr/) tool is used.

The Corstone integration tests implementation are located in the
`src/test_driver/corstone/integration-tests` directory. It contains supported
tests for Matter applications, common code implementation that can be shared
between test cases and general integration test settings.

The list of currently supported tests of Matter's applications:

```
shell
lock-app
ota-requestor-app
all-clusters-app
tv-app
unit-tests
```

## Environment setup

To provide the required environment, use the common
[Corstone platform environment](./corstone_examples.md#environment-setup)
instruction.

## Configuration

The `src/test_driver/corstone/integration-tests/pytest.ini` file contains
general configuration settings for example logs formatting or markers
definitions.

The `src/test_driver/corstone/integration-tests/conftest.py` file also serves
common settings for all available tests. You can find custom command-line
arguments or sharing fixtures in it.

> 💡 **Notes**:
>
> You can also provide your custom settings for running test via command-line.
> For example generate the test report with
> [Pytest JSON Report](https://pypi.org/project/pytest-json-report/) plugin.
>
> Example:
>
> `pytest --json-report --json-report-summary --json-report-file=test_report.json ...`

## Test execution

To execute specific Matter application run `pytest` with pointing to the test
definition file:

```
pytest <application_name>/test_app.py
```

Remember to add necessary command-line arguments according to your test
environment for run test successfully.

Example:

```
pytest --json-report --json-report-summary --json-report-file=test_report_lock-app.json --binaryPath=chip-corstone-lock-app-example.elf.elf --fvp=FVP_Corstone_SSE-300_Ethos-U55 --fvpConfig=cs300.conf lock-app/test_app.py
```

You can also use a helper script or VSCode tasks for testing the supported
Matter Corstone examples. For more information see
[Corstone examples testing](./corstone_examples.md#testing).

## Add new Matter's application test

To to add new Matter's application test to unit tests project, create the new
test directory in the `src/test_driver/corstone/integration-tests`. After that,
in `src/test_driver/corstone/integration-tests/<application_name>/test_app.py`
file implement test cases that validate your application.

The implementation should be `pytest` compliant. You can use the common fixtures
and functions or available test markers.

> 💡 **Notes**:
>
> Remember to update the list of currently supported Matter applications at the
> top of this document.
