# install-aws-cli-action

[![test](https://github.com/unfor19/install-aws-cli-action/actions/workflows/test.yaml/badge.svg)](https://github.com/unfor19/install-aws-cli-action/actions?query=workflow%3Atest)
[![test-action](https://github.com/unfor19/install-aws-cli-action-test/workflows/test-action/badge.svg)](https://github.com/unfor19/install-aws-cli-action-test/actions?query=workflow%3Atest-action)

Install/Setup AWS CLI on a GitHub Actions Linux host.

After this action, every step is capable of running `aws` CLI, and it's up to you to set AWS credentials in the subsequent steps.

Tested in [unfor19/install-aws-cli-action-test](https://github.com/unfor19/install-aws-cli-action-test/actions?query=workflow%3Atest-action)

**TIP**: It's possible to use the [entrypoint.sh](https://github.com/unfor19/install-aws-cli-action/blob/master/entrypoint.sh) script as a "bootstrap script to install/setup aws cli on Linux", regardless of GitHub Actions; see [Other Options](https://github.com/unfor19/install-aws-cli-action#other-options) for more details.

## Usage

Valid AWS CLI `version` values:

- `1` - latest v1
- `2` - latest v2 (default)
- `1.##.##` - specific v1
- `2.##.##` - specific v2

### Usage

Add one of the following steps to a job in your workflow.

#### Common Usage

```yaml
- id: install-aws-cli
  uses: unfor19/install-aws-cli-action@v1
  with:
    version: 2                         # default
    verbose: false                     # default
    arch: amd64                        # allowed values: amd64, arm64
```

#### Full Example

```yaml
- id: install-aws-cli
  uses: unfor19/install-aws-cli-action@v1
  with:
    version: 2                         # default
    verbose: false                     # default
    arch: amd64                        # allowed values: amd64, arm64
    bindir: "/usr/local/bin"           # default
    installrootdir: "/usr/local"       # default
    rootdir: ""                        # defaults to "PWD"
    workdir: ""                        # defaults to "PWD/unfor19-awscli"
```

### Test with GitHub Matrix

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

## Other options

- Execute locally
  ```bash
  curl -L -o install-aws.sh https://raw.githubusercontent.com/unfor19/install-aws-cli-action/master/entrypoint.sh && \
  chmod +x install-aws.sh
  ./install-aws.sh "v2" "amd64"
  rm install-aws.sh  
  ```
- Dockerfile - Add this to your Dockerfile
  ```dockerfile
  # Install AWS CLI
  WORKDIR /tmp/
  RUN curl -L -o install-aws.sh https://raw.githubusercontent.com/unfor19/install-aws-cli-action/master/entrypoint.sh && \
      sudo chmod +x install-aws.sh && \
      sudo ./install-aws.sh "v2" "amd64" && \
      sudo rm install-aws.sh
  ```
  **NOTE**: On some Docker images, you might need to add `sudo` in front of each command, like `sudo curl -L ..`, `sudo chmod ..`, etc.

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
