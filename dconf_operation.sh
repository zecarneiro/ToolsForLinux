#!/bin/bash
# Author: José Manuel C. Noronha

# Global Variable
typeOperation="$1"
pathDconf="$2"
backupFile="$3"

function backup(){
	dconf dump "$pathDconf" > "$backupFile"
}

function restoreBackup(){
	dconf load "$pathDconf" < "$backupFile"
}

function reset(){
	dconf reset -f "$pathDconf"
}

function installDependencies(){
	sudo apt install dconf-tools -y
}

case "$typeOperation" in
	"1" )
		backup
		;;
	"2" )
		restoreBackup
		;;
	"3" )
		reset
		;;
	"-i")
		installDependencies
		;;
	* )
		echo "All Deconf operation"
		echo "$0 OPTIONS PATH FILE(OPTIONAL FOR 3)"
		printf "\t 1 - dump\n"
		printf "\t 2 - restore backup\n"
		printf "\t 3 - reset\n"
		printf "\t -i - Install Dependencies\n"
		;;
esac