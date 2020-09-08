#!/bin/bash
# Author: José M. C. Noronha

: '
####################### APT/DEB AREA #######################
'
# Check if ppa/remote exist or not
function ppaInstaled(){
    local typePPA="$1"
    local ppa="$2"
    
    case "$typePPA" in
        -a|--apt)
            if [ ! -z "$(echo "$ppa" | cut -d ":" -f2)" ]; then
                ppa="$(echo "$ppa" | cut -d ":" -f2)"
            fi
            grep "^deb .*$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* | grep .
        ;;
        -s|--snap)
            echo "Not Exist PPA for SNAP"
            exit 1
        ;;
        -f|--flatpak)
            if [ -z "$ppa" ]; then
                flatpak remote-list | awk '{if (NR!=0) {print $1}}'
                exit 0
            fi
            flatpak remote-list | awk '{if (NR!=0) {print $1}}' | grep -i "$ppa"
        ;;
        *) printInvalidArg ;;
    esac
}

# Install/Uninstall PPA
function ppaAPT() {
    local operation="$1"; shift
    local cmdRun
    local runUpdate=0

    case "$operation" in
        i) cmdRun="sudo add-apt-repository ppa:%PPA% -y" ;;
        u) cmdRun="sudo add-apt-repository -r ppa:%PPA% -y" ;;
        *) printError ${FUNCNAME[0]} "Invalid arguments" 1 ;;
    esac

    for ppa in "$@"; do
        if [ ! -z "$(echo "$ppa" | cut -d ":" -f2)" ]; then
            ppa="$(echo "$ppa" | cut -d ":" -f2)"
        fi
        local existPPA=$(grep "^deb .*$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -c .)
        cmdRun="${cmdRun/\%PPA\%/$ppa}"

        case "$operation" in
            i)
                (( $existPPA == 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printError ${FUNCNAME[0]} "Error on install $ppa" $?
                    } || printSuccess "$ppa installed"; runUpdate=1 
                } || printInformation "PPA $ppa already exist!!!"
            ;;
            u)
                (( $existPPA > 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printError ${FUNCNAME[0]} "Error on uninstall $ppa" $?
                    } || printSuccess "$ppa uninstalled"; runUpdate=1 
                } || printInformation "PPA $ppa not exist!!!"
            ;;
        esac
    done

    # Update Lib APT
    if (( $runUpdate > 0 )); then sudo apt update; fi
}

function appAPT() {
    local operation="$1"; shift
    local cmdRun

    case "$operation" in
        i-no-recommends) cmdRun="sudo apt install --no-install-recommends %APP% -y" ;;
        i) cmdRun="sudo apt install %APP% -y" ;;
        u) cmdRun="sudo apt purge --auto-remove %APP% -y && sudo apt clean %APP%" ;;
        *) printError ${FUNCNAME[0]} "Invalid arguments" 1 ;;
    esac

    for app in "$@"; do
        local isInstalled=$(apt list --installed 2>/dev/null | grep -i "^$app" | grep -c .)
        cmdRun="${cmdRun/\%APP\%/$app}"
        echo $cmdRun

        case "$operation" in
            i|i-no-recommends)
                (( $isInstalled == 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printError ${FUNCNAME[0]} "Error on install $app" $?
                    } || printSuccess "$app installed"; runUpdate=1 
                } || printInformation "APP $app already installed!!!"
            ;;
            u)
                (( $isInstalled > 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printError ${FUNCNAME[0]} "Error on uninstall $app" $?
                    } || printSuccess "$app uninstalled"
                } || printInformation "APP $ppa not installed!!!"
            ;;
        esac
    done
}

: '
####################### OTHERS AREA #######################
'

# Install DEB Files
function installDebFiles(){
	local -a apps=($1)

	# Install
    for APP in "${apps[@]}"; do
        echo "Install $APP..."
        sudo gdebi -n "$APP"
        printEmptyLines 2
    done
}

# Install RPM Files
function installRpmFiles(){
	local -a apps=($1)

	# Install
    for APP in "${apps[@]}"; do
        echo "Install $APP..."
        sudo alien -i "$APP"
        printEmptyLines 2
    done
}

# Install Gnome Shell Extension
function installGnomeShellExtension(){
    local zipFile="$1"
    local uuid="$(unzip -c "$zipFile" metadata.json | grep uuid | cut -d \" -f4)"

    if [ ! -z $uuid ]; then
        local extensionsPath="$home/.local/share/gnome-shell/extensions/$uuid"

        # Create extension path
        mkdir -p "$extensionsPath"

        # Install Extension
        unzip -q "$zipFile" -d "$extensionsPath/"
        gnome-shell-extension-tool -e "$uuid"
    else
        echo "ERROR: Failed on get UUID"
    fi
}

# Kill app with pid
function killPID(){
	local pid="$1"
	local -i existPID
	local -a subprocessPID=()

	if [ ! -z "$pid" ]; then
		# Check if pid exist
		existPID=$(ps ax | grep $pid | grep -v grep | grep -c .)

		# Kill All PIDs
		if [ $existPID -gt 0 ]; then
		    subprocessPID=( "$(pgrep -P $pid)" )

		    # Kill PID Pai
		    kill $pid 2> /dev/null

		    for PID in "${subprocessPID[@]}"; do
		        if [ ! -z "$PID" ]; then
		            # Check if pid exist
                    existPID=$(ps ax | grep $PID | grep -v grep | grep -c .)

                    # add pid
                    if [ $existPID -gt 0 ]; then
                        # Kill subprocess PID
		                kill $PID 2> /dev/null
                    fi
		        fi
            done
		fi
	fi
}

# Create Boot Desktop files
function createBootDesktop(){
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
function createNormalDesktop(){
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
}

declare _OPERATIONS_APT_="$1"; shift
case "$_OPERATIONS_APT_" in
    apt-ppa) ppaAPT "$@" ;;
    apt-app) appAPT "$@" ;;
esac
