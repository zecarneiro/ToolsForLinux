#!/bin/bash
# Author: José M. C. Noronha

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
    local code="$3"
    local propont="\$> "
    local functionName=""
    [[ -z "$4" ]] || functionName="$4: "

    case "$typeMSG" in
        1) echo -e "$propont${GREEN}${functionName}$msg${NOCOLOR}" ;;
        2) echo -e "$propont${YELLOW}${functionName}$msg${NOCOLOR}" ;;
        3) echo -e "$propont${BLUE}${functionName}$msg${NOCOLOR}" ;;
        4)
            echo -e "$propont${RED}ERROR ${functionName}$msg"
            if [ -n "$code" ]; then
                echo -e "\nERROR CODE ${functionName}$code${NOCOLOR}"
            fi
        ;;
        *) echo -e "$propont${functionName}$msg" ;;
    esac
}

function exitError() {
    if (( $1 > 0 )); then
        exit $1
    fi
}

function isCommandExist() {
    local commands="$1"
    command -v $commands >/dev/null && {
        echo "1"
    } || {
        printMessages 2 "COMMAND [$commands] could not be found" $EXIT_ERROR ${FUNCNAME[0]}
        return $EXIT_ERROR
    }
}
