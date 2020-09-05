#!/bin/bash
# Author: José M. C. Noronha

# Global variable
declare operation="$1";
 # $1 processada, segue o proximo da fila em $1
declare home="$(echo $HOME)"
declare -a operatingSystemPermited=("Linux Mint")

# Clear Terminal Window
function clearScreen(){
	printf "\033c"
}

: '
Trim word by characters
word = $1
characters = $2
'
function trim() {
    local word="$1"
    local characters="$2"

    if [ -z "$characters" ]; then
        characters='." "$#%&!*'
    fi
    
    echo "$word" | sed "s/[$characters]//g"
}

# Trim

# Print empty lines. NumOfLines = $1
function printEmptyLines(){
	local numOfLines="$1"

	if [ ! -z $numOfLines ]; then
		for (( i = 0; i < $numOfLines; i++ )); do
			echo
		done
	fi
}

# Check your Graphic vendor
function checkGraphicVendor(){
    local nameVendor="$1"
    local -i exist=$( lspci -v | grep -ci "$nameVendor" )

    if [ $exist -ge 1 ]; then
        echo "1"
    else
        echo "0"
    fi
}

# Check if directory exist
function existDir(){
	local name="$1"
	local -i response

	# Check if is dir
	if [ -d "$name" ]; then
        response=1
    else
        response=0
    fi

	# Return response
	echo $response
}

# Check if file exist
function existFile(){
	local name="$1"
	local -i response

	# Check if is dir
    if [ -f "$name" ]; then
        response=1
    else
        response=0
    fi

	# Return response
	echo $response
}



# Delete File
function removeFile(){
    local name="$1"
    local -i runSudo=$2
    if [ $(existFile "$name") -eq 1 ]; then
        if [ $runSudo -eq 1 ]; then
            sudo rm -r "$name"
        else
            rm -r "$name"
        fi
    fi
}

# Delete Dir
function removeDir(){
    local name="$1"
    local -i runSudo=$2
    if [ $(existDir "$name") -eq 1 ]; then
        if [ $runSudo -eq 1 ]; then
            sudo rm -r "$name"
        else
            rm -r "$name"
        fi
    fi
}

# Execute command and return output
function execCommandGetOutput(){
    local command="$1"
    local response

    response="$(eval "$command")"
    echo "$response"
}

# Execute command chown on file or directory
function chownCmd(){
	local user="$1"
	local group="$2"
	local pathFileOrDir="$3"

	# Execute command
	eval "sudo chown -R $user:$group $pathFileOrDir"
}

# Install Linux Mint Applets
function installLinuxMintApplets(){
    if [ $(getOperatingSytem "linux mint") -eq 1 ]; then
        local zipFile="$1"
        local appletsPath="$homePath/.local/share/cinnamon/applets"

        # Create applets path
        mkdir -p "$appletsPath"

        # Install applets
        unzip "$zipFile" -d "$appletsPath/"
    else
        echo "Linux Mint is necessary to install applets"
    fi
}

# Return if operatin system is instaled
function getOperatingSytem(){
    local nameSO="$1"

    if [ $(lsb_release -a | grep -ci "$nameSO") -ge 1 ]; then
        echo "1"
    else
        echo "0"
    fi
}

# Dowload any data from link
function downloadFromLink(){
	local link="$1"
	local destPath="$2"
	local nameForFile="$3"
	local command="wget"

	if [ -z "$destPath" ]; then
		destPath="/tmp"
	fi

	if [ ! -z $nameForFile ]; then
		command="$command -O \"$destPath/$nameForFile\""
    else
        command="$command -P \"$destPath\""
	fi

	# Download
	eval "$command \"$link\""
}

# Return All Args received on string
function getAllArgsAndReturn(){
    local -a allArgs=($1)
    local wordToReturn=""
    local -i firstRun="0"

    for arg in "${allArgs[@]}"; do
        if [ $firstRun -eq  0 ]; then
            wordToReturn="$arg"
        else
            wordToReturn="$wordToReturn\n$arg"
        fi

        if [ $firstRun -eq  0 ]; then
            firstRun=$firstRun+1
        fi
    done

    printf "$wordToReturn"
}

