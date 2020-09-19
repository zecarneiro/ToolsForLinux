#!/bin/bash
# Author: José M. C. Noronha

: '
####################### APT AREA #######################
'
function cleanSystemAPT() {
    local -i linesWithRC
    local homeDir="$(echo $HOME)"

    printMessages "Clean System for APT" 3

    dependencyAPPS apt
    exitError $?

    executeCMD "sudo apt autoremove -y"
    exitError $?
    #dpkg --list
    data='oi r1 jjj \nrc ggg aaa\naaaa tttt rca'
    linesWithRC=$( echo -e "$data" )
    echo $?
    echo $linesWithRC; exit 1 
    (( $? > $_SUCCESS_ )) && {
        printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
        return $_EXIT_ERROR_
    }

    # Clean
    echo $linesWithRC
    if (( $linesWithRC > 0 )); then
		executeCMD "dpkg -l | grep ^rc | awk '{ print \$2}' | sudo xargs dpkg --purge"
        return $?
	fi
    return $_SUCCESS_
}

# Update APT repository
function updateAPT() {
    dependencyAPPS apt
    exitError $?

    printMessages "Update Repository APT" 3

    executeCMD "sudo apt update"
	return $?
}

# Upgrade APT System
function upgradeAPT() {
    local error_code=$_SUCCESS_
    local upgradableApp

    # Validate
    dependencyAPPS apt
    exitError $?

    printMessages "Upgrade APP APT" 3

	# Upgrade System
	while [ 1 ]; do
        upgradableApp=$(executeCMD "sudo apt list --upgradable | grep -c ." 1)
        error_code=$?
        (( $error_code > $_SUCCESS_ )) && {
            printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
            return $error_code
        }
        
		# Check if have new package
		if (( upgradableApp < 2 )); then
			break
		fi

        # Upgrade
        executeCMD "sudo apt upgrade -y"
        error_code=$?
        (( $error_code > $_SUCCESS_ )) && {
            printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
            return $error_code
        }
	done
    printMessages "DONE" 1
    return $_SUCCESS_
}

# Get List of App APT Installed
function installedAPT() {
    dependencyAPPS apt
    exitError $?

    [[ -z "$1" ]] && {
        apt list --installed 2>/dev/null
        return $?
    } || {
        apt -qq list "$1" --installed 2>/dev/null
        return $?
    }
}

# Install/Uninstall APT PPA
function repositoryAPT() {
    local operation="$1"; shift
    local cmd
    local runUpdate=0
    local errorPPA
    local countFail=0
    local existPPA
    local cmdRun

    dependencyAPPS apt
    exitError $?

    case "$operation" in
        i)
            cmd="sudo add-apt-repository ppa:%REPOSITORY% -y"
            errorPPA="INSTALL FAIL REPOSITORY: "
        ;;
        u)
            cmd="sudo add-apt-repository -r ppa:%REPOSITORY% -y"
            errorPPA="UNINSTALL FAIL REPOSITORY: "
        ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_EXIT_ERROR_ ;;
    esac

    for repository in "$@"; do
        if [ ! -z "$(echo "$repository" | cut -d ":" -f2)" ]; then
            ppa="$(echo "$repository" | cut -d ":" -f2)"
        fi
        existPPA=$(grep "^deb .*$repository" /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -c .)
        cmdRun="${cmd/\%REPOSITORY\%/$repository}"

        case "$operation" in
            i)
                (( $existPPA == 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on install $repository" 4 "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository installed" 1; runUpdate=1 
                } || printMessages "REPOSITORY $repository already exist!!!" 2
            ;;
            u)
                (( $existPPA > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on uninstall $repository" 4 "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository uninstalled" 1; runUpdate=1
                } ||  printMessages "REPOSITORY $repository not exist!!!" 2
            ;;
        esac
    done

    # Update Lib APT
    (( $runUpdate > $_SUCCESS_ )) && {
        updateAPT
        local error_code=$?
        (( $error_code > $_SUCCESS_ )) && return $error_code
    }
    (( $countFail > 0 )) && printMessages "$errorPPA" 2; return $_EXIT_ERROR_
    return $_SUCCESS_
}

