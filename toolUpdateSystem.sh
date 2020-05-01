#!/bin/bash
# Author: José Manuel C. Noronha

# Global Variable
declare functionShell="MS_functions"
declare homePath="$(echo $HOME)"
declare -a operatingSystemPermited=("Linux Mint")
declare selector="$1"

function sleepTime(){
	local -i timeToSleep=$1
	sleep $timeToSleep
}

# Check if is operating system permited
function checkOperatingSystemPermited(){
	local -i result=0
    for SO in "${operatingSystemPermited[@]}"; do
    	if [ $(lsb_release -a | grep -ci "$SO") -ge 1 ]; then
    		result=1
    		break
    	fi
    done

    # Return
    echo "$result"
}

# Update system and cache
function update() {
	# Space line
	printf "\nUpdate System\n"

	# Update System
	sudo apt update

	# Space line
	printf "\n\n"
}

# Fix Locale Package
function fixLocalePackage(){
	local lacaleLang="$(locale | grep LANGUAGE | cut -d '=' -f2- | cut -d ':' -f1)"

	printf "\nUpdate Language Pack...\n"

	# Get All missing language package
	language_all_package="$(check-language-support -l $lacaleLang)"
	local apps=("$language_all_package")

	# Install All missing language package
	sudo apt install ${apps[@]} -y
}

# Upgrade System All
function upgradeAll(){
	printf "\nUpgrade System...\n"
	# Upgrade System
	while [ 1 ]; do
		# Check if have new package
		if [ $(sudo apt list --upgradable | grep -c .) -le 1 ]; then
			break
		fi

		# Upgrade
		printf "Upgrade using apt\n"
		sudo apt upgrade -y
	done
}

# Upgrade Linux Mint
function upgradeMint(){
	# Verify is mint
	if [ $(lsb_release -a | grep -ci "linux mint") -ge 1 ]; then
		printf "\nUpgrade Linux Mint...\n"
		while [ 1 ]; do
			# Check if have new package
			if [ $(sudo mintupdate-cli -r list | grep -c .) -le 0 ]; then
				break
			fi

			# Upgrade
			printf "Upgrade using mintupdate-cli\n"
			sudo mintupdate-cli -ry upgrade
		done
	fi
}

# Update Snap
function updateSnap(){
	local -i isInstaled="$($functionShell -isId 'snapd' APT)"
	if [ $isInstaled -eq 1 ]; then
		printf "\nUpdate Snaps...\n"
		sudo snap refresh
	fi
}

# Update FLATPAK
function updateFlatpak(){
	local -i isPermitedSO=$(checkOperatingSystemPermited)
	local -i isInstaled="$($functionShell -isId 'flatpak' APT)"
	if [ $isInstaled -eq 1 ]; then
		printf "\nUpdate Flatpak...\n"

		if [ $isPermitedSO -eq 1 ]; then
			flatpak update
		else
			torsocks flatpak update
		fi
	fi
}

# Auto Remove all unncessary apps
function autoRemove(){
	printf "\nAuto remove apps...\n"
	sudo apt autoremove -y
}

# REMOÇÃO DOS FICHEIROS DE CONFIGURAÇÃO
function removeAllConfigFilesFromApps(){
	printf "\nRemove all files config...\n"
	# Comando para listar todos os APPS que estão instalados como também os
	# os ficheiros de configuração dos APPS que estiveram instalados
	comando_lista_dpkg="dpkg --list"

	# Na lista acima referida contêm linhas que iniciam com rc, o que significa que
	# são os APPS que deixaram os ficheiros de configuração e assim foram marcados
	# com palavra rc.
	palavra_chave="^rc"

	# O comando grep serve para fazer uma procura recursiva. Por exemplo, procurar
	# uma palavra num ficheiro retornando as linhas que contém a palavra.
	# Ao introduzir -c, o retorno do grep será o numero de linhas que contém a
	# palavra desejada
	comando_grep="grep -c"

	# Nome do ficheiro que irá receber a lista de APPS através do comando dpkg
	nome_lista_file="$homePath/lista_config_files"

	# Comando para remover o ficheiro acima mensionado
	remove_file="sudo rm $nome_lista_file"

	# Comando que remove os ficheiros de configuração dos app's que foram
	# desinstalados  
	comando_clean_config="dpkg -l | grep ^rc | awk '{ print $2}' | sudo xargs dpkg --purge"


	# >>>>>>>>>>> Execução dos comandos <<<<<<<<<<<
	# Execução do comando dpkg onde é armazenada a lista no ficheiro
	$comando_lista_dpkg > $nome_lista_file

	# Retorna o número de linhas do ficheiro que começam com rc
	num_linhas_com_rc=$(grep -c "$palavra_chave" $nome_lista_file)

	# Remove o ficheiro
	$remove_file

	# Condição que verifica se o valor de retorno do grep fôr igual a zero, quer
	# dizer que não existem ficheiro de configuração, caso contrário é executado o
	# comando para remove-los
	if [ $num_linhas_com_rc -eq "0" ]; then
		echo "Não existem ficheiros de configuração"
	else
		echo "Vai ser executado o comando: $comando_clean_config"
		dpkg -l | grep ^rc | awk '{ print $2}' | sudo xargs dpkg --purge
	fi
}

# Install All Depencies
function installDependecies(){
	sudo apt install language-selector-common -y
}

# Execute All Operation
function executeAllOperation(){
	update
	installDependecies
	fixLocalePackage
	upgradeAll
	upgradeMint
	updateSnap
	updateFlatpak
	autoRemove
	removeAllConfigFilesFromApps
}

# Help
function showHelp(){
	printf "Sequence of operation:\n"
	printf "\t1 - Update system and cache\n"
	printf "\t2 - Install All Depencies\n"
	printf "\t3 - Fix Locale Package\n"
	printf "\t4 - Upgrade System\n"
	printf "\t5 - Upgrade Linux Mint\n"
	printf "\t6 - Update Snap\n"
	printf "\t7 - Update FLATPAK\n"
	printf "\t7 - Auto Remove all unncessary apps\n"
	printf "\t8 - Remove all configs files\n"
	printf "\tImportant: If you have error, please run this command: $functionShell -iD\n"
}

# Main
function main(){
	case "$selector" in
		"-apt")
			update
			installDependecies
			upgradeAll
			upgradeMint
			autoRemove
			removeAllConfigFilesFromApps
			;;
		"-snap")
			update
			installDependecies
			updateSnap
			;;
		"-flatpak")
			update
			installDependecies
			updateFlatpak
			;;
		"-lang")
			update
			installDependecies
			fixLocalePackage
			;;
		"-all")
			executeAllOperation
			;;
		*)
			printf "\nUpdate System"
			printf "\n$0 OPTIONS\n"
			printf "\t -apt: Upgrade Apt package\n"
			printf "\t -snap: Upgrade Snap package\n"
			printf "\t -flatpak: Upgrade Flatpak package\n"
			printf "\t -lang: Upgrade Language package\n"
			printf "\t -all:\n"
			showHelp
			;;
	esac
}
main