#!/bin/bash
# Author: José M. C. Noronha

declare subcommand="$1"
declare toolGeneric="toolGeneric.sh"
declare -a apps
declare -a ppas
declare -i noRecomends="0"
declare -i EMPTY_LINES="1"

MESSAGE_HELP="
    $(basename "$0") <subcommand>... [OPTIONS]...

    SYNOPSIS
        $(basename "$0") [check-app | check-ppa] [OPTIONS]... [NAME]
        $(basename "$0") [install | uninstall] [OPTIONS]... [--app|--ppa]... [APP-NAME|PPA-NAME]

    Subcommand:
    check-app       Check|List App is installed. List if no name inserted
    check-ppa       Check PPA is installed
    install         Install Apps
    uninstall       Uninstall Apps

    --dependencies	Install Dependencies

    -h, --help		Help

    OPTIONS:
    -a, --apt       APT to check
    -s, --snap      SNAP to check
    -f, --flatpak   FLATPAK to check
    -d, --deb       Deb files
"

: '
####################### Generic Area #######################
'
function printInvalidArg() {
    echo "Ivalid Arguments"
    exit 1
}

function setAppsAndPPAs() {
    local -a args=($@)
    local -i selector="0"
    local -a arraySelector=("--no-recomends" "--app" "--ppa")

    for((i=0;i<"${#args[@]}";i++)); do
        if [ "${args[$i]}" = "${arraySelector[0]}" ]; then
            if [ $noRecomends -eq 0 ]; then
                noRecomends=1
            fi
            selector="0"
         else
            if [ "${args[$i]}" = "${arraySelector[1]}" ]; then
                selector="1"
            elif [ "${args[$i]}" = "${arraySelector[2]}" ]; then
                selector="2"
            fi
        fi

        if [ $selector -eq 1 ]&&[ "${args[$i]}" != "${arraySelector[1]}" ]; then
            apps+=( "${args[$i]}" )
        elif [ $selector -eq 2 ]&&[ "${args[$i]}" != "${arraySelector[2]}" ]; then
            ppas+=( "${args[$i]}" )
        fi
    done
}

: '
####################### CHECK AREA #######################
'
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

function installDependencies(){
    installAPT --app torsocks  flatpak xdg-desktop-portal-gtk gnome-software-plugin-flatpak
}

case "$subcommand" in
	check-app|check-ppa)
        shift
		if [ "$subcommand" = "check-app" ]; then
            appInstaled "$@"
        else
            ppaInstaled "$@"
        fi     
		exit 0
	;;
    install|uninstall)
        shift
        case "$1" in
            -a|--apt)
                shift
                if [ "$subcommand" = "install" ]; then
                    installAPT "$@"
                else
                    uninstallAPT "$@"
                fi
                exit 0
            ;;
            -s|--snap)
                shift
                if [ "$subcommand" = "install" ]; then
                    installSNAP "$@"
                else
                    uninstallSNAP "$@"
                fi
                exit 0
            ;;
            -f|--flatpak)
                shift
                if [ "$subcommand" = "install" ]; then
                    installFLATPAK "$@"
                else
                    uninstallFLATPAK "$@"
                fi
                exit 0
            ;;
            * ) printInvalidArg ;;
        esac
        
        installAPT "$@"
    ;;
	-h|--help)
		echo "$MESSAGE_HELP"
		exit 0
	;;
	* ) printInvalidArg ;;
esac