# Install/Uninstall APT APP
function appAPT() {
    local operation="$1"; shift
    local cmd
    local errorAPP
    local countFail=0

    dependencyAPPS apt
    exitError $?

    case "$operation" in
        i-no-recommends)
            cmd="sudo apt install --no-install-recommends %APP% -y"
            errorAPP="INSTALL FAIL APP: "
        ;;
        i)
            cmd="sudo apt install %APP% -y"
            errorAPP="INSTALL FAIL APP: "
        ;;
        u)
            cmd="sudo apt purge --auto-remove %APP% -y && sudo apt clean %APP%"
            errorAPP="UNINSTALL FAIL APP: "
        ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_EXIT_ERROR_ ;;
    esac

    for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"

        case "$operation" in
            i|i-no-recommends)
                (( $isInstalled == 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app installed" 1
                } || printMessages "APP $app already installed!!!" 2
            ;;
            u)
                (( $isInstalled > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on uninstall $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app uninstalled" 1
                } || printMessages "APP $ppa not installed!!!" 2
            ;;
        esac
    done
    (( $countFail > 0 )) && printMessages "$errorAPP" 2; return $_EXIT_ERROR_
    return $_SUCCESS_
}

: '
####################### DEB/RPM/GNOME_SHELL_EXT AREA #######################
'
# Install DEB Files
function debFiles() {
    local errorDEB="INSTALL FAIL DEB: "
    local countFail=0
    local cmd="sudo gdebi -n %APP%"

    dependencyAPPS deb
    exitError $?

    for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"
        (( $isInstalled == 0 )) && {
            executeCMD "$cmdRun"
            (( $? > $_SUCCESS_ )) && {
                printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                errorDEB="$errorDEB $ppa; "
                countFail=$((countFail+1))
            } || printMessages "$app installed" 1
        } || printMessages "APP $app already installed!!!" 2
    done
    (( $countFail > 0 )) && printMessages "$errorDEB" 2; return $_EXIT_ERROR_
    return $_SUCCESS_
}

# Install RPM Files
function rpmFiles() {
    local errorRPM="INSTALL FAIL RPM: "
    local countFail=0
    local cmd="sudo alien -i %APP%"

    dependencyAPPS rpm
    exitError $?

	for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"
        (( $isInstalled == 0 )) && {
            executeCMD "$cmdRun"
            (( $? > $_SUCCESS_ )) && {
                printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                errorRPM="$errorRPM $ppa; "
                countFail=$((countFail+1))
            } || printMessages "$app installed" 1
        } || printMessages "APP $app already installed!!!" 2
    done
    (( $countFail > 0 )) && printMessages "$errorRPM" 2; return $_EXIT_ERROR_
    return $_SUCCESS_
}

# Install Gnome Shell Extension
function gnomeShellExtensions() {
    local errorGNOME_EXT="INSTALL FAIL GNOME EXTENSION: "
    local homePath="$(echo $HOME)"
    local extensionsPath="$homePath/.local/share/gnome-shell/extensions"
    local uuid=""
    local countFail=0

    dependencyAPPS gnome-shell-ext
    exitError $?

    for extension in "$@"; do
        uuid="$(unzip -c "$zipFile" metadata.json | grep uuid | cut -d \" -f4)"
        if [ ! -z $uuid ]; then
            local error_code
            # Create extension path
            executeCMD "mkdir -p \"$extensionsPath/$uuid\""
            $error_code=$?

            # Extract zip Extension data
            (( $error_code < $_EXIT_ERROR_ )) && {
                executeCMD "unzip -q \"$extension\" -d \"$extensionsPath/$uuid/\""
                error_code=$?

                # Install extension
                (( $error_code < $_EXIT_ERROR_ )) && {
                    executeCMD "gnome-shell-extension-tool -e \"$uuid\""
                    $error_code=$?
                }
            }

            (( $error_code > $_SUCCESS_ )) && {
                printMessages "Error on install $extension" 4 ${FUNCNAME[0]}
                errorGNOME_EXT="$errorGNOME_EXT $extension; "
                countFail=$((countFail+1))
            } || printMessages "$extension installed" 1
        else
            printMessages "ERROR: Failed on get UUID from extension: $extension" 4
        fi
    done
    (( $countFail > 0 )) && printMessages "$errorGNOME_EXT" 2; return $_EXIT_ERROR_
    return $_SUCCESS_
}

