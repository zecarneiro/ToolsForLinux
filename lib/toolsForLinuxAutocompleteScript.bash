#/usr/bin/env bash

_System_completions() {
    local sugestions=""
    local -a systemArgs=("apt-clean" "apt-update" "apt-upgrade" "apt-installed" "apt-repository" "apt-app")
    systemArgs+=("deb-files" "rpm-files" "gnome-shell-extensions")
    systemArgs+=("snap-update" "snap-installed" "snap-app")
    systemArgs+=("flatpak-update" "flatpak-installed" "flatpak-repository" "flatpak-app")
    systemArgs+=("fix-locale-package" "reload-gnome-shell" "system-upgrade" "is-service-active" "pid-kill")
    systemArgs+=("check-graphic-vendor" "help")

    case $COMP_CWORD in
        2)
            sugestions="${systemArgs[@]}"
            COMPREPLY=($(compgen -W "${sugestions}" "${COMP_WORDS[2]}"))
        ;;
        3)
            sugestions=""
            case "${COMP_WORDS[2]}" in
                apt-repository|apt-app|flatpak-repository|flatpak-app) sugestions="i u" ;;
                snap-app) sugestions="i i-classic u" ;;
                system-upgrade) sugestions="apt snap flatpak all" ;;
            esac
            COMPREPLY=( $(compgen -W "${sugestions}" -- "${COMP_WORDS[COMP_CWORD]}") )
        ;;
    esac
}

_Others_completions() {
    local sugestions=""
    local -a othersArgs=("clear-screen" "to-binary" "cidr-calculator" "trim" "cut-string-by-separator")
    othersArgs+=("exec-cmd-get-output" "create-table" "help")

    case $COMP_CWORD in
        2)
            sugestions="${othersArgs[@]}"
            COMPREPLY=($(compgen -W "${sugestions}" "${COMP_WORDS[2]}"))
        ;;
        3)
            sugestions=""
            case "${COMP_WORDS[2]}" in
                cut-string-by-separator) sugestions="l r" ;;
            esac
            COMPREPLY=( $(compgen -W "${sugestions}" -- "${COMP_WORDS[COMP_CWORD]}") )
        ;;
    esac
}

_Files_completions() {
    local sugestions=""
    local -a filesArgs=("move-to-main-folder" "empty" "create-shortcuts" "help")

    case $COMP_CWORD in
        2)
            sugestions="${filesArgs[@]}"
            COMPREPLY=($(compgen -W "${sugestions}" "${COMP_WORDS[2]}"))
        ;;
        3)
            sugestions=""
            case "${COMP_WORDS[2]}" in
                empty) sugestions="f d" ;;
            esac
            COMPREPLY=( $(compgen -W "${sugestions}" -- "${COMP_WORDS[COMP_CWORD]}") )
        ;;
        4)
            sugestions=""
            case "${COMP_WORDS[3]}" in
                f|d) sugestions="list delete" ;;
            esac
            COMPREPLY=( $(compgen -W "${sugestions}" -- "${COMP_WORDS[COMP_CWORD]}") )
        ;;
    esac
}

_ToolsForLinux_completions() {
    local sugestions=""
    local -a toolsForLinuxArgs=("system" "others" "files" "install-dependencies")
    toolsForLinuxArgs+=("help")
    (( $COMP_CWORD > 2 )) && newCompCWord=2 || newCompCWord=$COMP_CWORD

    case $newCompCWord in
        1)
            sugestions="${toolsForLinuxArgs[@]}"
            COMPREPLY=($(compgen -W "${sugestions}" "${COMP_WORDS[1]}"))
        ;;
        2)
            if [ "${COMP_WORDS[1]}" = "${toolsForLinuxArgs[0]}" ]; then
                _System_completions
            elif [ "${COMP_WORDS[1]}" = "${toolsForLinuxArgs[1]}" ]; then
                _Others_completions
            elif [ "${COMP_WORDS[1]}" = "${toolsForLinuxArgs[2]}" ]; then
                _Files_completions
            elif [ "${COMP_WORDS[1]}" = "${toolsForLinuxArgs[3]}" ]; then
                (( $COMP_CWORD < 3 )) && {
                    sugestions="all apt deb rpm gnome-shell-ext snap flatpak locale-package dconf wget"
                    COMPREPLY=( $(compgen -W "${sugestions}" -- "${COMP_WORDS[COMP_CWORD]}") )
                }
            fi
        ;;
    esac
    return 0
}
complete -F _ToolsForLinux_completions ToolsForLinux