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
		showMessages "Invalid Number" 4 ${FUNCNAME[0]}; exitError $_CODE_EXIT_ERROR_
	fi

	showMessages "Convert $1 to binary" 3
	
    for (( n=$1 ; n>0 ; n >>= 1 )); do
		bit="$(( n&1 ))$bit"
		(( $? > 0 )) && {
			showMessages "Operactions Fail" 4 ${FUNCNAME[0]}
			exitError $_CODE_EXIT_ERROR_
		}
	done
	showMessages "Result = $bit" 1
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
				showMessages "$msgError" 4 ${FUNCNAME[0]}
				exitError $_CODE_EXIT_ERROR_
			fi
		done
	} || {
		showMessages "$msgError" 4 ${FUNCNAME[0]}
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
	showMessages "Type of network: $ip /$total" 1
}

: '
	Trim word by characters

	ARGS:
	word = $1
'
function trim() {
    local word="$1"
	echo "$word" | awk '{$1=$1};1'
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
		showMessages "ENV VAR: TOOLFORLINUX_TABLE_LENGTH_COLUMN not exist" 4
		return $_CODE_EXIT_ERROR_
	fi

	if [ -z "${TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR}" ]; then
		showMessages "ENV VAR: TOOLFORLINUX_TABLE_MAX_COLUMN_CHAR not exist" 4
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
		showMessages "Invalid DCONF PATH" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi

	# Validate dconf path
	if [[ "$reset" =~ "reset" ]]&&[ -z "$backupFile" ]; then
		showMessages "Invalid Backup file" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi

	case "$1" in
		backup) dconf dump "$dconfPath" > "$backupFile"; errorcode=$? ;;
		restore) dconf load "$dconfPath" < "$backupFile"; errorcode=$? ;;
		reset) dconf reset -f "$pathDconf"; errorcode=$? ;;
		*) showMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
	esac
	
	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        showMessages "Operations Fail" 4 "${FUNCNAME[0]}"
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
		showMessages "Invalid address" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi

	# Validate alias
	if [ -z "$alias" ]; then
		showMessages "Invalid alias" 4 ${FUNCNAME[0]}
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
		*) showMessages "Invalid arguments" 4 "${FUNCNAME[0]}"; return $_CODE_EXIT_ERROR_ ;;
	esac
	
	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        showMessages "Operations Fail" 4 "${FUNCNAME[0]}"
        return $errorcode
    }

	(( $restart_network == 1 )) && {
        sudo service network-manager restart
		errorcode=$?
		(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
			showMessages "Operations Fail" 4 "${FUNCNAME[0]}"
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
		showMessages "Invalid string inserted" 4 ${FUNCNAME[0]}
		return $_CODE_EXIT_ERROR_
	fi
	
	case "$1" in
		upper) echo "$stringData" | tr '[a-z]' '[A-Z]'; errorcode=$? ;;
		lower) echo "$stringData" | tr '[A-Z]' '[a-z]'; errorcode=$? ;;
		*) showMessages "Invalid arguments" 4 ${FUNCNAME[0]}; return $_CODE_EXIT_ERROR_ ;;
	esac
	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
        showMessages "Operations Fail" 4 "${FUNCNAME[0]}"
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
	local namePrint="Disk On WSL"
	local errorcode

	showMessages "Init $namePrint" 3

    # Validate Letter inserted
    if [ ${#letterDisk} -ne 1 ]; then
		msgerror="Invalid Letter of disk!!!"
		msgerror="${messageerror}\nExample: $(basename "$0") OneAnyLetter\n$(basename "$0") E"
        showMessages "$msgerror" 4 "${FUNCNAME[0]}"
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
        showMessages "Operations Fail" 4 "${FUNCNAME[0]}"
        return $errorcode
    }
	showMessages "$namePrint Done" 1
	return $_CODE_EXIT_SUCCESS_
}

: '
	Print MD Files

	ARGS:
	file = $1
'
function printFilesMD() {
	local file="$1"
	local namePrint="Read MD File"
	local errorcode

	showMessages "Init $namePrint" 3

	validateDependencies "md-file"
    exitError $?

	[[ -f "$file" ]] && {
		pandoc -f markdown "$file" | lynx -stdin
		errorcode=$?
	} || {
		showMessages "$msgerror" 4 "${FUNCNAME[0]}"
		return $_CODE_EXIT_ERROR_
	}

	(( $errorcode > $_CODE_EXIT_SUCCESS_ )) && {
		showMessages "Operation Fail" 4 "${FUNCNAME[0]}"
		return $errorcode
	}
	showMessages "$namePrint Done" 1
	return $_CODE_EXIT_SUCCESS_
}

