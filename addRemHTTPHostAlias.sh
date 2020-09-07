#!/bin/bash
# José M. C. Noronha

# Global variable
declare hostFile="/etc/hosts"
declare args="$1"

function insert(){
    read -p "Insert Address: " address
    read -p "Insert Alias: " aliasName

    if [ -z $address ]&&[ -z $aliasName ]; then
        echo "Wrong insert!!!!"
    else
        echo "$address $aliasName" | sudo tee -a "$hostFile" > /dev/null
        sudo service network-manager restart
    fi
}

function remove(){
    read -p "Insert Address: " address
    read -p "Insert Alias: " aliasName

    if [ -z $address ]&&[ -z $aliasName ]; then
        echo "Wrong insert!!!!"
    else
        sudo sed -i "/$address $aliasName/d" "$hostFile"
        sudo service network-manager restart
    fi
}

function main(){
    case "$args" in
        "insert")
            insert
            ;;
        "remove")
            remove
            ;;
        *)
            echo "$0 insert|remove"
            echo "Insert Remove HTTP address alias"
    esac
}
main
