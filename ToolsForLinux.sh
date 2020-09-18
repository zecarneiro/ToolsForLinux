#!/bin/bash
# Author: José M. C. Noronha

declare _LIB_="$PWD/lib"
declare _SRC_="$PWD/src"
declare EXIT_ERROR=1
declare _ALIAS_TOOLSFORLINUX_="ToolsForLinux"

# Import all necessary scripts
. "$_LIB_/functions.sh"
. "$_LIB_/colorForString.sh"

declare _OPERATIONS_="$1"; shift
case "$_OPERATIONS_" in
    app-operations) . "$_SRC_/appsOperations.sh" "$@" ;;
    other-operations) . "$_SRC_/othersOperations.sh" "$@" ;;
    *)
        echo "default"
    ;;
esac