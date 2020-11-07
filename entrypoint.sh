#!/bin/bash
set -e

### Requirements
### -----------------------------------
### Minimum: wget and unzip
### v1: Python v2.7+ or 3.4+
### v2: Nothing special 
### -----------------------------------

### Usage
### -----------------------------------
### ./entrypoint.sh ${AWS_CLI_VERSION}
### -----------------------------------


_AWS_CLI_VERSION=${AWS_CLI_VERISON:-$1}
_DOWNLOAD_URL=
_DOWNLOAD_FILENAME="unfor19-awscli.zip"


msg_error(){
    msg=$1
    echo -e ">> [ERROR]: ${msg}"
    exit 1
}


msg_log(){
    msg=$1
    echo -e ">> [LOG]: ${msg}"
}


valid_semantic_version(){
    msg_log "Validating semantic version"
    if [[ $_AWS_CLI_VERSION =~ ^([1,2]|[1,2](\.[0-9]{1,2}\.[0-9]{1,3}))$ ]]; then
        msg_log "Valid version input"
    else
        msg_error "Invalid version input \"$_AWS_CLI_VERSION\", should match: ^([1,2]|[1,2](\.[0-9]{1,2}\.[0-9]{1,3}))$"
    fi
}


set_download_url(){
    msg_log "Setting _DOWNLOAD_URL"
    # v1
    if [[ $_AWS_CLI_VERSION =~ ^1.*$ ]]; then
        if [[ $_AWS_CLI_VERSION = "1" ]]; then
            _DOWNLOAD_URL="https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
        else
            _DOWNLOAD_URL="https://s3.amazonaws.com/aws-cli/awscli-bundle-${_AWS_CLI_VERSION}.zip"
        fi
    # v2
    elif [[ $_AWS_CLI_VERSION =~ ^2.*$ ]]; then
        if [[ $_AWS_CLI_VERSION = "2" ]]; then
            # Latest v2
            _DOWNLOAD_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
        else
            # Specific v2
            _DOWNLOAD_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${_AWS_CLI_VERSION}.zip"
        fi
    fi
    msg_log "_DOWNLOAD_URL = ${_DOWNLOAD_URL}"
}


check_version_exists(){
    msg_log "Checking if the provided version exists in AWS"
    local exists
    set +e
    exists=$(wget -q -S --spider "$_DOWNLOAD_URL" 2>&1 | grep 'HTTP/1.1 200 OK')
    set -e
    if [[ -n $exists ]]; then
        msg_log "Provided version exists - ${_AWS_CLI_VERSION}"
    else
        msg_error "Provided version does not exist - ${_AWS_CLI_VERSION}"
    fi
}


download_aws_cli(){
    msg_log "Downloading ..."
    wget -q -O "$_DOWNLOAD_FILENAME" "$_DOWNLOAD_URL"
    ls -lah "$_DOWNLOAD_FILENAME"
}


install_aws_cli(){
    msg_log "Unzipping ${_DOWNLOAD_FILENAME}"
    unzip -qq "$_DOWNLOAD_FILENAME"
    msg_log "Installing AWS CLI - ${_AWS_CLI_VERSION}"
    if [[ $_AWS_CLI_VERSION =~ ^1.*$ ]]; then
        ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
    elif [[ $_AWS_CLI_VERSION =~ ^2.*$ ]]; then
        ./aws/install
    fi
    msg_log "Installation completed"
}


cleanup(){
    rm -rf "${_DOWNLOAD_FILENAME}" awscli-bundle aws
}


test_aws_cli(){
    msg_log "Printing AWS CLI installed version"
    aws --version
}


# Main
valid_semantic_version
set_download_url
check_version_exists
download_aws_cli
install_aws_cli
cleanup
test_aws_cli