# Return word by separator
function cutStringBySeparator(){
    local string="$1"
    local separator="$2"
    local direction="$3"
    local commandDir

    if [ "$direction" = "l" ]; then
        echo "$string" | awk -F"$separator" '{$0=$1}1'
    elif [ "$direction" = "r" ]; then
        echo "$string" | awk -F"$separator" '{$0=$2}1'
    else
        echo "$string"
    fi
}

# Check if is operating system permited
function checkOperatingSystemPermited(){
	local -i result=0
    for SO in "${operatingSystemPermited[@]}"; do
    	if [ $(getOperatingSytem "$SO") -eq 1 ]; then
    		result=1
    		break
    	fi
    done

    # Return
    echo "$result"
}

# Check service is active or not
function isServiceActive(){
	local nameService="$1"
	local -i isActive=$(ps -e | grep -v grep | grep -c "$nameService")

	if [ $isActive -ge 1 ]; then
		echo "1"
	else
		echo "0"
	fi
}

# Install All Dependencies
function installDependencies(){
	local appDependence="language-selector-common wget"
	local apps=("$appDependence")

    printf "\nInstall Dependencies for MS_functions...\n"

	# Update System
	sudo apt update > /dev/null

	# Install
	installAPT "${apps[@]}"
}

# Start All Dependencies
function startAppsDependencies(){
    printf "\nStart Dependencies for MS_functions...\n"

    # Start Snap
    if [ $(isServiceActive "snapd") -lt 1 ]; then
    	sudo service snapd start
    fi
}

