#!/bin/bash
_AWS_CLI_VERSION=${AWS_CLI_VERISON:-$1}
echo "Hello from entrypoint.sh, the version is ${_AWS_CLI_VERSION}"
