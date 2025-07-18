#!make
.ONESHELL:
.EXPORT_ALL_VARIABLES:
.PHONY: all $(MAKECMDGOALS)

UNAME := $(shell uname)
UNAME_ARCH := $(shell uname -m)
ROOT_DIR:=${CURDIR}
BASH_PATH:=$(shell which bash)

# --- OS Settings --- START ------------------------------------------------------------
# Windows
ifneq (,$(findstring NT, $(UNAME)))
_OS:=windows
endif
# macOS
ifneq (,$(findstring Darwin, $(UNAME)))
_OS:=macos
endif

ifneq (,$(findstring Linux, $(UNAME)))
_OS:=linux
endif

# Architecture
ifneq (,$(findstring arm64, $(UNAME_ARCH)))
_ARCH:=arm64
endif

ifneq (,$(findstring x86_64, $(UNAME_ARCH)))
_ARCH:=amd64
endif

_AWS_CLI_VERSION:=v2
_AWS_CLI_ARCH:=amd64

ifndef AWS_CLI_VERSION
AWS_CLI_VERSION:=${_AWS_CLI_VERSION}
endif

ifndef AWS_CLI_ARCH
AWS_CLI_ARCH:=${_AWS_CLI_ARCH}
endif


ifndef ARCH
ARCH:=${_ARCH}
endif


# --- OS Settings --- END --------------------------------------------------------------

SHELL:=${BASH_PATH}

DOCKER_IMAGE_NAME:=install-aws-cli-action

# Removes blank rows - fgrep -v fgrep
# Replace ":" with "" (nothing)
# Print a beautiful table with column
help: ## Print this menu
	@echo
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:.* #~~' | column -t -s'#'
	@echo
usage: help


# To validate env vars, add "validate-MY_ENV_VAR"
# as a prerequisite to the relevant target/step
validate-%:
	@if [[ -z '${${*}}' ]]; then \
		echo 'ERROR: Environment variable $* not set' && \
		exit 1 ; \
	fi


docker-build:
	docker build --platform linux/${ARCH} -t ${DOCKER_IMAGE_NAME} .

build: docker-build

docker-run:
	docker run --rm --platform linux/${ARCH} -it ${DOCKER_IMAGE_NAME} "${AWS_CLI_VERSION}" "${AWS_CLI_ARCH}"

run: docker-run
