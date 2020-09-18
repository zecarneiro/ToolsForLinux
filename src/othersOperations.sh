#!/bin/bash
# Author: José M. C. Noronha

function reloadGnomeShell() {
    killall -3 gnome-shell
	(( $? > 0 )) && printMessages "Operations Fail" 4 ${FUNCNAME[0]} || printMessages "Done" 1
}

declare _OPERATIONS_APT_="$1"; shift
case "$_OPERATIONS_APT_" in
	reload-gnome-shell) reloadGnomeShell ;;
esac