#!/bin/bash
# Author: José M. C. Noronha

: '
    Move All files/DIr to main dir
        -> if $1, then the main dir is $1. If not, the main dir is path on terminal

    ARGS:
    mainDir = $1    (OPTIONAL)
'
function moveAllToMainFolder() {
    local maindir="$1"
    [[ -n "$maindir" ]] && {
        if [ -d "$maindir" ]; then
            cd "$maindir"
        fi
    }

    find . -mindepth 2 -type f -print -exec mv {} . \;
    (( $? > 0 )) && {
        printMessages "Operations Fail" 4 ${FUNCNAME[0]}
        return $_CODE_EXIT_ERROR_
    } || {
        emptyFilesDirectory d delete
        printMessages "Done" 1
    }
    return $_CODE_EXIT_SUCCESS_
}

: '
    List/Delete Empty Files or Directory
    For more information visit:\n\t1 - https://www.computerhope.com/unix/ufind.htm\n\n

    ARGS:
    type =          $1  (f|d )
    operations =    $2  (list|delete)
'
function emptyFilesDirectory() {
    local typeOfData="$1"
    local operations="$2"

    local errorcode=0

    printMessages "Init List/Delete Empty Files or Directory" 3

    case "$typeOfData" in
        f)
            case "$operations" in
                list) find . -empty -type f -printf "\n%p\n"; errorcode="$?" ;;
                delete) find . -empty -type f -printf "\n%p\n" -exec rm -R {} +; errorcode="$?" ;;
                *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
            esac
        ;;
        d)
            case "$operations" in
                list) find . -empty -type d -printf "\n%p\n"; errorcode="$?" ;;
                delete) find . -empty -type d -printf "\n%p\n" -exec rm -R {} +; errorcode="$?" ;;
                *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
            esac
        ;;      
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
    esac
    (( $errorcode > 0 )) && {
        printMessages "Operactions Fail" 4 "${FUNCNAME[0]}"
        exitError $errorcode
    } || printMessages "Done" 1
    return $_CODE_EXIT_SUCCESS_
}

: '
    Create Symbolic Link for an file

    ARGS:
    file = $1
'
function createShortcuts() {
    local file="$1"
    local nameFile=''
    local errorcode

    printMessages "Create symbolic links for: $file" 3

    if [ -n "$file" ]; then        
        if [ -f "$file" ]||[ -d "$file" ]; then
            nameFile="$(basename "$file")" # Get name of file
            if [ -n "$nameFile" ]; then
                ln -sf "$file" "${nameFile}_shortcuts" || sudo ln -sf "$file" "${nameFile}_shortcuts"
                errorcode=$?
                (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
                    printMessages "Operations fail" 4 "${FUNCNAME[0]}"
                    return $_CODE_EXIT_ERROR_
                }
            else
                printMessages "Invalid File name" 4 "${FUNCNAME[0]}"
                return $_CODE_EXIT_ERROR_
            fi
        else
            printMessages "File or Dir not exist!!" 4 "${FUNCNAME[0]}"
            return $_CODE_EXIT_ERROR_
        fi
    else
        printMessages "Invalid File inserted" 4 "${FUNCNAME[0]}"
        return $_CODE_EXIT_ERROR_
    fi
    printMessages "Done" 1
    return $_CODE_EXIT_SUCCESS_
}

# Dowload any data from link
: ' function downloadFromLink() {
	local link="$1"
	local destPath="$2"
	local nameForFile="$3"
	local command="wget"

	if [ -z "$destPath" ]; then
		destPath="/tmp"
	fi

	if [ ! -z $nameForFile ]; then
		command="$command -O \"$destPath/$nameForFile\""
    else
        command="$command -P \"$destPath\""
	fi

	# Download
	eval "$command \"$link\""
}


 Create Boot Desktop files
