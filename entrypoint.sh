#!/usr/bin/env bash
set -e
set -o pipefail

### Requirements
### ----------------------------------------
### Minimum: wget and unzip
### v1: Python v2.7+ or 3.4+
### v2: Nothing special
### ----------------------------------------

### Usage
### ----------------------------------------
### Set AWS_CLI_VERSION env var or pass arg
### Print ls - export VERBOSE=true
### ./entrypoint.sh "$AWS_CLI_VERSION"
### ./entrypoint.sh "$AWS_CLI_VERSION" "$AWS_CLI_ARCH"
### ----------------------------------------


_ROOT_DIR="${PWD}"
_WORKDIR="${_ROOT_DIR}/unfor19-awscli"
_DOWNLOAD_FILENAME="unfor19-awscli.zip"
_VERBOSE=${VERBOSE:-"false"}
_LIGHTSAIL_INSTALL=${LIGHTSAILCTL:-"false"}
_DOWNLOAD_URL=""


_DEFAULT_VERSION="2"
_AWS_CLI_VERSION="${1:-"$AWS_CLI_VERSION"}"   # Use env or arg
_AWS_CLI_VERSION="${_AWS_CLI_VERSION^^}"      # All uppercase
_AWS_CLI_VERSION="${_AWS_CLI_VERSION//"V"/}"  # Remove "V"
_AWS_CLI_VERSION="${_AWS_CLI_VERSION:-"$_DEFAULT_VERSION"}"

_DEFAULT_ARCH="amd64"
_AWS_CLI_ARCH="${2:-"$AWS_CLI_ARCH"}"         # Use env or arg
_AWS_CLI_ARCH="${_AWS_CLI_ARCH,,}"            # All lowercase
_AWS_CLI_ARCH="${_AWS_CLI_ARCH:-"$_DEFAULT_ARCH"}"


msg_error(){
    local msg="$1"
    echo -e "[ERROR] $(date) :: $msg"
    exit 1
}


msg_log(){
    local msg="$1"
    echo -e "[LOG] $(date) :: $msg"
}


set_workdir(){
    mkdir -p "${_WORKDIR}"
    cd "${_WORKDIR}"
}


valid_semantic_version(){
    msg_log "Validating semantic version - ${_AWS_CLI_VERSION}"
    if [[ "$_AWS_CLI_VERSION" =~ ^([1,2]|[1,2](\.[0-9]{1,2}\.[0-9]{1,3}))$ ]]; then
        msg_log "Valid version input"
    else
        msg_error "Invalid version input \"${_AWS_CLI_VERSION}\", should match: ^([1,2]|[1,2](\.[0-9]{1,2}\.[0-9]{1,3}))$"
    fi
}


set_download_url(){
    msg_log "Setting _DOWNLOAD_URL"
    # v1
    if [[ "$_AWS_CLI_VERSION" =~ ^1.*$ ]]; then
        [[ "$_AWS_CLI_ARCH" != "amd64" ]] && msg_error "AWS CLI v1 does not support ${_AWS_CLI_VERSION}"
        if [[ "$_AWS_CLI_VERSION" = "1" ]]; then
            _DOWNLOAD_URL="https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
        else
            _DOWNLOAD_URL="https://s3.amazonaws.com/aws-cli/awscli-bundle-${_AWS_CLI_VERSION}.zip"
        fi
    # v2
    elif [[ "$_AWS_CLI_VERSION" =~ ^2.*$ ]]; then
        # Check arch
        if [[ "$_AWS_CLI_ARCH" = "amd64" ]]; then
            _AWS_CLI_ARCH="x86_64"
        elif [[ "$_AWS_CLI_ARCH" = "arm64" ]]; then
            _AWS_CLI_ARCH="aarch64"
        else
            msg_error "Invalid arch - ${_AWS_CLI_ARCH}"
        fi

        if [[ $_AWS_CLI_VERSION = "2" ]]; then
            # Latest v2
            _DOWNLOAD_URL="https://awscli.amazonaws.com/awscli-exe-linux-${_AWS_CLI_ARCH}.zip"
        else
            # Specific v2
            _DOWNLOAD_URL="https://awscli.amazonaws.com/awscli-exe-linux-${_AWS_CLI_ARCH}-${_AWS_CLI_VERSION}.zip"
        fi
    fi
    msg_log "Download URL - ${_DOWNLOAD_URL}"
}


