#!/bin/bash
# Author: José M. C. Noronha

# Check if installed
function appInstaled(){
    local typeApp="$1"
    local nameApp=$(./$toolGeneric -t "$2")

    case "$typeApp" in
        -a|--apt)
            if [ -z "$nameApp" ]; then
                apt list --installed 2>/dev/null
                exit 0
            fi
            apt list --installed 2>/dev/null | grep -i "^$nameApp"
        ;;
        -s|--snap)
            if [ -z "$nameApp" ]; then
                snap list | awk '{if (NR!=1) {print $1}}'
                exit 0
            fi
            snap list | awk '{if (NR!=1) {print $1}}' | grep -i "^$nameApp"
        ;;
        -f|--flatpak)
            if [ -z "$nameApp" ]; then
                flatpak list --all | awk '{if (NR!=1) {print $1}}'
                exit 0
            fi
            flatpak list --all | awk '{if (NR!=1) {print $1}}' | grep -i "^$nameApp"
        ;;
        *) printInvalidArg ;;
    esac
}

# Check if ppa/remote exist or not
function ppaInstaled() {
    local typePPA="$1"
    local ppa="$2"
    
    case "$typePPA" in
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

: '
####################### APT/DEB/RPM AREA #######################
'
# Get List of App APT Installed
function installedAPT() {
    [[ -z "$1" ]] && {
        apt list --installed 2>/dev/null
    } || {
        apt -qq list "$1" --installed 2>/dev/null
    }
    return $?
}

# Install/Uninstall PPA
function ppaAPT() {
    local operation="$1"; shift
    local cmdRun
    local runUpdate=0
    local errorPPA
    local countFail=0

    case "$operation" in
        i)
            cmdRun="sudo add-apt-repository ppa:%PPA% -y"
            errorPPA="INSTALL FAIL PPA: "
        ;;
        u)
            cmdRun="sudo add-apt-repository -r ppa:%PPA% -y"
            errorPPA="UNINSTALL FAIL PPA: "
        ;;
        *) printMessages "Invalid arguments" 4 $EXIT_ERROR "${FUNCNAME[0]}"; exitError $code ;;
    esac

    for ppa in "$@"; do
        if [ ! -z "$(echo "$ppa" | cut -d ":" -f2)" ]; then
            ppa="$(echo "$ppa" | cut -d ":" -f2)"
        fi
        local existPPA=$(grep "^deb .*$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -c .)
        cmdRun="${cmdRun/\%PPA\%/$ppa}"
        printMessages "$cmdRun"

        case "$operation" in
            i)
                (( $existPPA == 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printMessages "Error on install $ppa" 4 $? "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $ppa; "
                        countFail=$((countFail+1))
                    } || printMessages "$ppa installed" 1; runUpdate=1 
                } || printMessages "PPA $ppa already exist!!!" 2
            ;;
            u)
                (( $existPPA > 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printMessages "Error on uninstall $ppa" 4 $? "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $ppa; "
                        countFail=$((countFail+1))
                    } || printMessages "$ppa uninstalled" 1; runUpdate=1 
                } ||  printMessages "PPA $ppa not exist!!!" 2
            ;;
        esac
    done

    # Update Lib APT
    if (( $runUpdate > 0 )); then sudo apt update; fi
    (( $countFail > 0 )) && printMessages "$errorPPA" 2
}

function appAPT() {
    local operation="$1"; shift
    local cmdRun
    local errorAPP
    local countFail=0

    case "$operation" in
        i-no-recommends)
            cmdRun="sudo apt install --no-install-recommends %APP% -y"
            errorAPP="INSTALL FAIL APP: "
        ;;
        i)
            cmdRun="sudo apt install %APP% -y"
            errorAPP="INSTALL FAIL APP: "
        ;;
        u)
            cmdRun="sudo apt purge --auto-remove %APP% -y && sudo apt clean %APP%"
            errorAPP="UNINSTALL FAIL APP: "
        ;;
        *) printMessages "Invalid arguments" 4 $EXIT_ERROR "${FUNCNAME[0]}"; exitError $EXIT_ERROR ;;
    esac

    for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        cmdRun="${cmdRun/\%APP\%/$app}"
        printMessages "$cmdRun"

        case "$operation" in
            i|i-no-recommends)
                (( $isInstalled == 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printMessages "Error on install $app" 4 $? ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app installed" 1
                } || printMessages "APP $app already installed!!!" 2
            ;;
            u)
                (( $isInstalled > 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printMessages "Error on uninstall $app" 4 $? ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app uninstalled" 1
                } || printMessages "APP $ppa not installed!!!" 2
            ;;
        esac
    done
    (( $countFail > 0 )) && printMessages "$errorAPP" 2
}

