#!/bin/bash
# José M. C. Noronha

declare -i EXIT_ERROR=1
declare INITIATOR="->>"
declare INSTALATION_FOLDER="/opt/ToolsForLinux"
declare LIB_FOLDER="${INSTALATION_FOLDER}/lib"
declare AUTOCOMPLETE_SCRIPT="${LIB_FOLDER}/toolsForLinuxAutocompleteScript.bash"
declare UNINSTALL_SCRIPT="$INSTALATION_FOLDER/uninstall.sh"
declare TOOLS_FOR_LINUX_SCRIPT="$INSTALATION_FOLDER/ToolsForLinux.sh"
declare BASH_RC_FILE="/etc/bash.bashrc"
declare PATH_COMMAND="/bin"
declare COMMAND_SCRIPT="ToolsForLinux"
declare BASH_RC_FILE_DATA

if [ ! -f "$BASH_RC_FILE" ]; then
    echo -e "$INITIATOR NOT EXIST: $BASH_RC_FILE"
    exit $EXIT_ERROR
fi

# Uninstall older version
if [ -d "$INSTALATION_FOLDER" ]; then
    eval "sudo $UNINSTALL_SCRIPT"
fi

: '
####################### INSTALL TOOL AREA #######################
'
echo -e "$INITIATOR Install $COMMAND_SCRIPT"
sudo mkdir -p "$INSTALATION_FOLDER"
sudo cp -r . "$INSTALATION_FOLDER"

: '
####################### SET COMMAND AREA #######################
'
echo -e "$INITIATOR Set command $COMMAND_SCRIPT"
. "$TOOLS_FOR_LINUX_SCRIPT" files create-shortcuts "$TOOLS_FOR_LINUX_SCRIPT" "$PATH_COMMAND" "$COMMAND_SCRIPT"

: '
####################### SET AUTOCOMPLETE AREA #######################
'
echo -e "$INITIATOR Set autocomplete script"
echo ". \"$AUTOCOMPLETE_SCRIPT\"" | sudo tee -a "$BASH_RC_FILE" > /dev/null

: '
####################### RESTART BASHRC AND DELETE UNECESSARY FILES AREA #######################
'
echo -e "$INITIATOR Restart bashrc file"
. "$BASH_RC_FILE"

# Remove unecessary files
echo -e "$INITIATOR Remove unecessary files"
declare -a unecessary_files=("install.sh" ".git" ".gitattributes")
for item in "${unecessary_files[@]}"; do
    sudo rm -r "$INSTALATION_FOLDER/$item"
done

echo -e "$INITIATOR Install Done"