function createBootDesktop() {
    local appName="$1"
	local cmdToExec="$2"
    local useTerminal="$3"
	local icon="$4"
    local extraLines="$5"
    local autoStartApp="$home/.config/autostart"
    local desktopFullPath="$autoStartApp/$appName.desktop"
    local desktopFiletext

    # Create path
    mkdir -p "$autoStartApp"

    # Auto start app
    desktopFiletext="[Desktop Entry]"
    desktopFiletext="$desktopFiletext\nType=Application"
    desktopFiletext="$desktopFiletext\nExec=$cmdToExec"
    desktopFiletext="$desktopFiletext\nIcon=$icon"
    desktopFiletext="$desktopFiletext\nHidden=false"
    desktopFiletext="$desktopFiletext\nNoDisplay=false"

    # Define if use terminal or not
    if [ $useTerminal -eq 1 ]; then
        desktopFiletext="$desktopFiletext\nTerminal=true"
    else
        desktopFiletext="$desktopFiletext\nTerminal=false"
    fi

    desktopFiletext="$desktopFiletext\nX-GNOME-Autostart-enabled=true"
    desktopFiletext="$desktopFiletext\nName[pt]=$appName"
    desktopFiletext="$desktopFiletext\nName=$appName"
    desktopFiletext="$desktopFiletext\nComment[pt]="
    desktopFiletext="$desktopFiletext\nComment=\n"
    desktopFiletext="$desktopFiletext\n$extraLines"
    printf "$desktopFiletext" | tee "$desktopFullPath" > /dev/null
    chmod +x "$desktopFullPath"
}

# Create Normal Desktop files
function createNormalDesktop() {
	local appName="$1"
	local cmdToExec="$2"
    local useTerminal="$3"
	local icon="$4"
    local extraLines="$5"
	local normalApp="$home/.local/share/applications"
	local desktopFullPath="$normalApp/$appName.desktop"
    local desktopFiletext

    # Create path
    mkdir -p "$normalApp"

    # Normal App
    desktopFiletext="[Desktop Entry]"
    desktopFiletext="$desktopFiletext\nType=Application"
    desktopFiletext="$desktopFiletext\nExec=$cmdToExec"
    desktopFiletext="$desktopFiletext\nIcon=$icon"

    # Define if use terminal or not
    if [ $useTerminal -eq 1 ]; then
        desktopFiletext="$desktopFiletext\nTerminal=true"
    else
        desktopFiletext="$desktopFiletext\nTerminal=false"
    fi

    desktopFiletext="$desktopFiletext\nName[pt]=$appName"
    desktopFiletext="$desktopFiletext\nName=$appName"
    desktopFiletext="$desktopFiletext\nGenericName=$appName\n"
    desktopFiletext="$desktopFiletext\n$extraLines"
    printf "$desktopFiletext" | tee "$desktopFullPath" > /dev/null
    chmod +x "$desktopFullPath"
}'

: '
####################### MAIN AREA #######################
'
function HELP() {
    local data=()
    export TOOLFORLINUX_TABLE_LENGTH_COLUMN="2"
    export TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR="50"
	local -a data=()

    echo -e "$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[2]} <subcommand>\n\nSubcommand:"
    data+=("\"move-to-main-folder [MAIN_FOLDER]\"" "\"Move all files to main folder. Main folder is OPTIONAL\"")
    data+=("\"empty [f/d list/delete]\"" "\"List/Delete Empty Files or Directory\"")
    data+=("\"create-shortcuts [FILE]\"" "\"Create Symbolic Link for an file\"")
    
    data+=("%EMPTY_LINE%")
    data+=("help" "Help")

    . "$_SRC_/${_SUBCOMMANDS_[1]}.sh" create-table ${data[@]}
}

declare _OPERATIONS_APT_="$1"; shift
case "$_OPERATIONS_APT_" in
    move-to-main-folder) moveAllToMainFolder "$@" ;;
    empty) emptyFilesDirectory "$@" ;;
    create-shortcuts) createShortcuts "$@" ;;
    help) HELP ;;
    *)
        messageerror="$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[2]} help"
        printMessages "${_MESSAGE_RUN_HELP_/\%MSG\%/$messageerror}" 4 "${FUNCNAME[0]}"
        exitError $_CODE_EXIT_ERROR_
    ;;
esac