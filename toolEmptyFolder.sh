#!/bin/bash
# Author: José Manuel C. Noronha

# Global variable
declare -i operation=$1
declare path=$2

# Funtion return command by select option receive on first arg
# 1 - Print all empty directory
# 2 - Print all empty file
# 3 - Move all empty directory to trash using gio trash command
# 4 - Move all empty file to trash using gio trash command
# NOTE: -printf receive specific character and %p = name of result each line
function getCommand(){
	local -i select=$1
	local command

	case $select in
		1)
			command="find . -empty -type d -printf \n%p\n"
			;;
		2)
			command="find . -empty -type f -printf \n%p\n"
			;;
		3)
			command="find . -empty -type d -printf \n%p\n -exec gio trash {} +"
			;;
		4)
			command="find . -empty -type f -printf \n%p\n -exec gio trash {} +"
			;;
		5)
			command="find . -empty -type d -printf \n%p\n -exec rm -R {} +"
			;;
		6)
			command="find . -empty -type f -printf \n%p\n -exec rm -R {} +"
			;;
	esac

	# Return command
	echo "$command"
}

# Return number of file/directory empty
function numOfEmpty(){
	local -i directoryOrFile=$1 # 0 = Dir / 1 = File
	local command

	if [ $directoryOrFile -eq 0 ]; then
		command="$(getCommand 1)"
	else
		command="$(getCommand 2)"
	fi

	command="$command | grep -c ."
	echo "$command"
}

# Delete all empty directory or files
# $1 = select 0 = directories or 1 = files
function deleteDirectoryFiles(){
	local -i directoryOrFile=$1 # 0 = Dir / 1 = File
	local commandToDelete
	local numOfFileOrDir="$(numOfEmpty $directoryOrFile)"

	if [ $directoryOrFile -eq 0 ]; then
		commandToDelete="$(getCommand 3)"
	else
		commandToDelete="$(getCommand 4)"
	fi
	
	# Execute
	$commandToDelete

	if [ "$(numOfEmpty $directoryOrFile)" = "$numOfFileOrDir" ]; then
		if [ $directoryOrFile -eq 0 ]; then
			commandToDelete="$(getCommand 5)"
		else
			commandToDelete="$(getCommand 6)"
		fi

		# Execute
		$commandToDelete
	fi
}

# List all empty directory or files
# $1 = select 0 = directories or 1 = files
function listDirectoryFiles(){
	local -i directoryOrFile=$1 # 0 = Dir / 1 = File
	local commandToList

	if [ $directoryOrFile -eq 0 ]; then
		commandToList="$(getCommand 1)"
	else
		commandToList="$(getCommand 2)"
	fi

	# Execute
	$commandToList
}

# Set operation to do and print help
function setOperation(){
	echo
	case $operation in
		1)
			echo "OPERATION - LIST EMPTY DIRECTORIES"
			listDirectoryFiles 0
			;;
		2)
			echo "OPERATION - LIST EMPTY FILES"
			listDirectoryFiles 1
			;;
		3)
			echo "OPERATION - DELETE EMPTY DIRECTORIES"
			deleteDirectoryFiles 0
			;;
		4)
			echo "OPERATION - DELETE EMPTY FILES"
			deleteDirectoryFiles 1
			;;
		*)
			printf "List or Delete(Move to trash) empty Directories or empty Files\n"
			printf "For more information visit:\n\t1 - https://www.computerhope.com/unix/ufind.htm\n\n"
			printf "$0 OPTIONS PATH | $0 OPTIONS\n\n"
			printf "OPTIONS:\n\t1 = List Directories\n\t2 = List Files\n\t3 = Delete Directories\n\t4 = Delete Files\n"
	esac

	if [ $operation -ge 0 ]&&[ $operation -le 4 ]; then
		echo
		echo "### Operation Complete ###"
	fi
}

# Change to directory of work and call set operation
function changeExecPath(){	
	if [ -z "$path" ]; then
		setOperation
	else
		if [ -d "$path" ]; then
			cd "$path"
			setOperation
		else
			echo "$path : NOT EXIST"
		fi
	fi
}
changeExecPath