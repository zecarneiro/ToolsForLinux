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
        echo -e "\033[1;31mERROR $functionName: $msg"
    fi

    if [ -n "$code" ]; then
        echo -e "\033[1;31mERROR CODE $functionName: $code"
    fi
    exitError $code
}

function printSuccess() {
    local msg="$1"
    if [ -n "$msg" ]; then
        echo -e "\033[1;32mSUCCESS: $msg"
    fi
}

function printInformation() {
    local msg="$1"
    if [ -n "$msg" ]; then
        echo -e "\033[1;33mINFO: $msg"
    fi
}

function exitError() {
    if (( $1 > 0 )); then
        exit $1
    fi
}
