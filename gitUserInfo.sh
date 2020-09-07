#!/bin/bash

# Global
declare arg="$1"

function insertConfig(){
	printf "\nInsert new Config\n"
	# Read type of info
	read -p "For Local(On this path) ? y/N: " isLocal

	# Read user.name
	read -p "Insert User.name (Nothing for already used): " user
	if [ ! -z "$user" ]; then
		# Insert new user name		
		if [ -z "$isLocal" ]||[ "$isLocal" = "N" ]; then
			git config --global user.name "$user"
		else
			git config user.name "$user"
		fi		
	fi

	# Read user.email
	read -p "Insert User.email (Nothing for already used): " email
	if [ ! -z "$email" ]; then
		# Insert new user email		
		if [ -z "$isLocal" ]||[ "$isLocal" = "N" ]; then
			git config --global user.email "$email"
		else
			git config user.email "$email"
		fi		
	fi

	# Print config
	getConfig

	# Information
	echo "INFORMATION: Please restart any git software..."
}

function disablePermissionCheck(){
	local -i isGitExist="0"
	local defaultPath="$( echo $PWD )"

	echo "Default: $defaultPath"
	read -p "Insert path to disable permission check(ENTER TO DEFAULT): " path

	if [ -z "$path" ]; then
		isGitExist="$(ls -a | grep -v '.gitignore' | grep -ci '.git')"
	else
		if [ -d $path ]; then
			isGitExist="$(ls -a "$path" | grep -v '.gitignore' | grep -ci '.git')"	
		fi
	fi

	if [ $isGitExist -gt 0 ]; then
		git config core.fileMode false
	fi
}

function getConfig(){
	# Read type of info
	printf "\n1- Global\n2- Local\n3- All\n"
	read -p "Insert option: " userOption

	# Global
	if [ "$userOption" = "1" ]||[ "$userOption" = "3" ]; then
		printf "\nGit User Config for global repository\n"
		git config --list --global | grep -i "user.name"
		git config --list --global | grep -i "user.email"
	fi

	# Local
	if [ "$userOption" = "2" ]||[ "$userOption" = "3" ]; then
		printf "\nGit User Config for local repository\n"
		git config --list --local | grep -i "user.name"
		git config --list --local | grep -i "user.email"
	fi
}

function insertMergeDiffTool () {
	echo 'For windows if kdiff3 in path set: C:\\Program Files\\KDiff3\\kdiff3.exe'
	read -p "Name of Tool/App: " nameTool
	if [ -n "$nameTool" ]; then
		git config --global diff.tool "$nameTool"
		git config --global merge.tool "$nameTool"

		read -p "Path of App(Ex: /path/of/app/app.exe) [ENTER TO CONTINUE]: " pathTool
		if [ -n "$pathTool" ]; then
			git config --global difftool."$nameTool".path "$pathTool"
			git config --global mergetool."$nameTool".path "$pathTool"
		fi

		read -p "Command to execute tool [ENTER TO CONTINUE IF SET PATH]: " commandTool
		if [ -n "$commandTool" ]; then
			git config --global difftool."$nameTool".cmd "$commandTool"
			git config --global mergetool."$nameTool".cmd "$commandTool"
		fi
	else
		echo "Invalid insert"
	fi
}


function main(){
	case "$arg" in
		"config" )
			getConfig
			;;
		"insert" )
			insertConfig
			;;
		"dPCheck" )
			disablePermissionCheck
			;;
		"iMergeDiffTool")
			insertMergeDiffTool
			;;
		* )
			echo "Config user and config info for git"
			printf "\n$0 config|insert|dPCheck\n"
			printf "\t config: Display Git user info\n"
			printf "\t insert: Insert Git user info\n"
			printf "\t dPCheck: Disable Git for check change of permissions\n"
			printf "\t iMergeDiffTool: Config merge and diff tool\n"
			;;
	esac
}
main
