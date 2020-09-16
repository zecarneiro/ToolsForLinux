#!/bin/bash
# Author: José M. C. Noronha

# GLOBAL VARIABLE
declare _SUDO_="sudo"
declare -a _DEPENDENCIES_APT_=("$_SUDO_" "add-apt-repository" "apt")
declare -a _DEPENDENCIES_DEB_=("$_SUDO_" "gdebi")
declare -a _DEPENDENCIES_RPM_=("$_SUDO_" "alien")
declare -a _DEPENDENCIES_GNOME_SHELL_EXT_=("unzip" "gnome-shell-extension-tool")
declare -a _DEPENDENCIES_SNAP_=("$_SUDO_" "snapd" "snapd-xdg-open")
declare -a _DEPENDENCIES_FLATPAK_=("torsocks" "flatpak" "xdg-desktop-portal-gtk" "gnome-software-plugin-flatpak")

# Check if installed
function appInstaled(){
    local typeApp="$1"
    local nameApp=$(./$toolGeneric -t "$2")

    case "$typeApp" in
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
        -f|--flatpak)
            if [ -z "$ppa" ]; then
                flatpak remote-list | awk '{if (NR!=0) {print $1}}'
                exit 0
            fi
            
        ;;
        *) printInvalidArg ;;
    esac
}

: '
####################### APT/DEB/RPM AREA #######################
'
# Get List of App APT Installed
function installedAPT() {
    for dependency in "${_DEPENDENCIES_APT_[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

    [[ -z "$1" ]] && {
        apt list --installed 2>/dev/null
    } || {
        apt -qq list "$1" --installed 2>/dev/null
    }
    return $?
}

# Install/Uninstall PPA
function repositoryAPT() {
    local operation="$1"; shift
    local cmdRun
    local runUpdate=0
    local errorPPA
    local countFail=0

    for dependency in "${_DEPENDENCIES_APT_[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

    case "$operation" in
        i)
            cmdRun="sudo add-apt-repository ppa:%REPOSITORY% -y"
            errorPPA="INSTALL FAIL REPOSITORY: "
        ;;
        u)
            cmdRun="sudo add-apt-repository -r ppa:%REPOSITORY% -y"
            errorPPA="UNINSTALL FAIL REPOSITORY: "
        ;;
        *) printMessages "Invalid arguments" 4 $EXIT_ERROR "${FUNCNAME[0]}"; exitError $code ;;
    esac

    for repository in "$@"; do
        if [ ! -z "$(echo "$repository" | cut -d ":" -f2)" ]; then
            ppa="$(echo "$repository" | cut -d ":" -f2)"
        fi
        local existPPA=$(grep "^deb .*$repository" /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -c .)
        cmdRun="${cmdRun/\%REPOSITORY\%/$repository}"
        printMessages "$cmdRun"

        case "$operation" in
            i)
                (( $existPPA == 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printMessages "Error on install $repository" 4 $? "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository installed" 1; runUpdate=1 
                } || printMessages "REPOSITORY $repository already exist!!!" 2
            ;;
            u)
                (( $existPPA > 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printMessages "Error on uninstall $repository" 4 $? "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository uninstalled" 1; runUpdate=1 
                } ||  printMessages "REPOSITORY $repository not exist!!!" 2
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

    for dependency in "${_DEPENDENCIES_APT_[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

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
####################### DEB/RPM/GNOME_SHELL_EXT AREA #######################
'
# Install DEB Files
function debFiles() {
    local errorDEB="INSTALL FAIL DEB: "
    local countFail=0

    for dependency in "${_DEPENDENCIES_DEB_[@]}"; do
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

    for dependency in "${_DEPENDENCIES_RPM_[@]}"; do
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

    for dependency in "${_DEPENDENCIES_GNOME_SHELL_EXT_[@]}"; do
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
# Get List of App SNAP Installed
function installedSNAP() {
    for dependency in "${_DEPENDENCIES_SNAP_[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

    [[ -z "$1" ]] && {
        snap list | awk '{if (NR!=1) {print $1}}'
    } || {
        snap list | awk '{if (NR!=1) {print $1}}' | grep -i "^$1"
    }
    return $?
}

# Install SNAP APP
function appSNAP() {
    local operation="$1"; shift
    local cmdRun
    local errorAPP
    local countFail=0

    for dependency in "${_DEPENDENCIES_SNAP_[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

    case "$operation" in
        i|i-classic)
            cmdRun="sudo snap install %APP%"
            errorAPP="INSTALL FAIL APP: "
        ;;
        u)
            cmdRun="sudo snap remove %APP%"
            errorAPP="UNINSTALL FAIL APP: "
        ;;
        *) printMessages "Invalid arguments" 4 $EXIT_ERROR "${FUNCNAME[0]}"; exitError $EXIT_ERROR ;;
    esac

    for app in "$@"; do
        local isInstalled=$(installedSNAP $app | grep -c .)
        cmdRun="${cmdRun/\%APP\%/$app}"
        printMessages "$cmdRun"

        case "$operation" in
            i|i-classic)
                (( $isInstalled == 0 )) && {
                    if [ "$operation" = "i-classic" ]; then
                        eval "$cmdRun --classic"
                    else
                        eval "$cmdRun"
                    fi
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
####################### FLATPAK AREA #######################
'
function repositoryFLATPAK() {
    local operation="$1"; shift
    local cmdRun
    local runUpdate=0
    local errorPPA
    local countFail=0

    for dependency in "${_DEPENDENCIES_FLATPAK_[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

    case "$operation" in
        i)
            cmdRun="flatpak remote-add --if-not-exists %REPOSITORY%"
            errorPPA="INSTALL FAIL REPOSITORY: "
        ;;
        u)
            cmdRun="sudo add-apt-repository -r ppa:%REPOSITORY% -y"
            errorPPA="UNINSTALL FAIL REPOSITORY: "
        ;;
        *) printMessages "Invalid arguments" 4 $EXIT_ERROR "${FUNCNAME[0]}"; exitError $code ;;
    esac

    for repository in "$@"; do
        if [ ! -z "$(echo "$repository" | cut -d ":" -f2)" ]; then
            ppa="$(echo "$repository" | cut -d ":" -f2)"
        fi
        local existPPA=$(flatpak remote-list | awk '{if (NR!=0) {print $1}}' | grep -i "$repository" | grep -c .)
        cmdRun="${cmdRun/\%REPOSITORY\%/$repository}"
        printMessages "$cmdRun"

        case "$operation" in
            i)
                (( $existPPA == 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printMessages "Error on install $repository" 4 $? "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository installed" 1; runUpdate=1 
                } || printMessages "PPA $repository already exist!!!" 2
            ;;
            u)
                (( $existPPA > 0 )) && {
                    eval "$cmdRun"
                    (( $? > 0 )) && {
                        printMessages "Error on uninstall $repository" 4 $? "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository uninstalled" 1; runUpdate=1 
                } ||  printMessages "PPA $repository not exist!!!" 2
            ;;
        esac
    done

    # Update Lib APT
    if (( $runUpdate > 0 )); then sudo apt update; fi
    (( $countFail > 0 )) && printMessages "$errorPPA" 2
}

