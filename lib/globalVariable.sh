#!/bin/bash
# Author: José M. C. Noronha

declare _TRUE_="TRUE"
declare _FALSE_="FALSE"
declare _MESSAGE_RUN_HELP_="Please run [%MSG%] for help"
declare _ALIAS_TOOLSFORLINUX_="ToolsForLinux"
declare _TOOLSFORLINUX_SCRIPT_="$INSTALATION_FOLDER/${_ALIAS_TOOLSFORLINUX_}.sh"

# EXIT RETURN CODE
declare -i _CODE_EXIT_ERROR_=1
declare -i _CODE_EXIT_SUCCESS_=0