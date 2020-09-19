#!/bin/bash
# Author: José M. C. Noronha

declare _LIB_="$PWD/lib"
declare _SRC_="$PWD/src"
declare _ALIAS_TOOLSFORLINUX_="ToolsForLinux"

# Import all necessary scripts
. "$_LIB_/functions.sh"
. "$_LIB_/colorForString.sh"
. "$_LIB_/globalVariable.sh"
. "$_LIB_/dependencies.sh"

declare _OPERATIONS_="$1"; shift
case "$_OPERATIONS_" in
    apps-operations) . "$_SRC_/appsOperations.sh" "$@" ;;
    others-operations) . "$_SRC_/othersOperations.sh" "$@" ;;
    files-directory-operations) . "$_SRC_/filesDirectoriesOperations.sh" "$@" ;;
    *)
        echo "default"
    ;;
esac