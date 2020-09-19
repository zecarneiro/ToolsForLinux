#!/bin/bash
# Author: José M. C. Noronha

function printWithPropont() {
    local propont_name="\$"  
    [[ -n "$2" ]] && propont_name="$2"    
    echo -e "\n${LIGHTCYAN}${propont_name}>${NOCOLOR} ${1}"
}

: '
Print Messages by type with color. ARGS:
    ARG1:
        1 - SUCCESS
        2 - WARNING
        3 - INFO
        4 - ERROR
    ARG2: Messages to print
    ARG3: Print code of error
    ARG4: Function name. To get function name: ${FUNCNAME[0]}
'
function printMessages() {
    local msg="$1"
    local typeMSG="$2"
    local functionName=""
    [[ -z "$3" ]] || functionName="$3: "

    case "$typeMSG" in
        1) msg="${GREEN}${functionName}$msg${NOCOLOR}" ;;
        2) msg="${YELLOW}${functionName}$msg${NOCOLOR}" ;;
        3) msg="${BLUE}${functionName}$msg${NOCOLOR}" ;;
        4) msg="${RED}ERROR ${functionName}$msg" ;;
        *) msg="${functionName}$msg" ;;
    esac
    printWithPropont "$msg" "${_ALIAS_TOOLSFORLINUX_}"
}

function exitError() {
    if (( $1 > 0 )); then
        exit $1
    fi
}

function isCommandExist() {
    local commands="$1"
    local functionName="$2"
    command -v $commands >/dev/null && {
        return 0
    } || {
        printMessages "COMMAND [$commands] could not be found" 2 $functionName
        return $_EXIT_ERROR_
    }
}

: '
    Execute an command and show the command before
        -> If Arg2 not empty not show command
'
function executeCMD() {
    if [ -z "$2" ]; then
        printWithPropont "${DARKGRAY}${1}${NOCOLOR}" "${_ALIAS_TOOLSFORLINUX_}"
    fi
    eval "$1"
    return $?
}