# Main
case "$operation" in
    -t|--trim)
        shift
        trim "$@"
        exit 0
    ;;
    -e|--emptyLines)
        shift
        printEmptyLines "$@"
        exit 0
    ;;
    "-iD")
        installDependencies
        startAppsDependencies
        ;;
    "-existPPA")
        checkIsAddedPPA "${args[@]}"
        ;;
    "-isId")
        checkIsInstaled "${args[@]}"
        ;;
    "-existFile")
        existFile "${args[@]}"
        ;;
    "-existDir")
        existDir "${args[@]}"
        ;;
    "-kPID")
        echo "Kill PID if exist..."
        killPID "${args[@]}"
        ;;
    "-delFile")
        echo "Delete File if exist..."
        removeFile "${args[@]}"
        ;;
    "-delDir")
        echo "Delete Directory if exist..."
        removeDir "${args[@]}"
        ;;
    "-dBFile")
        echo "Create Boot Desktop files..."
        createBootDesktop "${args[@]}"
        ;;
    "-dNFile")
        echo "Create Normal Desktop files..."
        createNormalDesktop "${args[@]}"
        ;;
    "-eCmd")
        execCommandGetOutput "${args[@]}"
        ;;
    "-chown")
        echo "Execute command chown on file or directory..."
        chownCmd "${args[@]}"
        ;;
    "-iAPT")
        installAPT "${args[@]}"
        ;;
    "-uAPT")
        uninstallAPT "${args[@]}"
        ;;
    "-iSNAP")
        installSNAP "${args[@]}"
        ;;
    "-uSNAP")
        uninstallSNAP "${args[@]}"
        ;;
    "-iFLATPAK")
        installFLATPAK "${args[@]}"
        ;;
    "-uFLATPAK")
        uninstallFLATPAK "${args[@]}"
        ;;
    "-iGExt")
        installGnomeShellExtension "${args[@]}"
        ;;
    "-iLMApplets")
        installLinuxMintApplets "${args[@]}"
        ;;
    "-isOS")
        getOperatingSytem "${args[@]}"
        ;;
    "-iDeb")
        installDebFiles "${args[@]}"
        ;;
    "-iRpm")
        installRpmFiles "${args[@]}"
        ;;
    "-dFLink")
        downloadFromLink "${args[@]}"
        ;;
    "-gArgs")
        getAllArgsAndReturn "${args[@]}"
        ;;
    "-existGDriver")
        checkGraphicVendor "${args[@]}"
        ;;
    "-cls")
        clearScreen
        ;;
    "-cut")
        cutStringBySeparator "${args[@]}"
        ;;
    "-isSA")
        isServiceActive "${args[@]}"
        ;;
    *)
        echo "$0 OPERATION ARGS"
        printf "\n\nOPERATION:"

        # iD
        printf "\n\t-iD: Install All Dependencies\n"
        printf "\t\tARGS: None"

        # existPPA
        printf "\n\t-existPPA: Check if ppa/remote exist\n"
        printf "\t\tARGS: PPA (APT|FLATPAK)"

        # isId
        printf "\n\t-isId: Check if app is instaled\n"
        printf "\t\tARGS: NameApp (APT|SNAP|FLATPAK)"

        # existFile
        printf "\n\t-existFile: Check if file exist\n"
        printf "\t\tARGS: NameFile"

        # existDir
        printf "\n\t-existDir: Check if directory exist\n"
        printf "\t\tARGS: NameDirectory"

        # kPID
        printf "\n\t-kPID: Kill PID if exist\n"
        printf "\t\tARGS: PID"

        # delFile
        printf "\n\t-delFile: Delete file if exist\n"
        printf "\t\tARGS: Full_Path_File"

        # delDir
        printf "\n\t-delDir: Delete directory if exist\n"
        printf "\t\tARGS: Full_Path_Directory"

        # dBFile
        printf "\n\t-dBFile: Create Boot Desktop files\n"
        printf "\t\tARGS: Name_App Executable useTerminal(1|0) Icon ExtraLines"

        # dNFile
        printf "\n\t-dNFile: Create Normal Desktop files\n"
        printf "\t\tARGS: Name_App Executable useTerminal(1|0) Icon ExtraLines"

        # eCmd
        printf "\n\t-eCmd: Execute command and return output\n"
        printf "\t\tARGS: Command"

        # chown
        printf "\n\t-chown: Execute command chown on file or directory\n"
        printf "\t\tARGS: User(Can be empty string) Group(Can be empty string) Full_Path"

        # iAPT
        printf "\n\t-iAPT: Install APT APP (0/null = install recommends | 1 = no install recommends)\n"
        printf "\t\tARGS: \"app1 ...\" \"ppa1 ...\" (0|1)"

        # uAPT
        printf "\n\t-uAPT: Uninstall APT APP\n"
        printf "\t\tARGS: \"app1 ...\" \"ppa1 ...\""

        # iSNAP
        printf "\n\t-iSNAP: Install SNAP APP\n"
        printf "\t\tARGS: \"app1 ...\" \"type1 ...\"(classic|stable|...)"

        # uSNAP
        printf "\n\t-uSNAP: Uninstall SNAP APP\n"
        printf "\t\tARGS: \"app1 ...\""

        # iFLATPAK
        printf "\n\t-iFLATPAK: Install FLATPAK APP\n"
        printf "\t\tARGS: \"app1 ...\" \"vendor1 ...\" \"remote1 ...\""

        # uFLATPAK
        printf "\n\t-uFLATPAK: Uninstall FLATPAK APP\n"
        printf "\t\tARGS: \"app1 ...\" \"remote1 ...\""

        # iGExt
        printf "\n\t-iGExt: Install Gnome Extension\n"
        printf "\t\tARGS: Full_Path_ZIP_FILE"

        # iLMApplets
        printf "\n\t-iLMApplets: Install Linux Mint Applets\n"
        printf "\t\tARGS: Full_Path_ZIP_FILE"

        # isOS
        printf "\n\t-isOS: Check if Operating System Installed\n"
        printf "\t\tARGS: \"NameOperatingSystem\""

        # iDeb
        printf "\n\t-iDeb: Install DEB Files\n"
        printf "\t\tARGS: \"app1.deb ...\""

        # iRpm
        printf "\n\t-iRpm: Install RPM Files\n"
        printf "\t\tARGS: \"app1.rpm ...\""

        # dFLink
        printf "\n\t-dFLink: Dowload any data from link\n"
        printf "\t\tARGS: Link \"DestPath\"(Default: /tmp) \"NameForFile\"(OPTIONAL)"

        # gArgs
        printf "\n\t-gArgs: Return All Args received on string\n"
        printf "\t\tARGS: ALL POSSIBLE ARGS"

        # existGDriver
        printf "\n\t-existGDriver: Check Graphic Vendors\n"
        printf "\t\tARGS: NameVendor"

        # cls
        printf "\n\t-cls: Clear Screen\n"
        printf "\t\tARGS: None"

        # cut
        printf "\n\t-cut: Return word by separator\n"
        printf "\t\tARGS: \"string\" \"separator\" l|r(left|rigth)"

        # isSA
        printf "\n\t-isSA: Check if service is active\n"
        printf "\t\tARGS: name_of_service"

        printf "\n"
        ;;
esac