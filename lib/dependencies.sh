#!/bin/bash
# Author: José M. C. Noronha

function installDependencies() {
    local typeInstall="$1"
    local typeInstallAll="all"
    local namePrint="Dependencies"
    local -a appsToInstallAPT=()
    local -a serviceToStart=()

    showMessages "Install $namePrint" 3
    . "$_SRC_/${_SUBCOMMANDS_[0]}.sh" apt-update

    # DEB
    if [ "$typeInstall" = "deb" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("gdebi")
    fi

    # RPM
    if [ "$typeInstall" = "rpm" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("alien")
    fi

    # GNOME-SHELL-EXT
    if [ "$typeInstall" = "gnome-shell-ext" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("unzip")
    fi

    # SNAP
    if [ "$typeInstall" = "snap" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("snapd" "snapd-xdg-open")
        serviceToStart+=("snapd")
    fi

    # FLATPAK
    if [ "$typeInstall" = "flatpak" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("torsocks" "flatpak" "xdg-desktop-portal-gtk" "gnome-software-plugin-flatpak")
    fi

    # LOCALE-PACKAGE
    if [ "$typeInstall" = "locale-package" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("language-selector-common")
    fi

    # DCONF-EDITOR
    if [ "$typeInstall" = "dconf" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("dconf-editor")
    fi

    # WGET
    if [ "$typeInstall" = "wget" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("wget")
    fi

    # GIT
    if [ "$typeInstall" = "git" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("git")
    fi

    # MD-FILE
    if [ "$typeInstall" = "md-file" ]||[ "$typeInstall" = "$typeInstallAll" ]; then
        appsToInstallAPT+=("pandoc" "lynx")
    fi

    # Install APT
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
        apt) dependencyArray=("add-apt-repository" "apt" "dpkg") ;;
        deb) dependencyArray=("gdebi") ;;
        rpm) dependencyArray=("alien") ;;
        gnome-shell-ext) dependencyArray=("unzip" "gnome-shell-extension-tool") ;;
        snap) dependencyArray=("snap") ;;
        flatpak) dependencyArray=("torsocks" "flatpak") ;;
        locale-package) dependencyArray=("locale" "check-language-support") ;;
        dconf) dependencyArray=("dconf") ;;
        wget) dependencyArray=("wget") ;;
        git) dependencyArray=("git") ;;
        md-file) dependencyArray=("pandoc" "lynx") ;;
        *) showMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
    esac
    
    for dependency in "${dependencyArray[@]}"; do
        isCommandExist $dependency ${FUNCNAME[0]}
        (( $? > $_CODE_EXIT_SUCCESS_ )) && return $_CODE_EXIT_ERROR_
    done
    return $_CODE_EXIT_SUCCESS_
}