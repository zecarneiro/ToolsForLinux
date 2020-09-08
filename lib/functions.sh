#!/bin/bash
# Author: José M. C. Noronha

: '
####################### APT AREA #######################
'
function printError() {
    local functionName="$1"; shift
    local msg="$1"
    local code="$2"

    if [ -n "$msg" ]; then
        echo -e "${RED}ERROR $functionName: $msg${NOCOLOR}"
    fi

    if [ -n "$code" ]; then
        echo -e "${RED}ERROR CODE $functionName: $code${NOCOLOR}"
    fi
    exitError $code
}

function printSuccess() {
    local msg="$1"
    if [ -n "$msg" ]; then
        echo -e "${GREEN}SUCCESS: $msg${NOCOLOR}"
    fi
}

function printInformation() {
    local msg="$1"
    if [ -n "$msg" ]; then
        echo -e "${YELLOW}INFO: $msg${NOCOLOR}"
    fi
}

function exitError() {
    if (( $1 > 0 )); then
        exit $1
    fi
}
