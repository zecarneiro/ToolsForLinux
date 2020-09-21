#!/bin/bash
# Author: José M. C. Noronha

: '
####################### APT AREA #######################
'
# Clear all APT app data and uninstall unecessary apt apps
function cleanSystemAPT() {
    local -i linesWithRC
    local listDPKG
    local errorcode
    local homeDir="$(echo $HOME)"

    printMessages "Clean System for APT" 3

    validateDependencies apt
    exitError $?

    executeCMD "sudo apt autoremove -y"
    exitError $?
    
    listDPKG="$( executeCMD "dpkg --list" 1 )"
    errorcode=$?
    (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
        return $errorcode
    }    

    # Clean
    linesWithRC="$(echo "$listDPKG" | grep -c ^rc )"
    if (( $linesWithRC > 0 )); then
		dpkg -l | grep ^rc | awk '{ print $2}' | sudo xargs dpkg --purge
        return $?
	fi
    return $_CODE_EXIT_SUCCESS_
}

# Update APT repository
function updateAPT() {
    validateDependencies apt
    exitError $?

    printMessages "Update Repository APT" 3

    executeCMD "sudo apt update"
	return $?
}

# Upgrade APT System
function upgradeAPT() {
    local errorcode
    local upgradableApp
    local -i countUpgradableApp

    # Validate
    validateDependencies apt
    exitError $?

    printMessages "Upgrade APP APT" 3

	# Upgrade System
	while [ 1 ]; do
        upgradableApp=$(executeCMD "sudo apt list --upgradable" 1)
        errorcode=$?
        (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
            printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
            return $errorcode
        }
        
		# Check if have new package
        countUpgradableApp="$( echo "$upgradableApp" | grep -c . )"
		if (( countUpgradableApp < 2 )); then
			break
		fi

        # Upgrade
        executeCMD "sudo apt upgrade -y"
        errorcode=$?
        (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
            printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
            return $errorcode
        }
	done
    printMessages "DONE" 1
    return $_CODE_EXIT_SUCCESS_
}

# 
: '
    Get List of App APT Installed

    ARGS:
    app =       $1  (OPTIONAL)
'
function installedAPT() {
    validateDependencies apt
    exitError $?

    [[ -z "$1" ]] && {
        apt list --installed 2>/dev/null
        return $?
    } || {
        apt -qq list "$1" --installed 2>/dev/null
        return $?
    }
}

: '
    Install/Uninstall APT PPA

    ARGS:
    operation =     $1      (i|u)
    ppa =           $@
