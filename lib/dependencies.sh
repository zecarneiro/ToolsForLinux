#!/bin/bash
# Author: José M. C. Noronha

declare _DEPENDENCY_SUDO_="sudo"
declare -a _DEPENDENCY_APT_=("$_DEPENDENCY_SUDO_" "add-apt-repository" "apt" "dpkg")
declare -a _DEPENDENCY_DEB_=("$_DEPENDENCY_SUDO_" "gdebi")
declare -a _DEPENDENCY_RPM_=("$_DEPENDENCY_SUDO_" "alien")
declare -a _DEPENDENCY_GNOME_SHELL_EXT_=("unzip" "gnome-shell-extension-tool")
declare -a _DEPENDENCY_SNAP_=("$_DEPENDENCY_SUDO_" "snapd" "snapd-xdg-open")
declare -a _DEPENDENCY_FLATPAK_=("torsocks" "flatpak" "xdg-desktop-portal-gtk" "gnome-software-plugin-flatpak")

function dependencyAPPS() {
    local _sudo_="sudo"
    local -a dependencyArray
    case "$1" in
        apt) dependencyArray=("${_DEPENDENCY_APT_[@]}") ;;
        deb) dependencyArray=("${_DEPENDENCY_DEB_[@]}") ;;
        rpm) dependencyArray=("${_DEPENDENCY_SUDO_[@]}") ;;
        gnome-shell-ext) dependencyArray=("${_DEPENDENCY_GNOME_SHELL_EXT_[@]}") ;;
        snap) dependencyArray=("${_DEPENDENCY_SNAP_[@]}") ;;
        flatpak) dependencyArray=("${_DEPENDENCY_FLATPAK_[@]}") ;;
        *) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_EXIT_ERROR_ ;;
    esac
    
    for dependency in "${dependencyArray[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        (( $? > $_SUCCESS_ )) && return $_EXIT_ERROR_
    done
    return $_SUCCESS_
}