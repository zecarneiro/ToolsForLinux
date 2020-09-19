#!/bin/bash
# Author: José M. C. Noronha

function moveAllToMainFolder() {
    find . -mindepth 2 -type f -print -exec mv {} . \;
    (( $? > 0 )) && {
        printMessages "Operations Fail" 4 ${FUNCNAME[0]}
        return $_EXIT_ERROR_
    } || {
        printMessages "Done" 1
    }
    return $_SUCCESS_
}

: '
    List/Delete Empty Files or Directory
    For more information visit:\n\t1 - https://www.computerhope.com/unix/ufind.htm\n\n
'
function emptyFilesDirectory() {
    local typeOfData="$1"
    local operations="$2"
    local errorCode=0

    printMessages "Init List/Delete Empty Files or Directory" 3

    case "$typeOfData" in
        f)
            case "$operations" in
                list) find . -empty -type f -printf "\n%p\n"; errorCode="$?" ;;
                delete) find . -empty -type f -printf "\n%p\n" -exec rm -R {} +; errorCode="$?" ;;
                *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_EXIT_ERROR_ ;;
            esac
        ;;
        d)
            case "$operations" in
                list) find . -empty -type d -printf "\n%p\n"; errorCode="$?" ;;
                delete) find . -empty -type d -printf "\n%p\n" -exec rm -R {} +; errorCode="$?" ;;
                *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_EXIT_ERROR_ ;;
            esac
        ;;      
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_EXIT_ERROR_ ;;
    esac
    (( $errorCode > 0 )) && {
        printMessages "Operactions Fail" 4 "${FUNCNAME[0]}"
        exitError $errorCode
    } || printMessages "Done" 1
    return $_SUCCESS_
}

function existFileDirectory() {
    local fileDir="$2"
    case "$1" in
        f) [[ -f "$fileDir" ]] && echo "$_TRUE_" || echo "$_FALSE_" ;;
        d) [[ -d "$fileDir" ]] && echo "$_TRUE_" || echo "$_FALSE_" ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_EXIT_ERROR_ ;;
    esac
    return $_SUCCESS_
}


declare _OPERATIONS_APT_="$1"; shift
case "$_OPERATIONS_APT_" in
	move-to-main-folder) moveAllToMainFolder ;;
    empty) emptyFilesDirectory "$@" ;;
    exist) existFileDirectory "$@" ;;
esac