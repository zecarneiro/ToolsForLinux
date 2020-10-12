#!/bin/bash
# Author: José M. C. Noronha

declare -A _DEPENDENCIES_APT_=(
    [app]=""
    [command]="add-apt-repository apt dpkg"
    [service]=""
)

declare -A _DEPENDENCIES_DEB_=(
    [app]="gdebi"
    [command]="gdebi"
    [service]=""
)

declare -A _DEPENDENCIES_RPM_=(
    [app]="alien"
    [command]="alien"
    [service]=""
)

declare -A _DEPENDENCIES_GNOME_SHELL_EXT_=(
    [app]="unzip"
    [command]="unzip gnome-shell-extension-tool"
    [service]=""
)

declare -A _DEPENDENCIES_SNAP_=(
    [app]="snapd snapd-xdg-open"
    [command]="snapd"
    [service]="snapd"
)

declare -A _DEPENDENCIES_FLATPAK_=(
    [app]="torsocks flatpak xdg-desktop-portal-gtk gnome-software-plugin-flatpak"
    [command]="torsocks flatpak"
    [service]=""
)

declare -A _DEPENDENCIES_LOCALE_PACKAGE_=(
    [app]="language-selector-common"
    [command]="locale check-language-support"
    [service]=""
)

declare -A _DEPENDENCIES_DCONF_=(
    [app]="dconf-editor dconf-tools"
    [command]="dconf"
    [service]=""
)

declare -A _DEPENDENCIES_WGET_=(
    [app]="wget"
    [command]="wget"
    [service]=""
)

declare -A _DEPENDENCIES_MD_FILE_=(
    [app]="pandoc lynx"
    [command]="pandoc lynx"
    [service]=""
)

declare -A _DEPENDENCIES_DOS2UNIX_=(
    [app]="dos2unix"
    [command]="dos2unix"
    [service]=""
)

function installDependencies() {
    local namePrint="Dependencies"
    local -a appsToInstallAPT=()
    local -a serviceToStart=()

    showMessages "Install $namePrint" 3
    #. "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-update

    # Prepare all APPS
    appsToInstallAPT+=(${_DEPENDENCIES_DEB_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_RPM_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_GNOME_SHELL_EXT_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_SNAP_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_FLATPAK_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_LOCALE_PACKAGE_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_DCONF_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_WGET_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_MD_FILE_[app]})
    appsToInstallAPT+=(${_DEPENDENCIES_DOS2UNIX_[app]})

    # Prepare all SERVICES
    serviceToStart+=(${_DEPENDENCIES_SNAP_[service]})

    # INSTALL ALL APPS
    . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i "${appsToInstallAPT[@]}"
    

    # Run Services
    for service in "${serviceToStart[@]}"; do
        local serv_snap_active=$(. "$_SRC_/${_SUBCOMMANDS_[0]}.sh" is-service-active $service)

        # Start Snap
        if [ "$serv_snap_active" = "$_FALSE_" ]; then
            sudo service $service start
        fi
    done
    showMessages "$namePrint Done" 1
}

function validateDependencies() {
    local -a dependencyArray
    case "$1" in
        apt) dependencyArray=(${_DEPENDENCIES_APT_[command]}) ;;
        deb) dependencyArray=(${_DEPENDENCIES_DEB_[command]}) ;;
        rpm) dependencyArray=(${_DEPENDENCIES_RPM_[command]}) ;;
        gnome-shell-ext) dependencyArray=(${_DEPENDENCIES_GNOME_SHELL_EXT_[command]}) ;;
        snap) dependencyArray=(${_DEPENDENCIES_SNAP_[command]}) ;;
        flatpak) dependencyArray=(${_DEPENDENCIES_FLATPAK_[command]}) ;;
        locale-package) dependencyArray=(${_DEPENDENCIES_LOCALE_PACKAGE_[command]}) ;;
        dconf) dependencyArray=(${_DEPENDENCIES_DCONF_[command]}) ;;
        wget) dependencyArray=(${_DEPENDENCIES_WGET_[command]}) ;;
        md-file) dependencyArray=(${_DEPENDENCIES_MD_FILE_[command]}) ;;
        dos-to-unix) dependencyArray=(${_DEPENDENCIES_DOS2UNIX_[command]}) ;;
        *) showMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
    esac
    
    for dependency in "${dependencyArray[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        (( $? > $_CODE_EXIT_SUCCESS_ )) && return $_CODE_EXIT_ERROR_
    done
    return $_CODE_EXIT_SUCCESS_
}