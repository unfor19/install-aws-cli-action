# install-aws-cli-action

[![test](https://github.com/unfor19/install-aws-cli-action/actions/workflows/test.yaml/badge.svg)](https://github.com/unfor19/install-aws-cli-action/actions?query=workflow%3Atest)
[![test-action](https://github.com/unfor19/install-aws-cli-action-test/workflows/test-action/badge.svg)](https://github.com/unfor19/install-aws-cli-action-test/actions?query=workflow%3Atest-action)

Install AWS CLI on a GitHub Actions Linux host. 

After this action, every step is capable of running `aws` CLI, and it's up to you to set the environment variables (secrets) `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

Tested in [unfor19/install-aws-cli-action-test](https://github.com/unfor19/install-aws-cli-action-test/actions?query=workflow%3Atest-action)

## Usage

Valid `version` values:

- `1` - latest v1
- `2` - latest v2 (default)
- `1.##.##` - specific v1
- `2.##.##` - specific v2

### Usage

Add the following step to a job in your workflow

```yaml
- id: install-aws-cli
  uses: unfor19/install-aws-cli-action@v1
  with:
    version: 2     # default
    verbose: false # default
    arch: amd64    # allowed values: amd64, arm64
```

**TIP:** When running AWS CLI in Github Actions, make sure you set the `AWS_EC2_METADATA_DISABLED: true` and the `AWS_DEFAULT_REGION` environmnet variables for the step because AWS CLI will try to get the region from the IMDS Service instead, therefore causing an execution error.
```yaml
- name: Get caller identity
  env:
    AWS_EC2_METADATA_DISABLED: true
    AWS_DEFAULT_REGION: us-west-1
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_KEY }}
  run: |
    aws sts get-caller-identity
```


### Full example

See [unfor19/install-aws-cli-action-test/blob/master/.github/workflows/test-action.yml](https://github.com/unfor19/install-aws-cli-action-test/blob/master/.github/workflows/test-action.yml)

```yaml
name: test-action

on:
  push:

jobs:
  test:
    runs-on: ubuntu-20.04
    strategy:
      matrix:
        include:
          - TEST_NAME: "Latest v2"
            AWS_CLI_VERSION: "2"
          - TEST_NAME: "Specific v2"
            AWS_CLI_VERSION: "2.0.30"
          - TEST_NAME: "Latest v1"
            AWS_CLI_VERSION: "1"
          - TEST_NAME: "Specific v1"
            AWS_CLI_VERSION: "1.18.1"
          - TEST_NAME: "No Input"
    name: Test ${{ matrix.TEST_NAME }} ${{ matrix.AWS_CLI_VERSION }}
    steps:
      - name: Test ${{ matrix.TEST_NAME }}
        id: install-aws-cli
        uses: unfor19/install-aws-cli-action@master
        with:
          version: ${{ matrix.AWS_CLI_VERSION }}
      - run: aws --version
        shell: bash
```

## Local Development

<details>

<summary>Expand/Collapse</summary>

### Requirements

- Docker

### Getting Started

1. Build Docker image
   ```bash
   docker build -t "install-aws-cli-action" .
   ```
1. Run container
   ```bash
   docker run --rm -it "install-aws-cli-action" "v2" "amd64"
   ```

</details>

## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/install-aws-cli-action/blob/master/LICENSE) file for details
