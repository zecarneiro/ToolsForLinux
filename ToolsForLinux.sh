#!/bin/bash
# Author: José M. C. Noronha

declare _LIB_="$PWD/lib"
declare _SRC_="$PWD/src"

# Import all necessary scripts
. "$_LIB_/functions.sh"
. "$_LIB_/colorForString.sh"

declare _OPERATIONS_="$1"; shift
case "$_OPERATIONS_" in
    app-operations) . "$_SRC_/appsOperations.sh" "$@" ;;
    *)
        echo "default"
    ;;
esac
