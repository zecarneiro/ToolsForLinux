#!/bin/bash
# Author: José Manuel C. Noronha

# Global Variable
declare typeOperation="$1"
declare pathDconf="$2"
declare backupFile="$3"
declare toolAppsSystem="toolAppsSystem.sh"

function backup(){
	if [ -z "$pathDconf" ]||[ -z "$backupFile" ]; then
		echo "Invalid PATH or FILE-OUTPUT"
		exit 1
	fi
	dconf dump "$pathDconf" > "$backupFile"
}

function restoreBackup(){
	if [ -z "$pathDconf" ]||[ -z "$backupFile" ]; then
		echo "Invalid PATH or FILE-OUTPUT"
		exit 1
	fi
	dconf load "$pathDconf" < "$backupFile"
}

function reset(){
	if [ -z "$pathDconf" ]; then
		echo "Invalid PATH"
		exit 1
	fi
	dconf reset -f "$pathDconf"
}

function installDependencies(){
	./$toolAppsSystem install -a --app dconf-tools
}

function helpMessage () {
	echo "
		$(basename "$0") [OPTIONS]... [PATH]... [FILE-OUTPUT]

		OPTIONS:
		-b, --backup	Backup Dconf PATH [NECESSARY FILE-OUTPUT]
		-r, --restore	Restore Backup Dconf PATH from FILE
		-R, --reset		Reset Dconf from PATH
		
		--dependencies	Install Dependencies

		-h, --help		Help
	"
}

case "$typeOperation" in
	-b|--backup)
		backup
		exit 0
	;;
	-r|--restore)
		restoreBackup
		exit 0
	;;
	-R|--reset)
		reset
		exit 0
	;;
	--dependencies)
		installDependencies
		exit 0
	;;
	-h|--help)
		helpMessage
		exit 0
	;;
	* )
		echo "Ivalid Arguments"
		exit 1
	;;
esac