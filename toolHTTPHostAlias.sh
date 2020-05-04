#!/bin/bash
# José M. C. Noronha

# Global variable
declare hostFile="/etc/hosts"
declare addressData="$2"
declare aliasData="$3"

function insert(){
    if [ -z $addressData ]||[ -z $aliasData ]; then
        echo "Invalid Address or Alias"
        exit 1
    fi
    echo "$addressData $aliasData" | sudo tee -a "$hostFile" > /dev/null
    sudo service network-manager restart
}

function remove(){
    if [ -z $addressData ]||[ -z $aliasData ]; then
         echo "Invalid Address or Alias"
         exit 1
    fi
    sudo sed -i "/$addressData $aliasData/d" "$hostFile"
    sudo service network-manager restart
}

function helpMessage () {
    echo "
        $(basename "$0") [OPTIONS]... [ADDRESS]... [ALIAS]

        OPTIONS:
        -i, --insert    Insert HTTP address alias
        -r, --remove    Remove HTTP address alias
        
        -h, --help      Help
    "
}

case "$1" in
    -i|--insert)
        insert
        exit 0
    ;;
    -r|--remove)
        remove
        exit 0
    ;;
    -h|--help)
        helpMessage
        exit 0
    ;;
    *)
        echo "Ivalid Arguments"
        exit 1
    ;;
esac
