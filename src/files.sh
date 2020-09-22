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
    file =              $1
    dest =              $2
    shortcuts_name =    $3
'
function createShortcuts() {
    local file="$1"
    local dest="$2"
    local shortcuts_name="$3"
    local errorcode

    printMessages "Create symbolic links for: $file" 3
    if [ -n "$file" ]; then        
        if [ -f "$file" ]||[ -d "$file" ]; then
            # Get name of file if not set
            [[ -z "$shortcuts_name" ]] && shortcuts_name="$(basename "$file")"
            if [ -n "$shortcuts_name" ]; then
                # Validate dest
                if [ -z "$dest" ]||[ ! -d "$dest" ]; then $dest=""; fi
                executeCMD "ln -sf \"$file\" \"$dest/${shortcuts_name}\""
                errorcode=$?
                (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
                    printMessages "Operations fail" 4 "${FUNCNAME[0]}"
                    printMessages "Try again with sudo"

                    executeCMD "sudo ln -sf \"$file\" \"$dest/${shortcuts_name}\""
                    errorcode=$?
                }

                # If error persist, exit
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

: '
    Create Desktop files

    ARGS:
    operations =    $1  (boot|normal)
    name =          $2
    exec =          $3
    terminal =      $4  (true|false)
    icon =          $5  (Only PNG format)
    extradata =     $6
'
function desktopFile() {
    local operations="$1"; shift
	local name="$1"
    local exec="$2"
    local terminal="$3"
    local icon="$4"
    local extradata="$5"
    local homePath="$(echo $HOME)"
    local nameFile="$($_ALIAS_TOOLSFORLINUX_ others upper-lower-string upper "$name")"
    local -A keysData=(
        ['name']="%NAME%"
        ['exec']="%CMD_TO_EXEC%"
        ['icon']="%ICON_ONLY_PNG%"
        ['terminal']="%TERMINAL%"
        ['extradata']="%EXTRA_DATA%"
    )
    local desktopPath
    local desktopFile

    

    local desktopData="
        [Desktop Entry]\n
        Name=%NAME%\n
        Exec='%CMD_TO_EXEC%'\n
        Icon='%ICON_ONLY_PNG%'\n
        Terminal=%TERMINAL%\n
        Type=Application\n
    "

    printMessages "Init Create Desktop file" 3
    case "$operations" in
        boot)
            desktopPath="$homePath/.config/autostart"
            desktopFile="$desktopPath/$nameFile.desktop"
            mkdir -p "$desktopPath"

            desktopData="
                $desktopData
                Hidden=false\n
                NoDisplay=false\n
                X-GNOME-Autostart-enabled=true\n
            "
        ;;
        normal)
            desktopPath="$homePath/.local/share/applications"
            desktopFile="$desktopPath/$nameFile.desktop"
            mkdir -p "$desktopPath"
        ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
    esac
    
    # Insert extra data
    desktopData="
        $desktopData
        %EXTRA_DATA%
    "

    # Validate name
    [ -z "$name" ]||[ -z "$exec" ] && {
        printMessages "Desktop files must be have an valid name and command executable" 4 "${FUNCNAME[0]}"
        return $_CODE_EXIT_ERROR_
    }

    # Validate and replace for terminal
    if [[ "$terminal" = "true" ]]||[[ "$terminal" =~ "false" ]]; then
        desktopData="${desktopData//${keysData[terminal]}/$terminal}"
    else
        printMessages "Desktop files terminal must be true|false" 4 "${FUNCNAME[0]}"
        return $_CODE_EXIT_ERROR_      
    fi

    # Replace all
    desktopData="${desktopData//${keysData[name]}/$name}"
    desktopData="${desktopData//${keysData[exec]}/$exec}"
    desktopData="${desktopData//${keysData[icon]}/$icon}"
    desktopData="${desktopData//${keysData[extradata]}/$extradata}"
    

    # Create desktop file
    echo -e $desktopData | tee "$desktopFile" > /dev/null

    # Remove whitespace on init of line
    sed -i 's/^ *//' "$desktopFile"

    # Set permission to exec
    chmod +x "$desktopFile"

    printMessages "Done" 1
    return $_CODE_EXIT_SUCCESS_
}

: '
    Dowload any data from link

    ARGS:
    typeDest =  $1  (dir|file)
    link =      $2
    dest =      $3
'
function downloadFromLink() {
    local typeDest="$1"; shift
	local link="$1"
	local dest="$2"
	local argsCMD

    case "$typeDest" in
        dir)
            if [ -z "$dest" ]||[ "$dest" = "." ]; then
                argsCMD=""
            elif [ -d "$dest" ]; then
                argsCMD="-P \"$dest\""
            else
                printMessages "Invalid dir" 4 "${FUNCNAME[0]}"
                return $_CODE_EXIT_ERROR_
            fi
        ;;
        file)
            local dirFile="$(dirname "$dest")"
            if [ -d "$dirFile" ]; then
                argsCMD="-O \"$dest\""
            else
                printMessages "Invalid dir for file: $dest" 4 "${FUNCNAME[0]}"
                return $_CODE_EXIT_ERROR_
            fi
        ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
    esac

	# Download
    executeCMD "wget $argsCMD '$link'"
	(( $? > $_CODE_EXIT_SUCCESS_ )) && {
        printMessages "Operation Fail" 4 "${FUNCNAME[0]}"
        return $_CODE_EXIT_ERROR_
    }
    return $_CODE_EXIT_SUCCESS_
}

: '
####################### MAIN AREA #######################
'
function HELP() {
    local data=()
    export TOOLFORLINUX_TABLE_LENGTH_COLUMN="2"
    export TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR="67"
	local -a data=()

    echo -e "$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[2]} <subcommand>\n\nSubcommand:"
    data+=("\"move-to-main-folder [MAIN_FOLDER(OP)]\"" "\"Move all files to main folder\"")
    data+=("\"empty [f/d list/delete]\"" "\"List/Delete Empty Files or Directory\"")
    data+=("\"create-shortcuts [FILE DEST SHORTCUTS_NAME(OP)]\"" "\"Create Symbolic Link for an file\"")
    data+=("\"desktop-file [boot|normal NAME EXEC true|false ICON(OP) EXTRA(OP)]\"" "\"Create Desktop files. Term=\$4\"")
    data+=("\"download [dir|file LINK DEST(OP)]\"" "Dowload any data from link. If dir so DEST = PATH else DEST = FILE(path/for/file/name)")
    
    data+=("%EMPTY_LINE%")
    data+=("help" "Help")   
    . "$_SRC_/${_SUBCOMMANDS_[1]}.sh" create-table ${data[@]}

    printInformationHelp
}

declare _OPERATIONS_APT_="$1"; shift
case "$_OPERATIONS_APT_" in
    move-to-main-folder) moveAllToMainFolder "$@" ;;
    empty) emptyFilesDirectory "$@" ;;
    create-shortcuts) createShortcuts "$@" ;;
    desktop-file) desktopFile "$@" ;;
    download) downloadFromLink "$@" ;;
    help) HELP ;;
    *)
        messageerror="$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[2]} help"
        printMessages "${_MESSAGE_RUN_HELP_/\%MSG\%/$messageerror}" 4 "${FUNCNAME[0]}"
        exitError $_CODE_EXIT_ERROR_
    ;;
esac