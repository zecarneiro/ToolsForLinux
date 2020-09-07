#!/bin/bash
# Author: José M. C. Noronha

# Global variable
declare operation="$1"; shift
declare -a args=("$@")
declare home="$(echo $HOME)"
declare -a operatingSystemPermited=("Linux Mint")

# Clear Terminal Window
function clearScreen(){
	printf "\033c"
}

# Print empty lines
function printEmptyLines(){
	local numOfLines="$1"

	if [ ! -z $numOfLines ]; then
		for (( i = 0; i < $numOfLines; i++ )); do
			echo
		done
	fi
}

# Check if installed
function checkIsInstaled(){
    local nameApp="$1"
    local typeApp="$2"

    if [ "$typeApp" = "APT" ]; then # APT
        apt list --installed | grep -ci "$nameApp" | awk '{if ($1 > "0") {print "1"} else {print "0"}}'
    elif [ "$typeApp" = "SNAP" ]; then # SNAP
    	snap list | awk '{if (NR!=1) {print $1}}' | grep -ci "$nameApp" | awk '{if ($1 > "0") {print "1"} else {print "0"}}' | awk '{$1=$1;print}'
    elif [ "$typeApp" = "FLATPAK" ]; then # FLATPAK 
    	flatpak list --all | awk '{if (NR!=1) {print $1}}' | grep -ci "$nameApp" | awk '{if ($1 > "0") {print "1"} else {print "0"}}'
    else
    	echo "0"
    fi
}

