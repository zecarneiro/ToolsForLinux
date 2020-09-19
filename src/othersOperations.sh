#!/bin/bash
# Author: José M. C. Noronha

function reloadGnomeShell() {
    killall -3 gnome-shell
	(( $? > 0 )) && printMessages "Operations Fail" 4 ${FUNCNAME[0]} || printMessages "Done" 1
}

function toBinary() {
    local n bit
	local regex_number='^[0-9]+$'

	if ! [[ $1 =~ $regex_number ]] ; then
		printMessages "Invalid Number" 4 ${FUNCNAME[0]}; exitError $_EXIT_ERROR_
	fi

	printMessages "Convert $1 to binary" 3
	
    for (( n=$1 ; n>0 ; n >>= 1 )); do
		bit="$(( n&1 ))$bit"
		(( $? > 0 )) && {
			printMessages "Operactions Fail" 4 ${FUNCNAME[0]}
			exitError $_EXIT_ERROR_
		}
	done
	printMessages "Result = $bit" 1
}

: '
	CIDR Calculator
		-> CIDR - Classless Inter Domain Routing

	This function convert all numbers to binary of 8 bit and count 1s in this binary
	Example:
	  IP: 255.0.0.0
	  Where 255 = 11111111 = 8 1s
	  And 0 = 00000000 = 0 1s
	  So type of network of 255.0.0.0 is /8
'
function cidrCalculator() {
	local ip="$1"
	local -i total="0"
	local charOne="1"
	local msgError="Invalid IP ADDRESS"
	local regex_number='^[0-9]+$'

	# Convert all part of IP to Array
	IFS='.' read -ra ADDR <<< "$ip"
	(( ${#ADDR[@]} == 4 )) && {
		for ip_part in "${ADDR[@]}"; do
			if ! [[ $ip_part =~ $regex_number ]] ; then
				printMessages "$msgError" 4 ${FUNCNAME[0]}
				exitError $_EXIT_ERROR_
			fi
		done
	} || {
		printMessages "$msgError" 4 ${FUNCNAME[0]}
		exitError $_EXIT_ERROR_
	}

	for ip_part in "${ADDR[@]}"; do
		data="$(toBinary ${ip_part} | grep = | cut -d'=' -f2)"
		data="$(trim "$data")"
		if [ -n "$data" ]; then
			count="$(awk -F"${charOne}" '{print NF-1}' <<< "${data}")"
			if [ $count -ge 0 ]; then
				((total=total+count))
			fi
		fi
	done
	printMessages "Type of network: $ip /$total" 1
}

: '
	Trim word by characters
	word = $1
'
function trim() {
    local word="$1"
    echo "$word" | xargs
}

declare _OPERATIONS_APT_="$1"; shift
case "$_OPERATIONS_APT_" in
	reload-gnome-shell) reloadGnomeShell ;;
	to-binary) toBinary "$@" ;;
	cidr-calculator) cidrCalculator "$@" ;;
	trim) trim "$@" ;;
esac