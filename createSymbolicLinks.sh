#!/bin/bash
# Author: José M. C. Noronha

# Global
declare arg="$1"

function main () {
    local pathFile=''
    local nameFile=''

    # Ask for full path
    read -p "Insert full path of file: " pathFile

    if [ -n "$pathFile" ]; then        
        if [ -f "$pathFile" ]||[ -d "$pathFile" ]; then
            nameFile="$(basename "$pathFile")" # Get name of file
            if [ -n "$nameFile" ]; then            
                if [ -z "$arg" ]||[ "$arg" != "-s" ]; then
                    ln -sf "$pathFile" "$nameFile"
                else
                    sudo ln -sf "$pathFile" "$nameFile"
                fi
            fi
        else
            echo "File or Dir not exist!!"
        fi 
    fi
}
main