#!/bin/bash
# José M. C. Noronha

# Global variable
declare hostFile="/etc/hosts"
declare args="$1"

function insert(){
    read -p "Insert Address: " address
    read -p "Insert Alias: " aliasName

    if [ -z $address ]||[ -z $aliasName ]; then
        echo "Invalid Address or Alias"
    else
        echo "$address $aliasName" | sudo tee -a "$hostFile" > /dev/null
        sudo service network-manager restart
    fi
}

function remove(){
    read -p "Insert Address: " address
    read -p "Insert Alias: " aliasName

    if [ -z $address ]||[ -z $aliasName ]; then
         echo "Invalid Address or Alias"
    else
        sudo sed -i "/$address $aliasName/d" "$hostFile"
        sudo service network-manager restart
    fi
}

function help () {
    echo "
        $(basename "$0") [OPTIONS]

        OPTIONS:
        -i, --insert    Insert HTTP address alias
        -r, --remove    Remove HTTP address alias
        
        -h, --help      Help
    "
}

function main(){
    case "$args" in
        -i|--insert)
            insert
            exit 0
        ;;
        -r|--remove)
            remove
            exit 0
        ;;
        -h|--help)
            help
            exit 0
        ;;
        *)
            echo "Ivalid Options"
		    exit 1
        ;;
    esac
}
main
