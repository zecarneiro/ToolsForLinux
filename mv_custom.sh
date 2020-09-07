#!/bin/bash
SOURCE_DATA=$2
TARGET_DIR=$3

if [ ! `command -v rsync` ]; then
    sudo apt install rsync -y
fi

function move () {
    SOURCE_DIR="$(echo "${1%/}")"
    rsync -avr --remove-source-files "$1" "$TARGET_DIR"

    if [ "$2" = "1" ]&&[ -d "$1" ]; then
        # Delete
        printf "\n\n### Delete if empty: $1###\n\n"
        find "$1" -type d -empty -delete -print
    fi
}    

function execute() {
    local isDelete="$1"

    if [ "$SOURCE_DATA" = "." ]; then
        while IFS= read -r line
        do
            move "$line" "$isDelete"
        done <<< $(ls)
    else
        move "$SOURCE_DATA" "$isDelete"
    fi
}

function help () {
    echo "
        $(basename "$0") [OPTIONS] [SOURCE] [DESTINATION]

        OPTIONS:
        -ds, --delete-source            Delete Source directory if empty
        -nds, --no-delete-source        No Delete Source directory if empty

        -h, --help                      Help
    "
}

case "$1" in
    -ds|--delete-source)
        execute "1"
    ;;
    -nds|--no-delete-source)
        execute "0"
    ;;
    -h|--help)
        help
    ;;
    *)
        echo "Invalid arguments!!"
        echo "For more informations: $(basename "$0") -h"
    ;;
esac


