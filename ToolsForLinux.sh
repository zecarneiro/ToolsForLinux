#!/bin/bash
# Author: José M. C. Noronha

declare INSTALATION_FOLDER="/opt/ToolsForLinux"
declare _LIB_="$INSTALATION_FOLDER/lib"
declare _SRC_="$INSTALATION_FOLDER/src"
declare _DOC_="$INSTALATION_FOLDER/doc"
declare _ALIAS_TOOLSFORLINUX_="ToolsForLinux"
declare -a _SUBCOMMANDS_=("system" "others" "files")

# Import all necessary scripts
. "$_LIB_/functions.sh"
. "$_LIB_/globalVariable.sh"
. "$_LIB_/dependencies.sh"

: '
####################### FUNCTION AREA #######################
'
function docs() {
    local errorcode
    local namePrint="DOC"

    . "$_ALIAS_TOOLSFORLINUX_" others clear-screen
    printMessages "Show $namePrint" 3
    case "$1" in
        git)
            
            cat "$_DOC_/git"
            errorcode=$?
        ;;
        *) printMessages "Invalid arguments" 4 ${FUNCNAME[0]}; return $_CODE_EXIT_ERROR_ ;;
    esac
    
    (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        printMessages "Operation Fail" 4 ${FUNCNAME[0]}
        return $errorcode
    }
    printMessages "$namePrint Done" 1
    return $_CODE_EXIT_SUCCESS_
}

: '
####################### MAIN AREA #######################
'
function HELP() {
    local data=()
    export TOOLFORLINUX_TABLE_LENGTH_COLUMN="2"
    export TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR="90"

    echo -e "$_ALIAS_TOOLSFORLINUX_ <subcommand>\n\nSubcommand:"
    data+=("${_SUBCOMMANDS_[0]}" "\"Execute operation necessary for system\"")
    data+=("${_SUBCOMMANDS_[1]}" "\"Execute others operations\"")
    data+=("${_SUBCOMMANDS_[2]}" "\"Execute operactions for files and directories\"")
    data+=("\"install-dependencies [deb|rpm|gnome-shell-ext|snap|flatpak|locale-package|dconf|wget|git]\"" "\"Execute operactions for files and directories\"")

    data+=("%EMPTY_LINE%")
    data+=("help" "Help")

    . "$_SRC_/${_SUBCOMMANDS_[1]}.sh" create-table ${data[@]}
}

declare _OPERATIONS_="$1"; shift
case "$_OPERATIONS_" in
    system) . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" "$@" ;;
    others) . "$_SRC_/${_SUBCOMMANDS_[1]}.sh" "$@" ;;
    files) . "$_SRC_/${_SUBCOMMANDS_[2]}.sh" "$@" ;;
    install-dependencies) installDependencies "$@" ;;
    docs) docs "$@" ;;
    help) HELP ;;
    *)
        messageerror="$_ALIAS_TOOLSFORLINUX_ help"
        printMessages "${_MESSAGE_RUN_HELP_/\%MSG\%/$messageerror}" 4 "${FUNCNAME[0]}"
        exitError $_CODE_EXIT_ERROR_
    ;;
esac