: '
####################### SNAP AREA #######################
'
# Update Snap repository
function updateSNAP() {
    dependencyAPPS snap
    exitError $?

    printMessages "Update/Upgrade Repository/APP SNAP" 3

    executeCMD "sudo snap refresh"
	return $?
}

# Get List of App SNAP Installed
function installedSNAP() {
    dependencyAPPS snap
    exitError $?

    [[ -z "$1" ]] && {
        snap list | awk '{if (NR!=1) {print $1}}'
        return $?
    } || {
        snap list | awk '{if (NR!=1) {print $1}}' | grep -i "^$1"
        return $?
    }
}

# Install/Uninstall SNAP APP
function appSNAP() {
    local operation="$1"; shift
    local cmd
    local errorAPP
    local countFail=0

    dependencyAPPS snap
    exitError $?

    case "$operation" in
        i|i-classic)
            cmd="sudo snap install %APP%"
            errorAPP="INSTALL FAIL APP: "
        ;;
        u)
            cmd="sudo snap remove %APP%"
            errorAPP="UNINSTALL FAIL APP: "
        ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_EXIT_ERROR_ ;;
    esac

    for app in "$@"; do
        local isInstalled=$(installedSNAP $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"
        local error_code

        case "$operation" in
            i|i-classic)
                (( $isInstalled == 0 )) && {
                    if [ "$operation" = "i-classic" ]; then
                        executeCMD "$cmdRun --classic"
                        error_code=$?
                    else
                        executeCMD "$cmdRun"
                        error_code=$?
                    fi
                    (( $error_code > $_SUCCESS_ )) && {
                        printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app installed" 1
                } || printMessages "APP $app already installed!!!" 2
            ;;
            u)
                (( $isInstalled > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on uninstall $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app uninstalled" 1
                } || printMessages "APP $ppa not installed!!!" 2
            ;;
        esac
    done
    (( $countFail > 0 )) && printMessages "$errorAPP" 2; return $_EXIT_ERROR_
    return $_SUCCESS_
}

: '
####################### FLATPAK AREA #######################
'
# Update FLATPAK repository
function updateFLATPAK() {
    dependencyAPPS flatpak
    exitError $?

    printMessages "Update/Upgrade Repository/APP FLATPAK" 3

    executeCMD "flatpak update || torsocks flatpak update"
	return $?
}

# Get List of App FLATPAK Installed
function installedFLATPAK() {
    dependencyAPPS flatpak
    exitError $?

    [[ -z "$1" ]] && {
        flatpak list --all | awk '{if (NR!=1) {print $1}}'
        return $?
    } || {
        flatpak list --all | awk '{if (NR!=1) {print $1}}' | grep -i "^$nameApp"
        return $?
    }
}

# Install/Uninstall FLATPAK APP
function repositoryFLATPAK() {
    local operation="$1"; shift
    local cmd
    local runUpdate=0
    local errorPPA
    local countFail=0

    dependencyAPPS flatpak
    exitError $?

    case "$operation" in
        i)
            cmd="flatpak remote-add --if-not-exists %REPOSITORY%"
            cmd="${cmd} || torsocks ${cmd}"
            errorPPA="INSTALL FAIL REPOSITORY: "
        ;;
        u)
            cmd="flatpak remote-delete %REPOSITORY%"
            cmd="${cmd} || torsocks ${cmd}"
            errorPPA="UNINSTALL FAIL REPOSITORY: "
        ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_EXIT_ERROR_ ;;
    esac

    for repository in "$@"; do
        local existPPA=$(flatpak remote-list | awk '{if (NR!=0) {print $1}}' | grep -i "$repository" | grep -c .)
        local cmdRun="${cmd/\%REPOSITORY\%/$repository}"

        case "$operation" in
            i)
                (( $existPPA == 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on install $repository" 4 "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository installed" 1; runUpdate=1 
                } || printMessages "PPA $repository already exist!!!" 2
            ;;
            u)
                (( $existPPA > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on uninstall $repository" 4 "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository uninstalled" 1; runUpdate=1 
                } ||  printMessages "PPA $repository not exist!!!" 2
            ;;
        esac
    done

    # Update Lib
    (( $runUpdate > 0 )) && updateFLATPAK
    (( $countFail > 0 )) && printMessages "$errorPPA" 2; return $_EXIT_ERROR_
}

