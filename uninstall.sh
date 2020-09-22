#!/bin/bash
# José M. C. Noronha

declare -i EXIT_ERROR=1
declare INITIATOR="->"
declare INSTALATION_FOLDER="/opt/ToolsForLinux"
declare LIB_FOLDER="${INSTALATION_FOLDER}/lib"
declare AUTOCOMPLETE_SCRIPT="${LIB_FOLDER}/toolsForLinuxAutocompleteScript.bash"
declare BASH_RC_FILE="/etc/bash.bashrc"
declare COMMAND="/bin/ToolsForLinux"
declare BASH_RC_FILE_DATA

if [ ! -f "$BASH_RC_FILE" ]; then
    echo -e "$INITIATOR NOT EXIST: $BASH_RC_FILE"
    exit $EXIT_ERROR
fi

# Read BASHRC_FILE
BASH_RC_FILE_DATA="$(cat "$BASH_RC_FILE")"

# Remove command
echo -e "$INITIATOR Remove $COMMAND"
[[ -f "$COMMAND" ]] && sudo rm -r "$COMMAND"

# EXECUTE BASHRC OPERATIONS
echo -e "$INITIATOR Remove script autocomplete"
BASH_RC_FILE_DATA="$(echo "$BASH_RC_FILE_DATA" | grep -v ". \"$AUTOCOMPLETE_SCRIPT\"")"
echo "$BASH_RC_FILE_DATA" | sudo tee "$BASH_RC_FILE" > /dev/null

# DELETE INSTALATION FOLDER
if [ -d "$INSTALATION_FOLDER" ]; then
    echo -e "$INITIATOR Delete Dir: $INSTALATION_FOLDER"
    sudo rm -r "$INSTALATION_FOLDER"
fi
echo -e "$INITIATOR Uninstall Done"
