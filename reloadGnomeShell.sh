#!/bin/bash
# Author: José Manuel C. Noronha

# Global Variable
declare selector="$1"

function reload(){
    killall -3 gnome-shell
    echo "Done"
}

# Main
function main(){
	case "$selector" in
		"-r")
			reload
			;;
		*)
            echo "Reload Gnome Shell"
			echo "$0 OPTIONS"
			printf "\t -r: Reload Gnome Shell\n"
			;;
	esac
}
main