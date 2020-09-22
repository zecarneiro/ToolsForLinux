#!/bin/bash
# Author: José M. C. Noronha

declare _TRUE_="TRUE"
declare _FALSE_="FALSE"
declare _MESSAGE_RUN_HELP_="Please run [%MSG%] for help"

# EXIT RETURN CODE
declare -i _CODE_EXIT_ERROR_=1
declare -i _CODE_EXIT_SUCCESS_=0

# Get from https://gist.github.com/jonsuh/3c89c004888dfc7352be
# For Use: echo -e "string without color $RED string in red $NOCOLOR string without color"
declare NOCOLOR='\033[0m'
declare RED='\033[0;31m'
declare GREEN='\033[0;32m'
declare ORANGE='\033[0;33m'
declare BLUE='\033[0;34m'
declare PURPLE='\033[0;35m'
declare CYAN='\033[0;36m'
declare LIGHTGRAY='\033[0;37m'
declare DARKGRAY='\033[1;30m'
declare LIGHTRED='\033[1;31m'
declare LIGHTGREEN='\033[1;32m'
declare YELLOW='\033[1;33m'
declare LIGHTBLUE='\033[1;34m'
declare LIGHTPURPLE='\033[1;35m'
declare LIGHTCYAN='\033[1;36m'
declare WHITE='\033[1;37m'