: '
####################### DEB/RPM/ AREA #######################
'
# Install DEB Files
function debFiles() {
    local errorDEB="INSTALL FAIL DEB: "
    local countFail=0
    local -a listDependencies=("gdebi")

    for dependency in "${listDependencies[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

    for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        (( $isInstalled == 0 )) && {
            sudo gdebi -n "$app"
            (( $? > 0 )) && {
                printMessages "Error on install $app" 4 $? ${FUNCNAME[0]}
                errorDEB="$errorDEB $ppa; "
                countFail=$((countFail+1))
            } || printMessages "$app installed" 1
        } || printMessages "APP $app already installed!!!" 2
    done
    (( $countFail > 0 )) && printMessages "$errorDEB" 2
}

# Install RPM Files
function rpmFiles() {
    local errorRPM="INSTALL FAIL RPM: "
    local countFail=0
    local -a listDependencies=("alien")

    for dependency in "${listDependencies[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

	for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        (( $isInstalled == 0 )) && {
            sudo alien -i "$app"
            (( $? > 0 )) && {
                printMessages "Error on install $app" 4 $? ${FUNCNAME[0]}
                errorRPM="$errorRPM $ppa; "
                countFail=$((countFail+1))
            } || printMessages "$app installed" 1
        } || printMessages "APP $app already installed!!!" 2
    done
    (( $countFail > 0 )) && printMessages "$errorRPM" 2
}

# Install Gnome Shell Extension
function gnomeShellExtensions() {
    local errorGNOME_EXT="INSTALL FAIL GNOME EXTENSION: "
    local homePath="$(echo $HOME)"
    local extensionsPath="$homePath/.local/share/gnome-shell/extensions"
    local uuid=""
    local countFail=0
    local -a listDependencies=("unzip" "gnome-shell-extension-tool")

    for dependency in "${listDependencies[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

    for extension in "$@"; do
        uuid="$(unzip -c "$zipFile" metadata.json | grep uuid | cut -d \" -f4)"
        if [ ! -z $uuid ]; then
            # Create extension path
            mkdir -p "$extensionsPath/$uuid"

            # Extract zip Extension data
            unzip -q "$extension" -d "$extensionsPath/$uuid/"

            # Install extension
            gnome-shell-extension-tool -e "$uuid"

            (( $? > 0 )) && {
                printMessages "Error on install $extension" 4 $? ${FUNCNAME[0]}
                errorGNOME_EXT="$errorGNOME_EXT $extension; "
                countFail=$((countFail+1))
            } || printMessages "$extension installed" 1
        else
            printMessages "ERROR: Failed on get UUID from extension: $extension" 4
        fi
    done
    (( $countFail > 0 )) && printMessages "$errorGNOME_EXT" 2
}

: '
####################### SNAP AREA #######################
'
# Install SNAP APP
function installSNAP(){
    setAppsAndPPAs "$@"
    local -i count="0"

    # Install
    for APP in "${apps[@]}"; do
        if [ $(appInstaled "-s" "$APP" | grep -c .) -eq 0 ]; then
            echo "Install: $APP..."
            local type="classic"

            if [ ${#ppas[@]} -gt 0 ]&&[ $((count+1)) -ge ${#ppas[@]} ]; then
                type=${ppas[$count]}
                echo "$type"
            fi

            sudo snap install "$APP" --$type
            ./$toolGeneric -e "$EMPTY_LINES"
        else
            echo "$APP Already Installed..."
            ./$toolGeneric -e "$EMPTY_LINES"
        fi
        count=$count+1
    done
}

# Uninstall SNAP APP
function uninstallSNAP(){
    setAppsAndPPAs "$@"

    # Uninstall
    for APP in "${apps[@]}"; do
        echo "Uninstall $APP..."
        if [ $(appInstaled "-s" "$APP" | grep -c .) -gt 0 ]; then
            sudo snap remove "$APP"
            ./$toolGeneric -e "$EMPTY_LINES"
        else
            echo "$APP not Installed..."
            ./$toolGeneric -e "$EMPTY_LINES"
        fi
    done
}

: '
####################### OTHERS AREA #######################
'



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
    apt-installed) installedAPT "$@" ;;
    apt-ppa) ppaAPT "$@" ;;
    apt-app) appAPT "$@" ;;
    deb-files) debFiles "$@" ;;
    rpm-files) rpmFiles "$@" ;;
    gnome-shell-extensions) gnomeShellExtensions "$@"
esac
