#!/bin/bash
# Author: José M. C. Noronha

declare _DEPENDENCY_SUDO_="sudo"
declare -a _DEPENDENCY_APT_=("$_DEPENDENCY_SUDO_" "add-apt-repository" "apt" "dpkg")
declare -a _DEPENDENCY_DEB_=("$_DEPENDENCY_SUDO_" "gdebi")
declare -a _DEPENDENCY_RPM_=("$_DEPENDENCY_SUDO_" "alien")
declare -a _DEPENDENCY_GNOME_SHELL_EXT_=("unzip" "gnome-shell-extension-tool")
declare -a _DEPENDENCY_SNAP_=("$_DEPENDENCY_SUDO_" "snapd" "snapd-xdg-open")
declare -a _DEPENDENCY_FLATPAK_=("torsocks" "flatpak" "xdg-desktop-portal-gtk" "gnome-software-plugin-flatpak")
declare -a _DEPENDENCY_LOCALE_PACKAGE_=("locale" "check-language-support")
declare -a _DEPENDENCY_DCONF_=("dconf")
declare -a _DEPENDENCY_WGET_=("wget")

function installDependencies() {
    local typeInstall="$1"
    local typeInstallAll="all"

    . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-update

    # DEB
    if [ "$typeInstall" = "deb" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        printMessages "Install Dependency for DEB" 3
        . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i ${_DEPENDENCY_DEB_[1]}
    fi

    # RPM
    if [ "$typeInstall" = "rpm" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        printMessages "Install Dependency for RPM" 3
        . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i ${_DEPENDENCY_RPM_[1]} 
    fi

    # GNOME-SHELL-EXT
    if [ "$typeInstall" = "gnome-shell-ext" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        printMessages "Install Dependency for GNOME-SHELL-EXT" 3
        . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i ${_DEPENDENCY_GNOME_SHELL_EXT_[0]}
    fi

    # SNAP
    if [ "$typeInstall" = "snap" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        printMessages "Install Dependency for SNAP" 3
        . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i ${_DEPENDENCY_SNAP_[1]} ${_DEPENDENCY_SNAP_[2]}

        serv_snap_active=$(. "$_SRC_/${_SUBCOMMANDS_[0]}.sh" is-service-active snapd)

         # Start Snap
        if [ "$serv_snap_active" = "$_FALSE_" ]; then
            sudo service snapd start
        fi
    fi

    # FLATPAK
    if [ "$typeInstall" = "flatpak" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        printMessages "Install Dependency for FLATPAK" 3
        . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i "${_DEPENDENCY_FLATPAK_[@]}"
    fi

    # LOCALE-PACKAGE
    if [ "$typeInstall" = "locale-package" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        printMessages "Install Dependency for LOCALE-PACKAGE" 3
        . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i "language-selector-common"
    fi

    # DCONF-EDITOR
    if [ "$typeInstall" = "locale-package" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        printMessages "Install Dependency for DCONF-EDITOR" 3
        . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i "${_DEPENDENCY_DCONF_[@]}"
    fi

    # WGET
    if [ "$typeInstall" = "wget" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        printMessages "Install Dependency for WGET" 3
        . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-app i "${_DEPENDENCY_WGET_[@]}"
    fi
    printMessages "Done" 1
}

function validateDependencies() {
    local -a dependencyArray
    case "$1" in
        apt) dependencyArray=("${_DEPENDENCY_APT_[@]}") ;;
        deb) dependencyArray=("${_DEPENDENCY_DEB_[@]}") ;;
        rpm) dependencyArray=("${_DEPENDENCY_SUDO_[@]}") ;;
        gnome-shell-ext) dependencyArray=("${_DEPENDENCY_GNOME_SHELL_EXT_[@]}") ;;
        snap) dependencyArray=("${_DEPENDENCY_SNAP_[@]}") ;;
        flatpak) dependencyArray=("${_DEPENDENCY_FLATPAK_[@]}") ;;
        locale-package) dependencyArray=("${_DEPENDENCY_LOCALE_PACKAGE_[@]}") ;;
        dconf) dependencyArray=("${_DEPENDENCY_DCONF_[@]}") ;;
        wget) dependencyArray=("${_DEPENDENCY_WGET_[@]}") ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
    esac
    
    for dependency in "${dependencyArray[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        (( $? > $_CODE_EXIT_SUCCESS_ )) && return $_CODE_EXIT_ERROR_
    done
    return $_CODE_EXIT_SUCCESS_
}