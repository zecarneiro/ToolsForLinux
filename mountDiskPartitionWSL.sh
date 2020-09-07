#!/bin/bash
declare letterDisk="${1%:}"
declare mountDir="/mnt"

function ToLower(){
    local message="$1"
    echo "$message" | tr '[A-Z]' '[a-z]'
}

function ToUpper(){
    local message="$1"
    echo "$message" | tr '[a-z]' '[A-Z]'
}

function main(){
    local mountLetterDir="$(ToLower "$letterDisk")"
    local windowsLetter="$(ToUpper "$letterDisk")"

    # Validate Letter inserted
    if [ ${#letterDisk} -ne 1 ]; then
        echo "Invalid Letter of disk!!!"
        echo "Example: $(basename "$0") OneAnyLetter"
        echo "$(basename "$0") E"
        exit 1
    fi

    # Umount disk if already mounted
    if [ -d "$mountDir/$mountLetterDir" ]; then
        sudo umount "$mountDir/$mountLetterDir"
    fi

    # Mount
    sudo mount -t drvfs "${windowsLetter}:" "$mountDir/$mountLetterDir"
}
main