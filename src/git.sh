#!/bin/bash

# Global
declare _GIT_GLOBAL_ARG_="--global "
declare isGitExist="$(ls -a | grep -v '.gitignore' | grep -ci '.git')"

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

function setDefaultConfig() {
	local cmdFileMode="git config {0}core.fileMode false"
	local cmdAutoSaveFilesWindowsMode="git config {0}core.autocrlf true"
	
	case "$1" in
		local)
			executeCMD "${cmdFileMode//\{0\}/''}"
			executeCMD "${cmdAutoSaveFilesWindowsMode//\{0\}/''}"
			
		;;
		global)
			executeCMD "${cmdFileMode//\{0\}/$_GIT_GLOBAL_ARG_}"
			executeCMD "${cmdAutoSaveFilesWindowsMode//\{0\}/$_GIT_GLOBAL_ARG_}"
		;;
		*)
			echo "default"
		;;
	esac
	
}

function gitCommands() {
	case "$1" in
		create-repository)
			showMessages "${_EXECUTE_CMD_MSG_//\{0\}/'Create Repository'} for: $file" 3
			showMessages "1 - git init"
			showMessages "2 - git remote add origin <server>"
		;;
		create-copy-repository)
			showMessages "${_EXECUTE_CMD_MSG_//\{0\}/'Create Copy of Repository'} for: $file" 3
			showMessages "Local:	git clone /path/of/repository"
			showMessages "Remote:	git clone usuário@servidor:/path/for/repository"
		;;
		add-changes-commit)
			showMessages "${_EXECUTE_CMD_MSG_//\{0\}/'Add Changes and Commit'} for: $file" 3
			showMessages "1 - \n\t# File: git add <file>\n\t# All: git add *"
			showMessages "2 - git commit -m 'Message'"
		;;
		branch-opeations)
			showMessages "${_EXECUTE_CMD_MSG_//\{0\}/'Branch Operations'} for: $file" 3
			showMessages "Create:	git checkout -b <branch>"
			showMessages "Change:	git checkout <branch>"
			showMessages "Delete:	git branch -d <branch>"
		;;
		*)
			echo "default"
		;;
	esac
	
}

declare _OPERATIONS_GIT_="$1"; shift
case "$_OPERATIONS_GIT_" in
	get-commands) gitCommands "$@" ;;
	set-default-config) setDefaultConfig "$@" ;;
    help) HELP ;;
    *)
        messageerror="$_ALIAS_TOOLSFORLINUX_ ${_SUBCOMMANDS_[3]} help"
        showMessages "${_MESSAGE_RUN_HELP_/\%MSG\%/$messageerror}" 4 "${FUNCNAME[0]}"
        exitError $_CODE_EXIT_ERROR_
    ;;
esac