: '
	Print Messages by type with color.
	Get from https://gist.github.com/jonsuh/3c89c004888dfc7352be

	ARG1: Messages to print
    ARG2: 
		GREEN
		YELLOW
		BLUE
		RED
		ORANGE
		PURPLE
		CYAN
		LIGHTGRAY
		DARKGRAY
		LIGHTRED
		LIGHTGREEN
		LIGHTBLUE
		LIGHTPURPLE
		LIGHTCYAN
		WHITE
	ARG3: Function name. To get function name: ${FUNCNAME[0]}
'
function printMessage() {
    local msg="$1"
    local typeMSG="$2"
	local noLine="$4"
    local functionName=""
    [[ -n "$3" ]] && functionName="$3: "
	local -A COLORS=(
		['NOCOLOR']='\033[0m'
		['RED']='\033[0;31m'
		['GREEN']='\033[0;32m'
		['ORANGE']='\033[0;33m'
		['BLUE']='\033[0;34m'
		['PURPLE']='\033[0;35m'
		['CYAN']='\033[0;36m'
		['LIGHTGRAY']='\033[0;37m'
		['DARKGRAY']='\033[1;30m'
		['LIGHTRED']='\033[1;31m'
		['LIGHTGREEN']='\033[1;32m'
		['YELLOW']='\033[1;33m'
		['LIGHTBLUE']='\033[1;34m'
		['LIGHTPURPLE']='\033[1;35m'
		['LIGHTCYAN']='\033[1;36m'
		['WHITE']='\033[1;37m'
	)

    case "$typeMSG" in
		GREEN) msg="${COLORS[GREEN]}${functionName}$msg" ;;
        YELLOW) msg="${COLORS[YELLOW]}${functionName}$msg" ;;
        BLUE) msg="${COLORS[BLUE]}${functionName}$msg" ;;
        RED) msg="${COLORS[RED]}${functionName}$msg" ;;
		ORANGE) msg="${COLORS[ORANGE]}${functionName}$msg" ;;
		PURPLE) msg="${COLORS[PURPLE]}${functionName}$msg" ;;
		CYAN) msg="${COLORS[CYAN]}${functionName}$msg" ;;
		LIGHTGRAY) msg="${COLORS[LIGHTGRAY]}${functionName}$msg" ;;
		DARKGRAY) msg="${COLORS[DARKGRAY]}${functionName}$msg" ;;
		LIGHTRED) msg="${COLORS[LIGHTRED]}${functionName}$msg" ;;
		LIGHTGREEN) msg="${COLORS[LIGHTGREEN]}${functionName}$msg" ;;
		LIGHTBLUE) msg="${COLORS[LIGHTBLUE]}${functionName}$msg" ;;
		LIGHTPURPLE) msg="${COLORS[LIGHTPURPLE]}${functionName}$msg" ;;
		LIGHTCYAN) msg="${COLORS[LIGHTCYAN]}${functionName}$msg" ;;
		WHITE) msg="${COLORS[WHITE]}${functionName}$msg" ;;
        *) msg="${functionName}$msg" ;;
    esac

	if [ "$noLine" = "1" ]; then
		printf "$msg${COLORS[NOCOLOR]}"
	else
		echo -e "$msg${COLORS[NOCOLOR]}"
	fi
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
	data+=("\"http-alias [set|unset ADDRESS ALIAS]\"" "\"Set/Unset Alias for HTTP host\"")
	data+=("\"upper-lower-string [upper|lower STRING]\"" "\"Upper/Lower an String\"")
	data+=("\"disk-on-wsl [mount|umount LETTER_OF_DISK]\"" "\"Mount/Umount disk on WSL (IMPORTANT: Only work on WSL)\"")
	data+=("\"print-md-file [FILE]\"" "\"Print MD Files\"")
	data+=("\"print-message [MSG COLOR FUNC_NAME]\"" "\"Print Message with color or not\"")
    
	data+=("%EMPTY_LINE%")
    data+=("help" "Help")

    . "$_SRC_/${_SUBCOMMANDS_[1]}.sh" create-table ${data[@]}

	echo -e "\nINFORMATIONS:"
	echo -e " - COLORS FOR print-message:"
	echo -e "\tGREEN\n\tYELLOW\n\tBLUE\n\tRED\n\tORANGE\n\tPURPLE\n\tCYAN\n\tLIGHTGRAY\n\tDARKGRAY\n\tLIGHTRED\n\tLIGHTGREEN\n\tLIGHTBLUE\n\tLIGHTPURPLE\n\tLIGHTCYAN\n\tWHITE"
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
	print-md-file) printFilesMD "$@" ;;
	print-message) printMessage "$@" ;;
	help) HELP ;;
	*)
        messageerror="$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[1]} help"
        showMessages "${_MESSAGE_RUN_HELP_/\%MSG\%/$messageerror}" 4 "${FUNCNAME[0]}"
        exitError $_CODE_EXIT_ERROR_
    ;;
esac