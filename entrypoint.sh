#!/usr/bin/env bash
set -e

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
### ----------------------------------------


_ROOT_DIR="${PWD}"
_WORKDIR="${_ROOT_DIR}/unfor19-awscli"
_DOWNLOAD_FILENAME="unfor19-awscli.zip"
_VERBOSE=${VERBOSE:-"false"}
_DEFAULT_VERSION=2
_AWS_CLI_VERSION=${1:-$AWS_CLI_VERSION} # Use env or arg
_AWS_CLI_VERSION=${_AWS_CLI_VERSION//v/} # Remove "v"
_AWS_CLI_VERSION=${_AWS_CLI_VERSION//V/} # Remove "V"
_AWS_CLI_VERSION=${_AWS_CLI_VERSION:-$_DEFAULT_VERSION}
_DOWNLOAD_URL=""
_LIGHTSAIL_INSTALL=${LIGHTSAILCTL:-"false"}

msg_error(){
    msg=$1
    echo -e ">> [ERROR]: ${msg}"
    exit 1
}


msg_log(){
    msg=$1
    echo -e ">> [LOG]: ${msg}"
}


detect_verbose(){
    msg_log "Verbose mode = ${_VERBOSE}"
}


detect_bash(){
    msg_log "Detecting Bash version ..."
    bash --version
}


detect_download_tool(){
    # Prefers wget over curl
    local result_wget
    local result_curl
    msg_log "Detecting download tool ..."
    result_wget=$(wget --version 2>&1 || true)
    if [[ $result_wget =~ not.*found ]]; then
        result_curl=$(curl --version 2>&1 || true)
        if [[ $result_curl =~ not.*found ]]; then
            msg_error "Required: wget or curl"
        else
        # found curl
            _DOWNLOAD_TOOL="curl"
        fi
    else # found wget
        _DOWNLOAD_TOOL="wget"
    fi
    msg_log "Download tool: $_DOWNLOAD_TOOL"
}


detect_os(){
    local os
    os="$(uname)"
    if [[ $os =~ "Darwin" ]]; then
        _OS="macOS"
    elif [[ $os =~ "NT" ]]; then
        # Must use Git Bash
        _OS="Windows"
    else
        # Default is Linux
        _OS="Linux"
    fi
    msg_log "Running on $_OS"
}


set_workdir(){
    mkdir -p "${_WORKDIR}"
    cd "${_WORKDIR}"
}


valid_semantic_version(){
    msg_log "Validating semantic version - $_AWS_CLI_VERSION"
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
            if [[ $_OS = "Linux" || $_OS = "macOS" ]]; then
                _DOWNLOAD_URL="https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
            elif [[ $_OS = "Windows" ]]; then
                _DOWNLOAD_URL="Not needed"
            fi
        else
            # Specific v1 - same for any OS
            _DOWNLOAD_URL="https://s3.amazonaws.com/aws-cli/awscli-bundle-${_AWS_CLI_VERSION}.zip"
        fi
    # v2
    elif [[ $_AWS_CLI_VERSION =~ ^2.*$ ]]; then
        if [[ $_AWS_CLI_VERSION = "2" ]]; then
            # Latest v2
            if [[ $_OS = "Linux" ]]; then            
                _DOWNLOAD_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
            elif [[ $_OS = "macOS" ]]; then
                _DOWNLOAD_URL="https://awscli.amazonaws.com/AWSCLIV2.pkg"
            elif [[ $_OS = "Windows" ]]; then
                _DOWNLOAD_URL="https://awscli.amazonaws.com/AWSCLIV2.msi"
            fi
        else
            # Specific v2
            if [[ $_OS = "Linux" ]]; then
                _DOWNLOAD_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${_AWS_CLI_VERSION}.zip"
            elif [[ $_OS = "macOS" ]]; then
                _DOWNLOAD_URL="https://awscli.amazonaws.com/AWSCLIV2-${_AWS_CLI_VERSION}.pkg"
            elif [[ $_OS = "Windows" ]]; then
                _DOWNLOAD_URL="https://awscli.amazonaws.com/AWSCLIV2-${_AWS_CLI_VERSION}.msi"
            fi
        fi
    fi
    msg_log "_DOWNLOAD_URL = ${_DOWNLOAD_URL}"
}


check_version_exists(){
    if [[ $_OS = "Linux" || $_OS = "macOS" ]] || [[ $_OS = "Windows" && $_AWS_CLI_VERSION =~ ^2.*$ ]]; then
        msg_log "Checking if the provided version exists in AWS"
        local exists
        if [[ $_DOWNLOAD_TOOL = "wget" ]]; then
            exists=$(wget -q -S --spider "$_DOWNLOAD_URL" 2>&1 || true)
        elif [[ $_DOWNLOAD_TOOL = "curl" ]]; then
            exists=$(curl -s -o /dev/null -w "%{http_code}" "$_DOWNLOAD_URL" 2>&1 || true)
        fi
        msg_log "Exists: $exists"
        if [[ $exists =~ 200 ]]; then
            msg_log "Provided version exists - ${_AWS_CLI_VERSION}"
        else
            msg_error "Provided version does not exist - ${_AWS_CLI_VERSION}"
        fi
    fi
}


download_aws_cli(){
    if [[ $_DOWNLOAD_URL != "Not Needed" ]]; then
        if [[ $_OS = "Linux" || $_OS = "macOS" ]] || [[ $_OS = "Windows" && $_AWS_CLI_VERSION =~ ^2.*$ ]]; then
            msg_log "Downloading ..."
            if [[ $_DOWNLOAD_TOOL = "wget" ]]; then
                wget -q -O "$_DOWNLOAD_FILENAME" "$_DOWNLOAD_URL"
            elif [[ $_DOWNLOAD_TOOL = "curl" ]]; then
                curl -s -o "$_DOWNLOAD_FILENAME" "$_DOWNLOAD_URL"
            fi 
        fi
    [[ $_VERBOSE = "true" ]] && ls -lah "$_DOWNLOAD_FILENAME"
    wait
    msg_log "Finished downloading"
    fi
}


install_aws_cli(){
    local aws_path
    msg_log "Installing AWS CLI - ${_AWS_CLI_VERSION}"
    if [[ $_AWS_CLI_VERSION =~ ^1.*$ ]]; then
        if [[ $_OS = "Linux" || $_OS = "macOS" ]]; then
            msg_log "Unzipping ${_DOWNLOAD_FILENAME}"
            unzip -qq "$_DOWNLOAD_FILENAME"
            [[ $_VERBOSE = "true" ]] && ls -lah
            wait
            ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
        elif [[ $_OS = "Windows" ]]; then
            if [[ $_AWS_CLI_VERSION = "1" ]]; then
                # Latest v1
                pip3 install awscli --upgrade
            else
                # Specific v1
                pip3 install awscli=="$_AWS_CLI_VERSION" --upgrade
            fi
        fi
    elif [[ $_AWS_CLI_VERSION =~ ^2.*$ ]]; then
        if [[ $_OS = "Linux" ]]; then
            set +e
            aws_path=$(which aws)
            [[ -n $aws_path ]] && msg_log "aws_path = $aws_path"
            set -e        
            msg_log "Unzipping ${_DOWNLOAD_FILENAME}"
            unzip -qq "$_DOWNLOAD_FILENAME"
            [[ $_VERBOSE = "true" ]] && ls -lah
            wait
            if [[ $aws_path =~ ^.*aws.*not.*found || -z $aws_path ]]; then
                # Fresh install
                ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli        
            else
                # Update
                ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
            fi
        elif [[ $_OS = "macOS" ]]; then
            # Fresh install or Update
            local pkg_filename
            pkg_filename=${_DOWNLOAD_FILENAME//\.zip/\.pkg}
            mv "$_DOWNLOAD_FILENAME" "$pkg_filename"
            installer -pkg ./"$pkg_filename" -target /
        elif [[ $_OS = "Windows" ]]; then
            local msi_filename
            local pwsh_path
            local pwsh_script_path
            pwsh_script_path="install_with_pwsh.ps1"
            pwsh_path=$(which pwsh)
            msi_filename=${_DOWNLOAD_FILENAME//\.zip/\.msi}
            mv "$_DOWNLOAD_FILENAME" "$msi_filename"
            cat <<EOT >> "$pwsh_script_path"
#!"${pwsh_path}"
\$MSIArguments = @(
    "/i"
    (-f $msi_filename)
    "/qn"
    "/norestart"
)
Start-Process "msiexec.exe" -ArgumentList \$MSIArguments -Wait -NoNewWindow 
EOT
            chmod +x "$pwsh_script_path"
            ./"$pwsh_script_path"
        fi
    fi
    msg_log "Installation completed"
}


cleanup(){
    cd "${_ROOT_DIR}"
    [[ $_VERBOSE = "true" ]] && ls -lh
    rm -rf "${_WORKDIR}"
    [[ $_VERBOSE = "true" ]] && ls -lh
    wait
}


test_aws_cli(){
    msg_log "Printing AWS CLI installed version"
    aws --version
}


install_lightsailctl(){
    _LIGHTSAIL_URL="https://s3.us-west-2.amazonaws.com/lightsailctl/latest/linux-amd64/lightsailctl"
    _LIGHTSTAIL_FILEPATH="/usr/local/bin/lightsailctl"
    if [[ $_LIGHTSAIL_INSTALL = "true" ]]; then
        if [[ $_AWS_CLI_VERSION =~ ^2.*$ ]]; then
            msg_log "Installing Lightsailctl"
            if [[ $_DOWNLOAD_TOOL = "wget" ]]; then
                wget -q -O "$_LIGHTSTAIL_FILEPATH" "$_LIGHTSAIL_URL"
            elif [[ $_DOWNLOAD_TOOL = "curl" ]]; then
                curl -s -o "$_LIGHTSTAIL_FILEPATH" "$_LIGHTSAIL_URL"
            fi
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
  if [[ $_LIGHTSAIL_INSTALL = "true" ]]; then
    set +e
    installed_lightsail=$(lightsailctl 2>&1 | grep "it is meant to be invoked by AWS CLI")
    set -e
    if [[ -n $installed_lightsail ]]; then
      msg_log "Lightsail was installed successfully"
    else
      error_msg "Failed to install lightsailctl"
    fi
  fi
}


# Main
detect_verbose
detect_bash
detect_download_tool
detect_os
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