check_version_exists(){
    msg_log "Checking if the provided version exists in AWS"
    local exists
    exists="$(wget -q -S --spider "$_DOWNLOAD_URL" 2>&1 | grep 'HTTP/1.1 200 OK' || true)"
    if [[ -n "$exists" ]]; then
        msg_log "Provided version exists - ${_AWS_CLI_VERSION}"
    else
        msg_error "Provided version does not exist - ${_AWS_CLI_VERSION}"
    fi
}


download_aws_cli(){
    msg_log "Downloading ..."
    wget -q -O "$_DOWNLOAD_FILENAME" "$_DOWNLOAD_URL"
    [[ "$_VERBOSE" = "true" ]] && ls -lah "$_DOWNLOAD_FILENAME"
    wait
}


install_aws_cli(){
    local aws_path
    msg_log "Unzipping ${_DOWNLOAD_FILENAME}"
    unzip -qq "$_DOWNLOAD_FILENAME"
    [[ "$_VERBOSE" = "true" ]] && ls -lah
    wait
    msg_log "Installing AWS CLI - ${_AWS_CLI_VERSION}"
    if [[ "$_AWS_CLI_VERSION" =~ ^1.*$ ]]; then
        ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
    elif [[ "$_AWS_CLI_VERSION" =~ ^2.*$ ]]; then
        aws_path=$(which aws || true)
        [[ -n "$aws_path" ]] && msg_log "aws_path = ${aws_path}"
        if [[ "$aws_path" =~ ^qemu-aarch64.* ]]; then
            msg_error "Failed to install AWS CLI - Make sure AWS_CLI_ARCH is set properly, current value is ${_AWS_CLI_ARCH}"
        elif [[ "$aws_path" =~ ^.*aws.*not.*found || -z "$aws_path" ]]; then
            # Fresh install
            ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli
        else
            # Update
            ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
        fi
    fi
    msg_log "Installation completed"
}


cleanup(){
    cd "${_ROOT_DIR}"
    [[ "$_VERBOSE" = "true" ]] && ls -lh
    rm -r "${_WORKDIR}"
    [[ "$_VERBOSE" = "true" ]] && ls -lh
    wait
}


test_aws_cli(){
    local test_results
    msg_log "Printing AWS CLI installed version"
    test_results="$(aws --version 2>&1 || true)"
    if [[ "$test_results" =~ ^aws-cli/.*  ]]; then
        echo "$test_results"
    else
        msg_error "Installation failed - ${test_results}"
        if [[ "$test_results" =~ ^qemu-aarch64.*Could.*not.*open ]]; then
            msg_log "Make sure AWS_CLI_ARCH is set properly, current value is - ${AWS_CLI_ARCH}"
        fi        
    fi
}


install_lightsailctl(){
    if [[ $_LIGHTSAIL_INSTALL = "true" ]]; then
        if [[ $_AWS_CLI_VERSION =~ ^2.*$ ]]; then
            msg_log "Installing Lightsailctl"
            wget -q -O "/usr/local/bin/lightsailctl" "https://s3.us-west-2.amazonaws.com/lightsailctl/latest/linux-amd64/lightsailctl"
            wait
            chmod +x /usr/local/bin/lightsailctl
            msg_log "Installation complete"
        else
            msg_error "Cannot install Lightsail plugin with CLI 1.x"
        fi
    fi
}


test_lightsailctl(){
  local installed_lightsail
  if [[ "$_LIGHTSAIL_INSTALL" = "true" ]]; then
    installed_lightsail=$(lightsailctl 2>&1 | grep "it is meant to be invoked by AWS CLI" || true)
    if [[ -n "$installed_lightsail" ]]; then
      msg_log "Lightsail was installed successfully"
    else
      error_msg "Failed to install lightsailctl"
    fi
  fi
}


# Main
set_workdir
valid_semantic_version
set_download_url
check_version_exists
download_aws_cli
install_aws_cli
install_lightsailctl
cleanup
test_aws_cli
test_lightsailctl
