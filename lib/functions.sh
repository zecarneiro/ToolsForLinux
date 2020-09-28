#!/bin/bash
# Author: José M. C. Noronha

: '
    Show Messages

    ARGS:
    MSG =           $1
    TYPE_MSG =      $2 (1 = SUCCESS|2 = WARNING|3 = INFO|4 = ERROR)
    FUNC_NAME =     $3
'
function showMessages() {
    local msg="$1"
    local typeMsg="$2"
    local functionName=""
    [[ -n $3 ]] && functionName="$3"

    . "$_TOOLSFORLINUX_SCRIPT_" others print-message "${_ALIAS_TOOLSFORLINUX_}> " LIGHTCYAN "" 1

    case "$typeMsg" in
        1) . "$_TOOLSFORLINUX_SCRIPT_" others print-message "$msg" GREEN "$functionName" 1 ;;
        2) . "$_TOOLSFORLINUX_SCRIPT_" others print-message "$msg" YELLOW "$functionName" 1 ;;
        3) . "$_TOOLSFORLINUX_SCRIPT_" others print-message "$msg" BLUE "$functionName" 1 ;;        
        4) . "$_TOOLSFORLINUX_SCRIPT_" others print-message "ERROR $msg" RED "$functionName" 1 ;;
        *) . "$_TOOLSFORLINUX_SCRIPT_" others print-message "$msg" "" "$functionName" 1 ;;
    esac
    echo ""
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
        showMessages "COMMAND [$commands] could not be found" 2 $functionName
        return $_CODE_EXIT_ERROR_
    }
}

: '
    Execute an command and show the command before
        -> If Arg2 not empty not show command
'
function executeCMD() {
    if [ -z "$2" ]; then
        . "$_TOOLSFORLINUX_SCRIPT_" others print-message "${_ALIAS_TOOLSFORLINUX_}> " LIGHTCYAN "" 1
        . "$_TOOLSFORLINUX_SCRIPT_" others print-message "${1}" DARKGRAY "" 1
        echo ""
    fi
    eval "$1"
    return $?
}

function printInformationHelp() {
    echo -e "\nINFORMATION:"
    echo -e "\t > OP = OPTIONAL"
}