# Install FLATPAK APP
function appFLATPAK() {
    local operation="$1"; shift
    local cmd
    local errorAPP
    local countFail=0

    dependencyAPPS flatpak
    exitError $?

    case "$operation" in
        i)
            cmd="flatpak install %APP%"
            cmd="${cmd} || torsocks ${cmd}"
            errorAPP="INSTALL FAIL APP: "
        ;;
        u)
            cmd="flatpak uninstall %APP%"
            cmd="${cmd} || torsocks ${cmd}"
            errorAPP="UNINSTALL FAIL APP: "
        ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_EXIT_ERROR_ ;;
    esac

    for app in "$@"; do
        local isInstalled=$(installedFLATPAK $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"

        case "$operation" in
            i)
                (( $isInstalled == 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app installed" 1
                } || printMessages "APP $app already installed!!!" 2
            ;;
            u)
                (( $isInstalled > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_SUCCESS_ )) && {
                        printMessages "Error on uninstall $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app uninstalled" 1
                } || printMessages "APP $ppa not installed!!!" 2
            ;;
        esac
    done
    (( $countFail > 0 )) && printMessages "$errorAPP" 2; return $_EXIT_ERROR_
    return $_SUCCESS_
}

: '
####################### OTHERS AREA #######################
'
# Fix Locale Package
function fixLocalePackage() {
    local errorCode=0
    local localeLang
    local language_all_package
    local -a dependencies=("locale" "check-language-support")

    for dependency in "${dependencies[@]}"; do
        isCommandExist "$dependency"
        errorCode=$?
        (( $errorCode > 0 )) && {
            printMessages "Install language-selector-common" 4 "${FUNCNAME[0]}"
            exitError "$errorCode"
        }
    done
    
    printMessages "Fix Locale Package" 3
	localeLang="$(locale | grep LANGUAGE | cut -d '=' -f2- | cut -d ':' -f1)"
    if [ -n "$localeLang" ]; then
        language_all_package="$(check-language-support -l $lacaleLang)"
        appAPT i "$language_all_package"
    fi
}

function upgradeSystem() {
    local validArguments=0
    case "$1" in
        apt|snap|flatpak|all) validArguments=1 ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_EXIT_ERROR_ ;;
    esac
    
    dependencyAPPS apt
    exitError $?

    # Always execute update for APT
    updateAPT

    # Upgrade all APP APT
    if [ "$1" = "apt" ]||[ "$1" = "all" ]; then
        fixLocalePackage
        upgradeAPT
        cleanSystemAPT
    fi

    # Upgrade all APP SNAP
    if [ "$1" = "snap" ]||[ "$1" = "all" ]; then
        dependencyAPPS snap
        (( $? < 1 )) && updateSNAP
    fi

    # Upgrade all APP FLATPAK
    if [ "$1" = "flatpak" ]||[ "$1" = "all" ]; then
        dependencyAPPS flatpak
        (( $? < 1 )) && updateFLATPAK
    fi
    printMessages "DONE" 1
}

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
    # APT
    apt-clean) cleanSystemAPT ;;
    apt-update) updateAPT ;;
    apt-upgrade) upgradeAPT ;;
    apt-installed) installedAPT "$@" ;;
    apt-repository) repositoryAPT "$@" ;;
    apt-app) appAPT "$@" ;;

    # DEB/RPM/Gnome Shell EXT
    deb-files) debFiles "$@" ;;
    rpm-files) rpmFiles "$@" ;;
    gnome-shell-extensions) gnomeShellExtensions "$@" ;;

    # Snap
    snap-update) updateSNAP ;;
    snap-installed) installedSNAP "$@" ;;
    snap-app) appSNAP "$@" ;;

    # Flatpak
    flatpak-update) updateFLATPAK ;;
    flatpak-installed) installedFLATPAK "$@" ;;
    flatpak-repository) repositoryFLATPAK "$@" ;;
    flatpak-app) appFLATPAK "$@" ;;

    # OTHERS
    system-upgrade) upgradeSystem "$@" ;;
    fix-locale-package) fixLocalePackage ;;
    pid-kill) killPID "$@" ;;
esac