'
function repositoryAPT() {
    local operation="$1"; shift
    local cmd
    local runUpdate=0
    local errorPPA
    local countFail=0
    local existPPA
    local cmdRun

    validateDependencies apt
    exitError $?

    case "$operation" in
        i)
            cmd="sudo add-apt-repository ppa:%REPOSITORY% -y --no-update"
            errorPPA="INSTALL FAIL REPOSITORY: "
        ;;
        u)
            cmd="sudo add-apt-repository -r ppa:%REPOSITORY% -y"
            errorPPA="UNINSTALL FAIL REPOSITORY: "
        ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_CODE_EXIT_ERROR_ ;;
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
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on install $repository" 4 "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository installed" 1; runUpdate=1 
                } || printMessages "REPOSITORY $repository already exist!!!" 2
            ;;
            u)
                (( $existPPA > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on uninstall $repository" 4 "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository uninstalled" 1; runUpdate=1
                } ||  printMessages "REPOSITORY $repository not exist!!!" 2
            ;;
        esac
    done

    # Update Lib APT
    (( $runUpdate == 1 )) && {
        updateAPT
        local errorcode=$?
        (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && return $errorcode
    }
    (( $countFail > 0 )) && printMessages "$errorPPA" 2; return $_CODE_EXIT_ERROR_
    return $_CODE_EXIT_SUCCESS_
}

: '
    Install/Uninstall APT APP

    ARGS:
    operation =     $1      (i|u)
    apps =          $@
'
function appAPT() {
    local operation="$1"; shift
    local cmd
    local errorAPP
    local countFail=0

    validateDependencies apt
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
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_CODE_EXIT_ERROR_ ;;
    esac

    for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"

        case "$operation" in
            i|i-no-recommends)
                (( $isInstalled == 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app installed" 1
                } || printMessages "APP $app already installed!!!" 2
            ;;
            u)
                (( $isInstalled > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on uninstall $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app uninstalled" 1
                } || printMessages "APP $ppa not installed!!!" 2
            ;;
        esac
    done
    (( $countFail > 0 )) && printMessages "$errorAPP" 2; return $_CODE_EXIT_ERROR_
    return $_CODE_EXIT_SUCCESS_
}

: '
####################### DEB/RPM/GNOME_SHELL_EXT AREA #######################
'
: '
    Install DEB Files

    ARGS:
    deb =          $@
'
function debFiles() {
    local errorDEB="INSTALL FAIL DEB: "
    local countFail=0
    local cmd="sudo gdebi -n %APP%"

    validateDependencies deb
    exitError $?

    for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"
        (( $isInstalled == 0 )) && {
            executeCMD "$cmdRun"
            (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                errorDEB="$errorDEB $ppa; "
                countFail=$((countFail+1))
            } || printMessages "$app installed" 1
        } || printMessages "APP $app already installed!!!" 2
    done
    (( $countFail > 0 )) && printMessages "$errorDEB" 2; return $_CODE_EXIT_ERROR_
    return $_CODE_EXIT_SUCCESS_
}

: '
    Install RPM Files

    ARGS:
    rpm =          $@
'
function rpmFiles() {
    local errorRPM="INSTALL FAIL RPM: "
    local countFail=0
    local cmd="sudo alien -i %APP%"

    validateDependencies rpm
    exitError $?

	for app in "$@"; do
        local isInstalled=$(installedAPT $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"
        (( $isInstalled == 0 )) && {
            executeCMD "$cmdRun"
            (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                errorRPM="$errorRPM $ppa; "
                countFail=$((countFail+1))
            } || printMessages "$app installed" 1
        } || printMessages "APP $app already installed!!!" 2
    done
    (( $countFail > 0 )) && printMessages "$errorRPM" 2; return $_CODE_EXIT_ERROR_
    return $_CODE_EXIT_SUCCESS_
}

: '
    Install Gnome Shell Extension

    ARGS:
    gnome_shell_ext =          $@
'
function gnomeShellExtensions() {
    local errorGNOME_EXT="INSTALL FAIL GNOME EXTENSION: "
    local homePath="$(echo $HOME)"
    local extensionsPath="$homePath/.local/share/gnome-shell/extensions"
    local uuid=""
    local countFail=0

    validateDependencies gnome-shell-ext
    exitError $?

    # TODO: Validate error code for unzip and gnome-shell-extension-tool
    for extension in "$@"; do
        uuid="$(unzip -c "$extension" metadata.json | grep uuid | cut -d \" -f4)"
        if [ ! -z $uuid ]; then
            local errorcode
            # Create extension path
            executeCMD "mkdir -p \"$extensionsPath/$uuid\""
            errorcode=$?

            # Extract zip Extension data
            (( $errorcode < $_CODE_EXIT_ERROR_ )) && {
                executeCMD "unzip -q \"$extension\" -d \"$extensionsPath/$uuid/\""
                errorcode=$?

                # Install extension
                (( $errorcode < $_CODE_EXIT_ERROR_ )) && {
                    executeCMD "gnome-shell-extension-tool -e \"$uuid\""
                    errorcode=$?
                }
            }

            (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
                printMessages "Error on install $extension" 4 ${FUNCNAME[0]}
                errorGNOME_EXT="$errorGNOME_EXT $extension; "
                countFail=$((countFail+1))
            } || printMessages "$extension installed" 1
        else
            printMessages "ERROR: Failed on get UUID from extension: $extension" 4
        fi
    done
    (( $countFail > 0 )) && printMessages "$errorGNOME_EXT" 2; return $_CODE_EXIT_ERROR_
    return $_CODE_EXIT_SUCCESS_
}

: '
####################### SNAP AREA #######################
'
# Update Snap repository
function updateSNAP() {
    validateDependencies snap
    exitError $?

    printMessages "Update/Upgrade Repository/APP SNAP" 3

    executeCMD "sudo snap refresh"
	return $?
}

: '
    Get List of App SNAP Installed

    ARGS:
    app =       $1      (OPTIONAL)
'
function installedSNAP() {
    validateDependencies snap
    exitError $?

    [[ -z "$1" ]] && {
        snap list | awk '{if (NR!=1) {print $1}}'
        return $?
    } || {
        snap list | awk '{if (NR!=1) {print $1}}' | grep -i "^$1"
        return $?
    }
}

: '
    Install/Uninstall SNAP APP

    ARGS:
    operation =       $1      (i|i-classic|u)
    apps =            $@
'
function appSNAP() {
    local operation="$1"; shift
    local cmd
    local errorAPP
    local countFail=0

    validateDependencies snap
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
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_CODE_EXIT_ERROR_ ;;
    esac

    # TODO: Validate error code for snap
    for app in "$@"; do
        local isInstalled=$(installedSNAP $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"
        local errorcode

        case "$operation" in
            i|i-classic)
                (( $isInstalled == 0 )) && {
                    if [ "$operation" = "i-classic" ]; then
                        executeCMD "$cmdRun --classic"
                        errorcode=$?
                    else
                        executeCMD "$cmdRun"
                        errorcode=$?
                    fi
                    (( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app installed" 1
                } || printMessages "APP $app already installed!!!" 2
            ;;
            u)
                (( $isInstalled > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on uninstall $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app uninstalled" 1
                } || printMessages "APP $ppa not installed!!!" 2
            ;;
        esac
    done
    (( $countFail > 0 )) && printMessages "$errorAPP" 2; return $_CODE_EXIT_ERROR_
    return $_CODE_EXIT_SUCCESS_
}

: '
####################### FLATPAK AREA #######################
'
# Update/Upgrade Repository
function updateFLATPAK() {
    validateDependencies flatpak
    exitError $?

    printMessages "Update/Upgrade Repository/APP FLATPAK" 3

    executeCMD "flatpak update || torsocks flatpak update"
	return $?
}

: '
    Get List of App FLATPAK Installed

    ARGS:
    app =       $1      (OPTIONAL)
'
function installedFLATPAK() {
    validateDependencies flatpak
    exitError $?

    [[ -z "$1" ]] && {
        flatpak list --all | awk '{if (NR!=1) {print $1}}'
        return $?
    } || {
        flatpak list --all | awk '{if (NR!=1) {print $1}}' | grep -i "^$nameApp"
        return $?
    }
}

: '
    Install/Uninstall FLATPAK Repository

    ARGS:
    operation =     $1      (i|u)
    repository =    $@
'
function repositoryFLATPAK() {
    local operation="$1"; shift
    local cmd
    local runUpdate=0
    local errorPPA
    local countFail=0

    validateDependencies flatpak
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
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_CODE_EXIT_ERROR_ ;;
    esac

    # TODO: Validate error code for flatpak
    for repository in "$@"; do
        local existPPA=$(flatpak remote-list | awk '{if (NR!=0) {print $1}}' | grep -i "$repository" | grep -c .)
        local cmdRun="${cmd/\%REPOSITORY\%/$repository}"

        case "$operation" in
            i)
                (( $existPPA == 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on install $repository" 4 "${FUNCNAME[0]}"
                        errorPPA="$errorPPA $repository; "
                        countFail=$((countFail+1))
                    } || printMessages "$repository installed" 1; runUpdate=1 
                } || printMessages "PPA $repository already exist!!!" 2
            ;;
            u)
                (( $existPPA > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
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
    (( $countFail > 0 )) && printMessages "$errorPPA" 2; return $_CODE_EXIT_ERROR_
}

: '
    Install/Uninstall FLATPAK APP

    ARGS:
    operation =     $1      (i|u)
    app =           $@
'
function appFLATPAK() {
    local operation="$1"; shift
    local cmd
    local errorAPP
    local countFail=0

    validateDependencies flatpak
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
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_CODE_EXIT_ERROR_ ;;
    esac

    # TODO: Validate error code for flatpak
    for app in "$@"; do
        local isInstalled=$(installedFLATPAK $app | grep -c .)
        local cmdRun="${cmd/\%APP\%/$app}"

        case "$operation" in
            i)
                (( $isInstalled == 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on install $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app installed" 1
                } || printMessages "APP $app already installed!!!" 2
            ;;
            u)
                (( $isInstalled > 0 )) && {
                    executeCMD "$cmdRun"
                    (( $? > $_CODE_EXIT_SUCCESS_ )) && {
                        printMessages "Error on uninstall $app" 4 ${FUNCNAME[0]}
                        errorAPP="$errorAPP $app; "
                        countFail=$((countFail+1))
                    } || printMessages "$app uninstalled" 1
                } || printMessages "APP $ppa not installed!!!" 2
            ;;
        esac
    done
    (( $countFail > 0 )) && printMessages "$errorAPP" 2; return $_CODE_EXIT_ERROR_
    return $_CODE_EXIT_SUCCESS_
}

: '
####################### OTHERS AREA #######################
'
# Fix Locale Package
function fixLocalePackage() {
    local errorCode=0
    local localeLang
    local language_all_package

    validateDependencies "locale-package"
    errorCode=$?
    (( $errorCode > $_CODE_EXIT_SUCCESS_ )) && {
        printMessages "Install language-selector-common" 4 "${FUNCNAME[0]}"
        exitError "$errorCode"
    }
    
    printMessages "Fix Locale Package" 3
	localeLang="$(locale | grep LANGUAGE | cut -d '=' -f2- | cut -d ':' -f1)"
    if [ -n "$localeLang" ]; then
        language_all_package="$(check-language-support -l $lacaleLang)"
        appAPT i "$language_all_package"
    fi
}

# Reload Gnome Shell
function reloadGnomeShell() {
    killall -3 gnome-shell
	(( $? > 0 )) && printMessages "Operations Fail" 4 ${FUNCNAME[0]} || printMessages "Done" 1
}

: '
    Update/Upgrade all apps(APT/SNAP/FLATPAK)

    ARGS:
    type =     $1      (apt|snap|flatpak|all)
'
function upgradeSystem() {
    local validArguments=0
    case "$1" in
        apt|snap|flatpak|all) validArguments=1 ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; exitError $_CODE_EXIT_ERROR_ ;;
    esac
    
    validateDependencies apt
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
        validateDependencies snap
        (( $? < 1 )) && updateSNAP
    fi

    # Upgrade all APP FLATPAK
    if [ "$1" = "flatpak" ]||[ "$1" = "all" ]; then
        validateDependencies flatpak
        (( $? < 1 )) && updateFLATPAK
    fi
    printMessages "DONE" 1
}

: '
    Check service is active or not

    ARGS:
    name_service =      $1
'
function isServiceActive() {
	local nameService="$1"
	local -i isActive

    [[ -z "$nameService" ]] && {
        printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"
        exitError $_CODE_EXIT_ERROR_
    }

    isActive=$(ps -e | grep -v grep | grep -c "$nameService")
    (( $isActive >= 1 )) && echo $_TRUE_ || echo $_FALSE_
}

: '
    Kill APP by PID

    ARGS:
    pid =      $1
'
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

: '
	Check your Graphic vendor

	ARGS:
	nameVendor = $1
'
function checkGraphicVendor() {
    local nameVendor="$1"
	local lspciData
	local errorcode
	local -i exist

	lspciData="$(executeCMD "lspci -v" 1)"
	errorcode=$?
	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
		printMessages "Operations Fail" 4 ${FUNCNAME[0]}
		exitError $errorcode
	}

    exist=$( echo "$lspciData" | grep -ci "$nameVendor" )
	(( $exist > 0 )) && echo $_TRUE_ || echo $_FALSE_
}

: '
####################### MAIN AREA #######################
'
function HELP() {
    local data=()
    export TOOLFORLINUX_TABLE_LENGTH_COLUMN="2"
    export TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR="50"
	local -a data=()

    echo -e "$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[1]} <subcommand>\n\nSubcommand:"
    data+=("apt-clean" "\"Clear all APT app data and uninstall unecessary apt apps\"")
    data+=("apt-update" "\"Update APT repository\"")
    data+=("apt-upgrade" "\"Upgrade APT System\"")
    data+=("\"apt-installed [APP]\"" "\"Get List of App APT Installed. APP if present only this app\"")
    data+=("\"apt-repository [i|u PPA1 PPA2...]\"" "\"Install/Uninstall APT PPA\"")
    data+=("\"apt-app [i|u APP1 APP2...]\"" "\"Install/Uninstall APT APP\"")

    data+=("%EMPTY_LINE%")
    data+=("\"deb-files [DEB1 DEB2...]\"" "\"Install DEB Files\"")
    data+=("\"rpm-files [RPM1 RPM2...]\"" "\"Install RPM Files\"")
    data+=("\"gnome-shell-extensions [GSEXT1 GSEXT2...]\"" "\"Install Gnome Shell Extension\"")
    
    data+=("%EMPTY_LINE%")
    data+=("snap-update" "\"Update Snap repository\"")
    data+=("\"snap-installed [APP]\"" "\"Get List of App SNAP Installed. APP if present only this app\"")
    data+=("\"snap-app [i|i-classic|u APP1 APP2...]\"" "\"Install/Uninstall SNAP APP\"")

    data+=("%EMPTY_LINE%")
    data+=("flatpak-update" "\"Update/Upgrade Repository\"")
    data+=("\"flatpak-installed [APP]\"" "\"Get List of App FLATPAK Installed. APP if present only this app\"")
    data+=("\"flatpak-repository [i|u REMOTE1 REMOTE2...]\"" "\"Install/Uninstall FLATPAK Repository\"")
    data+=("\"flatpak-app [i|u APP1 APP2...]\"" "\"Install/Uninstall FLATPAK APP\"")

    data+=("%EMPTY_LINE%")
    data+=("fix-locale-package" "\"Fix Locale Package\"")
    data+=("reload-gnome-shell" "\"Reload Gnome Shell if present\"")
    data+=("\"system-upgrade [apt|snap|flatpak|all]\"" "\"Update/Upgrade all apps(APT/SNAP/FLATPAK)\"")
    data+=("\"is-service-active [service_name]\"" "\"Check service is active or not\"")
    data+=("\"pid-kill [pid]\"" "\"Kill APP by PID\"")
    data+=("\"check-graphic-vendor [GRAPHIC_VENDOR]\"" "\"Check if graphic vendor is installed\"")

    data+=("%EMPTY_LINE%")
    data+=("help" "Help")
    
    . "$_SRC_/${_SUBCOMMANDS_[1]}.sh" create-table ${data[@]}
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
    fix-locale-package) fixLocalePackage ;;
    reload-gnome-shell) reloadGnomeShell ;;
    system-upgrade) upgradeSystem "$@" ;;
    is-service-active) isServiceActive "$@" ;;
    pid-kill) killPID "$@" ;;
    check-graphic-vendor) checkGraphicVendor "$@" ;;
    help) HELP ;;
    *)
        messageerror="$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[0]} help"
        printMessages "${_MESSAGE_RUN_HELP_/\%MSG\%/$messageerror}" 4 "${FUNCNAME[0]}"
        exitError $_CODE_EXIT_ERROR_
    ;;
esac
