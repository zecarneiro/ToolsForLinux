#!/bin/bash

# With this script will open terminal for nautilus on select files or folder/path
# Will be appear on context menu script > name_of_script

# Firt Arg: name_of_script
# Second Arg: command_of_terminal
# Third Arg: Indicate if path of file selected if separeted of command or not
#	1 - Not separated
#	0 - Separated
# Example: open_in_terminal.sh "name_of_script" "command_of_terminal" 1
declare nameFile="$1"
declare terminalCmd="$2"
declare isCmdAndPathNotHaveSpace="$3"
declare homeDir="$(echo $HOME)"
declare pathFolderSelected="echo -e \"\$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS\""
declare pathScriptNautilus="$homeDir/.local/share/nautilus/scripts"
declare finalCmd
declare scriptText=""

# Execute
if [ -n "$nameFile" ]&&[ -n "$terminalCmd" ]; then
	mkdir -p "$pathScriptNautilus"
	if [ "$isCmdAndPathNotHaveSpace" = "1" ]; then
		finalCmd="$terminalCmd\"\$($pathFolderSelected)\""
	else
		finalCmd="$terminalCmd \"\$($pathFolderSelected)\""
	fi

	scriptText="#!/bin/bash"
	scriptText="$scriptText\n$finalCmd"
	printf "$scriptText\n" > "$pathScriptNautilus"/"$nameFile"
	sudo chmod 777 "$pathScriptNautilus"/"$nameFile"
	nautilus -q
fi