# Install FLATPAK APP
function appFLATPAK() {
    local operation="$1"; shift
    local cmdRun
    local errorAPP
    local countFail=0

    for dependency in "${_DEPENDENCIES_FLATPAK_[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        exitError $?
    done

    case "$operation" in
        i)
            cmdRun="sudo snap install %APP%"
            errorAPP="INSTALL FAIL APP: "
        ;;
        u)
            cmdRun="sudo snap remove %APP%"
            errorAPP="UNINSTALL FAIL APP: "
        ;;
        *) printMessages "Invalid arguments" 4 $EXIT_ERROR "${FUNCNAME[0]}"; exitError $EXIT_ERROR ;;
    esac

    # Set ppa
    for PPA in "${ppa[@]}"; do
        if [ ! -z "$PPA" ]; then
            if [ $(checkIsAddedPPA "${vendorApp[$vendorIndex]}" "FLATPAK") -eq 0 ]; then
            	PPA="${vendorApp[$vendorIndex]} $PPA"
                echo "Set Remote: $PPA..."
                
                if [ $isPermitedSO -eq 1 ]; then
                	
                    printEmptyLines 2
                    flatpak update
                else
                	torsocks flatpak remote-add --if-not-exists $PPA
                    printEmptyLines 2
                    torsocks flatpak update
                fi
            else
                echo "This $PPA Already Exist..."
            fi
        fi
        vendorIndex=$vendorIndex+1
    done

    # Install
    vendorIndex=0
    for APP in "${apps[@]}"; do
        if [ $(checkIsInstaled "$APP" "FLATPAK") -eq 0 ]; then
        	APP="${vendorApp[$vendorIndex]} $APP"
            echo "Install: $APP..."
            if [ $isPermitedSO -eq 1 ]; then
            	flatpak install $APP
            else
            	torsocks flatpak install $APP
            fi
            printEmptyLines 2
        else
            echo "$APP Already Installed..."
        fi
        vendorIndex=$vendorIndex+1
    done
}

# Uninstall FLATPAK APP
function uninstallFLATPAK(){
    local -a apps=($1)
    local -a ppa=($2)
    local -i isPermitedSO=$(checkOperatingSystemPermited)

    # Del ppa
    for PPA in "${ppa[@]}"; do
        if [ ! -z "$PPA" ]; then
            if [ $(checkIsAddedPPA "$PPA" "FLATPAK") -eq 1 ]; then
                echo "Remove Remote: $PPA..."

                if [ $isPermitedSO -eq 1 ]; then
                	flatpak remote-delete $PPA
                    printEmptyLines 2
                    flatpak update
                else
                	torsocks flatpak remote-delete $PPA
                    printEmptyLines 2
                    torsocks flatpak update
                fi
            fi
        fi
    done

    # Uninstall
    for APP in "${apps[@]}"; do
        if [ $(checkIsInstaled "$APP" "FLATPAK") -eq 1 ]; then
            echo "Uninstall $APP..."
            if [ $isPermitedSO -eq 1 ]; then
            	flatpak uninstall $APP
            else
            	torsocks flatpak uninstall $APP
            fi
            printEmptyLines 2
        fi
    done
}

: '
####################### OTHERS AREA #######################
'
# Kill app with pid
function killPID() {
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
}

declare _OPERATIONS_APT_="$1"; shift
case "$_OPERATIONS_APT_" in
    apt-installed) installedAPT "$@" ;;
    apt-repository) repositoryAPT "$@" ;;
    apt-app) appAPT "$@" ;;
    deb-files) debFiles "$@" ;;
    rpm-files) rpmFiles "$@" ;;
    gnome-shell-extensions) gnomeShellExtensions "$@" ;;
    snap-installed) installedSNAP "$@" ;;
    snap-app) appSNAP "$@" ;;
esac
