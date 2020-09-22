#!/bin/bash
# Author: José M. C. Noronha

# Clear Terminal Window
function clearScreen() {
	printf "\033c"
}

: '
	Convert number to binary

	ARGS:
	number = $1
'
function toBinary() {
    local n bit
	local regex_number='^[0-9]+$'

	if ! [[ $1 =~ $regex_number ]] ; then
		printMessages "Invalid Number" 4 ${FUNCNAME[0]}; exitError $_CODE_EXIT_ERROR_
	fi

	printMessages "Convert $1 to binary" 3
	
    for (( n=$1 ; n>0 ; n >>= 1 )); do
		bit="$(( n&1 ))$bit"
		(( $? > 0 )) && {
			printMessages "Operactions Fail" 4 ${FUNCNAME[0]}
			exitError $_CODE_EXIT_ERROR_
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

	ARGS:
	ip = $1
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
				exitError $_CODE_EXIT_ERROR_
			fi
		done
	} || {
		printMessages "$msgError" 4 ${FUNCNAME[0]}
		exitError $_CODE_EXIT_ERROR_
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

	ARGS:
	word = $1
'
function trim() {
    local word="$1"
    echo "$word" | xargs
}

: '
	Cut string by separator

	ARGS:
	diretion =		$1	(l/r)
	separator =		$2
	string =		$1
'
function cutStringBySeparator() {
    local direction="$1"; shift
    local separator="$1"; shift
	local string="$@"
    local commandDir

    if [ "$direction" = "l" ]; then
        echo "$string" | awk -F"$separator" '{$0=$1}1'
    elif [ "$direction" = "r" ]; then
        echo "$string" | awk -F"$separator" '{$0=$2}1'
    else
        echo "$string"
    fi
}

: '
	Execute command and return output

	ARGS:
	command = $1
'
function execCommandGetOutput() {
    local command="$1"
	local errorcode
    local response
	
	response="$(executeCMD "$command" 1)"
	errorcode=$?
    echo "$response"
	return $errorcode
}

: '
	Print data with same space, or table format
	To Set:
	
	1 - First export two variables
		* TOOLFORLINUX_TABLE_LENGTH_COLUMN and TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR
	2 - Call ther function with all args
	Exemple
		export TOOLFORLINUX_TABLE_LENGTH_COLUMN=2
		export TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR=20
		createTable First Second "\"Third and Four\"" Five "%EMPTY_LINE%" Six Other

		Will be print:
			First               Second
			Third and Four      Five

			Six                 Other

'
function createTable() {
	local -a data=()
	local initNewString=0
	local newString=""
	local keyEmptyLine="%EMPTY_LINE%"
	local keyEmptyColumn="%EMPTY_COLUMN%"

	if [ -z "${TOOLFORLINUX_TABLE_LENGTH_COLUMN}" ]; then
		printMessages "ENV VAR: TOOLFORLINUX_TABLE_LENGTH_COLUMN not exist" 4
		return $_CODE_EXIT_ERROR_
	fi

	if [ -z "${TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR}" ]; then
		printMessages "ENV VAR: TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR not exist" 4
		return $_CODE_EXIT_ERROR_
	fi

	# Get all string from args. If some strin init and end with '', so this loop get all word between them
	for i in "$@"; do
		if [[ $i == \"* ]]; then
			newString="${newString} $i"
			initNewString=1
		elif [[ $i == *\" ]]; then
			newString="${newString} $i"
			initNewString=0
		else
			newString="${newString} $i"
		fi

		(( $initNewString == 0 )) && {
			data+=("$(trim "$newString")")
			newString=""
		}
	done

	local -i count=0
	for column in "${data[@]}"; do
		if [ "$column" = "$keyEmptyLine" ]; then
			count=$TOOLFORLINUX_TABLE_LENGTH_COLUMN
		elif [ "$column" = "$keyEmptyColumn" ]; then
			printf "%-${TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR}s" ""
		else
			printf "%-${TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR}s" "${column}"
		fi
		(( count=$count+1))

		if (( $count >= ${TOOLFORLINUX_TABLE_LENGTH_COLUMN} )); then
			printf "\n"
			count=0
		fi
	done
	return $_CODE_EXIT_SUCCESS_
}

: '
	Backup/Load and Reset dconf data

	ARGS:
	diretion =		$1	(l/r)
	separator =		$2
	string =		$1
'
function dconf() {
	local dconfPath="$2"
	local backupFile="$3"
	local errorcode

	validateDependencies dconf
    exitError $?

	# Validate dconf path
	if [ -z "$dconfPath" ]; then
		printMessages "Invalid DCONF PATH" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi

	# Validate dconf path
	if [[ "$reset" =~ "reset" ]]&&[ -z "$backupFile" ]; then
		printMessages "Invalid Backup file" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi

	case "$1" in
		backup) dconf dump "$dconfPath" > "$backupFile"; errorcode=$? ;;
		restore) dconf load "$dconfPath" < "$backupFile"; errorcode=$? ;;
		reset) dconf reset -f "$pathDconf"; errorcode=$? ;;
		*) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
	esac
	
	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
        return $errorcode
    }
	return $_CODE_EXIT_SUCCESS_
}

: '
	Set/Unset Alias for HTTP host

	ARGS:
	type =		$1	(set|unset)
	address =	$2
	alias =		$1
'
function httpAlias() {
	local hostFile="/etc/hosts"
	local address="$2"
	local alias="$3"
	local -i restart_network=0

	# Validate address
	if [ -z "$address" ]; then
		printMessages "Invalid address" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi

	# Validate alias
	if [ -z "$alias" ]; then
		printMessages "Invalid alias" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi

	case "$1" in
		set)
			echo "$address $alias" | sudo tee -a "$hostFile" > /dev/null
			errorcode=$?
			restart_network=1
		;;
		unset)
			sudo sed -i "/$address $alias/d" "$hostFile"
			errorcode=$?
			restart_network=1
		;;
		*) printMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
	esac
	
	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
        return $errorcode
    }

	(( $restart_network == 1 )) && {
        sudo service network-manager restart
		errorcode=$?
		(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
			printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
			return $errorcode
		}
    }
	return $_CODE_EXIT_SUCCESS_
}

