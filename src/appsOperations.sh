#!/bin/bash
# Author: José M. C. Noronha

: '
####################### APT AREA #######################
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
    local ppas="$@"
    local command
    local runUpdate=0

    case "$operation" in
        -i) command="sudo add-apt-repository ppa:%PPA% -y" ;;
        -u) command="sudo add-apt-repository -r ppa:%PPA% -y" ;;
        *) printError ${FUNCNAME[0]} "Invalid arguments" 1 ;;
    esac

    for ppa in "$@"; do
        if [ ! -z "$(echo "$ppa" | cut -d ":" -f2)" ]; then
            ppa="$(echo "$ppa" | cut -d ":" -f2)"
        fi
        local existPPA=$(grep "^deb .*$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -c .)
        command="${command/\%PPA\%/$ppa}"

        case "$operation" in
            -i)
                (( $existPPA == 0 )) && {
                    eval "$command"
                    (( $? > 0 )) && {
                        printError ${FUNCNAME[0]} "Error on install $ppa" $?
                    } || printSuccess "$ppa installed"; runUpdate=1 
                } || printInformation "PPA $ppa already exist!!!"
            ;;
            -u)
                (( $existPPA > 0 )) && {
                    eval "$command"
                    (( $? > 0 )) && {
                        printError ${FUNCNAME[0]} "Error on uninstall $ppa" $?
                    } || printSuccess "$ppa uninstalled"; runUpdate=1 
                } || printInformation "PPA $ppa not exist!!!"
            ;;
        esac
    done
    echo "oi"

    # Update Lib APT
    if (( $runUpdate > 0 )); then sudo apt update; fi
}

function appAPT() {
    local operation="$1"; shift
    local noRecomends="$1"; shift
    local apps="$@"
    local command
}


# Install APT APP
function installAPT(){
    setAppsAndPPAs "$@"

    # Set ppa
    for PPA in "${ppas[@]}"; do
        if [ ! -z "$PPA" ]; then
            if [ $(ppaInstaled "-a" "$PPA" | grep -c .) -eq 0 ]; then
                echo "Set PPA: $PPA..."
                sudo add-apt-repository "$PPA" -y
                ./$toolGeneric -e "$EMPTY_LINES"
            else
                echo "This $PPA Already Exist..."
                ./$toolGeneric -e "$EMPTY_LINES"
            fi
        fi
    done

    # Install
    for APP in "${apps[@]}"; do
        if [ $(appInstaled "-a" "$APP" | grep -c .) -eq 0 ]; then
            echo "Install: $APP..."
            if [ ! -z "$noRecomends" ]||[ $noRecomends -eq 0 ]; then
                sudo apt install "$APP" -y
            else
                sudo apt install --no-install-recommends "$APP" -y
            fi
            ./$toolGeneric -e "$EMPTY_LINES"
        else
            echo "$APP Already Installed..."
            ./$toolGeneric -e "$EMPTY_LINES"
        fi
    done
}

# Uninstall APT APP
function uninstallAPT(){
    setAppsAndPPAs "$@"

    # Uninstall
    for APP in "${apps[@]}"; do
        echo "Uninstall: $APP..."
        if [ $(appInstaled "-a" "$APP" | grep -c .) -gt 0 ]; then
            sudo apt purge --auto-remove "$APP" -y

            echo "Clear $APP..."
            sudo apt clean "$APP"
            ./$toolGeneric -e "$EMPTY_LINES"
        fi
    done

    # Del ppa
    for PPA in "${ppas[@]}"; do
        if [ ! -z "$PPA" ]; then
            if [ $(ppaInstaled "-a" "$PPA" | grep -c .) -gt 0 ]; then
                echo "Remove PPA: $PPA..."
                sudo add-apt-repository -r "$PPA" -y
                sudo apt update
                ./$toolGeneric -e "$EMPTY_LINES"
            fi
        fi
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
    ppa) ppaAPT "$@" ;;
esac