# Check if ppa/remote exist or not
function checkIsAddedPPA(){
    local ppa="$1"
    local typePPA="$2"
    local -i existPPA
    
    if [ ! -z "$ppa" ]; then
    	if [ "$typePPA" = "APT" ]; then # APT
    		 if [ ! -z "$(echo "$ppa" | cut -d ":" -f2)" ]; then
	            ppa="$(echo "$ppa" | cut -d ":" -f2)"
	        fi

	        existPPA=$(grep "^deb .*$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -c .)
	        if [ $existPPA -gt 0 ]; then
	            echo "1"
	        else
	        	echo "0"
	        fi
    	elif [ "$typePPA" = "FLATPAK" ]; then # FLATPAK
    		flatpak remote-list | awk '{if (NR!=0) {print $1}}' | grep -ci "$ppa" | awk '{if ($1 > "0") {print "1"} else {print "0"}}'
    	fi
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

# Kill app with pid
function killPID(){
	local pid="$1"
	local -i existPID
	local -a subprocessPID=()

	if [ ! -z "$pid" ]; then
		# Check if pid exist
		existPID=$(ps ax | grep $pid | grep -v grep | grep -c .)

		# Kill All PIDs
		if [ $existPID -gt 0 ]; then
		    subprocessPID=( "$(pgrep -P $pid)" )

		    # Kill PID Pai
		    kill $pid 2> /dev/null

		    for PID in "${subprocessPID[@]}"; do
		        if [ ! -z "$PID" ]; then
		            # Check if pid exist
                    existPID=$(ps ax | grep $PID | grep -v grep | grep -c .)

                    # add pid
                    if [ $existPID -gt 0 ]; then
                        # Kill subprocess PID
		                kill $PID 2> /dev/null
                    fi
		        fi
            done
		fi
	fi
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

# Create Boot Desktop files
function createBootDesktop(){
    local appName="$1"
	local cmdToExec="$2"
    local useTerminal="$3"
	local icon="$4"
    local extraLines="$5"
    local autoStartApp="$home/.config/autostart"
    local desktopFullPath="$autoStartApp/$appName.desktop"
    local desktopFiletext

    # Create path
    mkdir -p "$autoStartApp"

    # Auto start app
    desktopFiletext="[Desktop Entry]"
    desktopFiletext="$desktopFiletext\nType=Application"
    desktopFiletext="$desktopFiletext\nExec=$cmdToExec"
    desktopFiletext="$desktopFiletext\nIcon=$icon"
    desktopFiletext="$desktopFiletext\nHidden=false"
    desktopFiletext="$desktopFiletext\nNoDisplay=false"

    # Define if use terminal or not
    if [ $useTerminal -eq 1 ]; then
        desktopFiletext="$desktopFiletext\nTerminal=true"
    else
        desktopFiletext="$desktopFiletext\nTerminal=false"
    fi

    desktopFiletext="$desktopFiletext\nX-GNOME-Autostart-enabled=true"
    desktopFiletext="$desktopFiletext\nName[pt]=$appName"
    desktopFiletext="$desktopFiletext\nName=$appName"
    desktopFiletext="$desktopFiletext\nComment[pt]="
    desktopFiletext="$desktopFiletext\nComment=\n"
    desktopFiletext="$desktopFiletext\n$extraLines"
    printf "$desktopFiletext" | tee "$desktopFullPath" > /dev/null
    chmod +x "$desktopFullPath"
}

# Create Normal Desktop files
function createNormalDesktop(){
	local appName="$1"
	local cmdToExec="$2"
    local useTerminal="$3"
	local icon="$4"
    local extraLines="$5"
	local normalApp="$home/.local/share/applications"
	local desktopFullPath="$normalApp/$appName.desktop"
    local desktopFiletext

    # Create path
    mkdir -p "$normalApp"

    # Normal App
    desktopFiletext="[Desktop Entry]"
    desktopFiletext="$desktopFiletext\nType=Application"
    desktopFiletext="$desktopFiletext\nExec=$cmdToExec"
    desktopFiletext="$desktopFiletext\nIcon=$icon"

    # Define if use terminal or not
    if [ $useTerminal -eq 1 ]; then
        desktopFiletext="$desktopFiletext\nTerminal=true"
    else
        desktopFiletext="$desktopFiletext\nTerminal=false"
    fi

    desktopFiletext="$desktopFiletext\nName[pt]=$appName"
    desktopFiletext="$desktopFiletext\nName=$appName"
    desktopFiletext="$desktopFiletext\nGenericName=$appName\n"
    desktopFiletext="$desktopFiletext\n$extraLines"
    printf "$desktopFiletext" | tee "$desktopFullPath" > /dev/null
    chmod +x "$desktopFullPath"
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

# Install APT APP
function installAPT(){
    local -a apps=($1)
    local -a ppa=($2)
    local -i noRecomends="$3"

    # Set ppa
    for PPA in "${ppa[@]}"; do
        if [ ! -z "$PPA" ]; then
            if [ $(checkIsAddedPPA "$PPA" "APT") -eq 0 ]; then
                echo "Set PPA: $PPA..."
                sudo add-apt-repository "$PPA" -y
                printEmptyLines 2
                sudo apt update
            else
                echo "This $PPA Already Exist..."
            fi
        fi
    done

    # Install
    for APP in "${apps[@]}"; do
        if [ $(checkIsInstaled "$APP" "APT") -eq 0 ]; then
            echo "Install: $APP..."

            if [ ! -z "$noRecomends" ]||[ $noRecomends -eq 0 ]; then
                sudo apt install "$APP" -y
            else
                sudo apt install --no-install-recommends "$APP" -y
            fi
            printEmptyLines 2
        else
            echo "$APP Already Installed..."
        fi
    done
}

# Uninstall APT APP
function uninstallAPT(){
    local -a apps=($1)
    local -a ppa=($2)

    # Del ppa
    for PPA in "${ppa[@]}"; do
        if [ ! -z "$PPA" ]; then
            if [ $(checkIsAddedPPA "$PPA" "APT") -eq 1 ]; then
                echo "Remove PPA: $PPA..."
                sudo add-apt-repository -r "$PPA" -y
                printEmptyLines 2
                sudo apt update
            fi
        fi
    done

    # Uninstall
    for APP in "${apps[@]}"; do
        echo "Uninstall: $APP..."
        if [ $(checkIsInstaled "$APP" "APT") -eq 1 ]; then
            sudo apt purge --auto-remove "$APP" -y

            echo "Clear $APP..."
            sudo apt clean "$APP"
            printEmptyLines 2
        fi
    done
}

# Install SNAP APP
function installSNAP(){
    local -a apps=($1)
    local -a types=($2)
    local type
    local -i typesIndex=0

    # Install
    for APP in "${apps[@]}"; do
        if [ $(checkIsInstaled "$APP" "SNAP") -eq 0 ]; then
            echo "Install: $APP..."

            if [ ! -z ${types[$types]} ]&&[ "${types[$types]}" != "" ]; then
                type=${types[$types]}
            else
                type="classic"
            fi
            sudo snap install "$APP" --$type
            printEmptyLines 2
        else
            echo "$APP Already Installed..."
        fi
        typesIndex=$typesIndex+1
    done
}

# Uninstall SNAP APP
function uninstallSNAP(){
    local -a apps=($1)

    # Uninstall
    for APP in "${apps[@]}"; do
        echo "Uninstall $APP..."
        if [ $(checkIsInstaled "$APP" "SNAP") -eq 1 ]; then
        	echo "Remove Remote: $PPA..."
            sudo snap remove "$APP"
            printEmptyLines 2
        fi
    done
}

# Install FLATPAK APP
function installFLATPAK(){
    local -a apps=($1)
    local vendorApp=($2)
    local -a ppa=($3)
    local -i vendorIndex=0
    local -i isPermitedSO=$(checkOperatingSystemPermited)

    # Set ppa
    for PPA in "${ppa[@]}"; do
        if [ ! -z "$PPA" ]; then
            if [ $(checkIsAddedPPA "${vendorApp[$vendorIndex]}" "FLATPAK") -eq 0 ]; then
            	PPA="${vendorApp[$vendorIndex]} $PPA"
                echo "Set Remote: $PPA..."
                
                if [ $isPermitedSO -eq 1 ]; then
                	flatpak remote-add --if-not-exists $PPA
                    printEmptyLines 2
                    flatpak update
                else
                	torsocks flatpak remote-add --if-not-exists $PPA
                    printEmptyLines 2
                    torsocks flatpak update
                fi
            else
                echo "This $PPA Already Exist..."
            fi
        fi
        vendorIndex=$vendorIndex+1
    done

    # Install
    vendorIndex=0
    for APP in "${apps[@]}"; do
        if [ $(checkIsInstaled "$APP" "FLATPAK") -eq 0 ]; then
        	APP="${vendorApp[$vendorIndex]} $APP"
            echo "Install: $APP..."
            if [ $isPermitedSO -eq 1 ]; then
            	flatpak install $APP
            else
            	torsocks flatpak install $APP
            fi
            printEmptyLines 2
        else
            echo "$APP Already Installed..."
        fi
        vendorIndex=$vendorIndex+1
    done
}

# Uninstall FLATPAK APP
function uninstallFLATPAK(){
    local -a apps=($1)
    local -a ppa=($2)
    local -i isPermitedSO=$(checkOperatingSystemPermited)

    # Del ppa
    for PPA in "${ppa[@]}"; do
        if [ ! -z "$PPA" ]; then
            if [ $(checkIsAddedPPA "$PPA" "FLATPAK") -eq 1 ]; then
                echo "Remove Remote: $PPA..."

                if [ $isPermitedSO -eq 1 ]; then
                	flatpak remote-delete $PPA
                    printEmptyLines 2
                    flatpak update
                else
                	torsocks flatpak remote-delete $PPA
                    printEmptyLines 2
                    torsocks flatpak update
                fi
            fi
        fi
    done

    # Uninstall
    for APP in "${apps[@]}"; do
        if [ $(checkIsInstaled "$APP" "FLATPAK") -eq 1 ]; then
            echo "Uninstall $APP..."
            if [ $isPermitedSO -eq 1 ]; then
            	flatpak uninstall $APP
            else
            	torsocks flatpak uninstall $APP
            fi
            printEmptyLines 2
        fi
    done
}

# Install DEB Files
function installDebFiles(){
	local -a apps=($1)

	# Install
    for APP in "${apps[@]}"; do
        echo "Install $APP..."
        sudo gdebi -n "$APP"
        printEmptyLines 2
    done
}

# Install RPM Files
function installRpmFiles(){
	local -a apps=($1)

	# Install
    for APP in "${apps[@]}"; do
        echo "Install $APP..."
        sudo alien -i "$APP"
        printEmptyLines 2
    done
}

# Install Gnome Shell Extension
function installGnomeShellExtension(){
    local zipFile="$1"
    local uuid="$(unzip -c "$zipFile" metadata.json | grep uuid | cut -d \" -f4)"

    if [ ! -z $uuid ]; then
        local extensionsPath="$home/.local/share/gnome-shell/extensions/$uuid"

        # Create extension path
        mkdir -p "$extensionsPath"

        # Install Extension
        unzip -q "$zipFile" -d "$extensionsPath/"
        gnome-shell-extension-tool -e "$uuid"
    else
        echo "ERROR: Failed on get UUID"
    fi
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
	local appDependence="torsocks language-selector-common snapd snapd-xdg-open flatpak xdg-desktop-portal-gtk gnome-software-plugin-flatpak gdebi alien wget"
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
function main(){
    case "$operation" in
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
}
main