: '
	Upper/Lower an String

	ARGS:
	type =		$1	(upper|lower)
	string =	$2
'
function upperLowerString() {
	local stringData="$2"
	local errorcode

	if [ -z "$stringData" ]; then
		printMessages "Invalid string inserted" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi
	
	case "$1" in
		upper) echo "$stringData" | tr '[a-z]' '[A-Z]'; errorcode=$? ;;
		lower) echo "$stringData" | tr '[A-Z]' '[a-z]'; errorcode=$? ;;
		*) printMessages "Invalid arguments" 4 ${FUNCNAME[0]}; return $_CODE_EXIT_ERROR_ ;;
	esac
	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
        return $errorcode
    }
	return $_CODE_EXIT_SUCCESS_
}

: '
	Mount/Umount disk on WSL

	ARGS:
	type =			$1	(mount|umount)
	letterDisk =	$2
'
function diskOnWSL() {
	local letterDisk="${2%:}"
	local mountLetterDir="$(upperLowerString lower "$letterDisk")"
    local windowsLetter="$(upperLowerString upper "$letterDisk")"
	local mountDir="/mnt"
	local errorcode

    # Validate Letter inserted
    if [ ${#letterDisk} -ne 1 ]; then
		msgerror="Invalid Letter of disk!!!"
		msgerror="${messageerror}\nExample: $(basename "$0") OneAnyLetter\n$(basename "$0") E"
        printMessages "$msgerror" 4 "${FUNCNAME[0]}"
        return $_CODE_EXIT_ERROR_
    fi

	# Umount disk if already mounted
	if [ "$1" = "mount" ]||[ "$1" = "umount" ]; then
		sudo umount "$mountDir/$mountLetterDir"
		errorcode=$?
	fi

	# Mount disk
	if [ "$1" = "mount" ]; then
		sudo mount -t drvfs "${windowsLetter}:" "$mountDir/$mountLetterDir"
		errorcode=$?
	fi

	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        printMessages "Operations Fail" 4 "${FUNCNAME[0]}"
        return $errorcode
    }
	printMessages "Done" 1
	return $_CODE_EXIT_SUCCESS_
}

: '
####################### MAIN AREA #######################
'
function HELP() {
    local data=()
    export TOOLFORLINUX_TABLE_LENGTH_COLUMN="2"
    export TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR="55"
	local -a data=()

    echo -e "$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[1]} <subcommand>\n\nSubcommand:"
	data+=("clear-screen" "\"Clear screen\"")
    data+=("\"to-binary [NUMBER]\"" "\"Convert number to binary\"")
    data+=("\"cidr-calculator [IPv4]\"" "\"CIDR Calculator\"")
	data+=("\"trim [STRING]\"" "\"TRIM string\"")
	data+=("\"cut-string-by-separator [l/r SEPARATOR STRING]\"" "\"Cut string by separator\"")
	data+=("\"exec-cmd-get-output [COMMAND]\"" "\"Execute command and print result\"")
	data+=("\"create-table [DATA_1 DATA_2...]\"" "\"Print data in table format\"")
	data+=("\"dconf [backup|restore|reset DCONF_PATH BACKUP_FILE]\"" "\"Backup/Load and Reset dconf data. If reset backup file is not necessary\"")
	data+=("\"http-alias [ADDRESS ALIAS]\"" "\"Set/Unset Alias for HTTP host\"")
	data+=("\"upper-lower-string [upper|lower STRING]\"" "\"Upper/Lower an String\"")
	data+=("\"disk-on-wsl [mount|umount LETTER_OF_DISK]\"" "\"Mount/Umount disk on WSL (IMPORTANT: Only work on WSL)\"")
    
	data+=("%EMPTY_LINE%")
    data+=("help" "Help")

    . "$_SRC_/${_SUBCOMMANDS_[1]}.sh" create-table ${data[@]}
}

declare _OPERATIONS_APT_="$1"; shift
case "$_OPERATIONS_APT_" in
	clear-screen) clearScreen ;;
	to-binary) toBinary "$@" ;;
	cidr-calculator) cidrCalculator "$@" ;;
	trim) trim "$@" ;;
	cut-string-by-separator) cutStringBySeparator "$@" ;;
	exec-cmd-get-output) execCommandGetOutput "$@" ;;
	create-table) createTable "$@" ;;
	dconf) dconf "$@" ;;
	http-alias) httpAlias "$@" ;;
	upper-lower-string) upperLowerString "$@" ;;
	disk-on-wsl) diskOnWSL "$@" ;;
	help) HELP ;;
	*)
        messageerror="$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[1]} help"
        printMessages "${_MESSAGE_RUN_HELP_/\%MSG\%/$messageerror}" 4 "${FUNCNAME[0]}"
        exitError $_CODE_EXIT_ERROR_
    ;;
esac