#!/bin/bash
#
#------------------------------------------------------------------------------------------------#
####################  Global and Start Functions  #################
#------------------------------------------------------------------------------------------------#
## Global Variables ##
#--------------------#

# Colors Variables
Red='\033[0;31m'
Brown='\033[38;5;94m'
BrownBold='\033[1;33m'
Blue='\033[0;34m'
BBlue='\033[1;34m'
Green='\033[1;32m'
NC='\033[0m'
#
# Capture user name
username=$(whoami)
#
## Install Functions ##
#---------------------#
## Update & Upgrade APT
updateAPT() {
    sudo systemctl daemon-reload
	if (sudo apt update && sudo apt upgrade -y); then
		printf "${BBlue} ⤅ ${Green}APT repo successfully updated & upgraded.\n${NC}"
	else
		printf "${Red} ⤅ Failed to update & upgrade APT.\n${NC}"
	fi
}
#
installAPT() {
    for package in "$@"; do
        if sudo apt install -y "$package"; then
            printf "${BBlue} ⤅ ${Green}Successfully installed ${Brown}$package${Green} via APT.\n${NC}"
        else
            printf "${Red} ⤅ Failed to install ${Brown}$package${Red} via APT.\n${NC}"
        fi
    done
}
#
installFlat() {
    if (flatpak install -y --system "$1" "$2"); then
        printf "${BBlue} ⤅ ${Green}Successfully installed ${Brown}$2${Green} via Flatpak.\n${NC}"
    else
        printf "${Red} ⤅ Failed to install ${Brown}$2.\n${NC}"
    fi
}

## Log Functions ##
#---------------------#
# Small Log
#printf() {
#    # Captura a saída original do printf
#    output=$(builtin printf "$@")
    
    # Adiciona a hora:minuto:segundo ao arquivo, sem alterar a saída na tela
#    echo "$(date '+%H:%M:%S') $output" >> $script_dir/Logs/smallLog

    # Imprime a saída original na tela
#    builtin printf "$output"
#}

#exec > >(tee -a logfile.log) 2>&1

## Add User to Sudo ##
#--------------------#
Add_User_to_Sudo() {
    # Adding via usermod (requires reloggin to apply)
    sudoers_entry="$username ALL=(ALL:ALL) ALL"
    suoder_file="/etc/sudoers.d/PermConf"
    printf "${Blue}Enter root password${NC}"
    echo""
    if su -c "/usr/sbin/usermod -aG sudo $username && echo '$sudoers_entry' >> '$suoder_file'"; then
        cd ~ && source .profile
        cd ~ && source .bashrc
        printf "${BBlue} ⤅ ${Green}Successfully added ${username} to Sudo group and to Sudoers File.\n${NC}"
        # Remove Duplicates
        sudo awk -v user="$username" '
            BEGIN { seen = 0 }
            $0 == user " ALL=(ALL:ALL) ALL" {
                seen++
                if (seen == 1) {
                    print $0
                }
                next
            }
            { print }
        ' "$suoder_file" | sudo tee "$suoder_file" > /dev/null
    else
        printf "${Red} ⤅ Failed to add ${username} to Sudo group and Sudoers File.\n${NC}"
    fi
}

## Add Nertwork Drive ##
#----------------------#

add_cron_mount() {
    cron_entry="* * * * * /usr/bin/sudo /bin/mount -a"
    cron_file="/etc/crontab"

    if ! grep -Fxq "$cron_entry" "$cron_file"; then
        if echo "$cron_entry" | sudo tee -a "$cron_file" > /dev/null; then
            printf "${BBlue} ⤅ ${Green}Successfully added auto mount to Crontab.\n${NC}"
        else
            printf "${Red} ⤅ Failed to add auto mount to Crontab.\n${NC}"
        fi
    else
        printf "${BBlue} ⤅ ${Blue}Auto mount already configured in Crontab.\n${NC}"
    fi
}

applyDriver() {
    echo -e "Verify the information below and press ${Green}'y'${NC} if it is correct, ${Blue}'r'${NC} to redo, or ${Red}'e'${NC} to exit:"
    echo -e "${BBlue}${fstabEntry}${NC}"
    read -p "$(echo -e "Choice (${Green}y${NC}/${Blue}r${NC}/${Red}e${NC}): ")" driverChoice
    case $driverChoice in
        y|Y)
            if echo "$fstabEntry" | sudo tee -a "/etc/fstab" > /dev/null; then
                printf "${BBlue} ⤅ ${Green}Successfully added external driver.\n${NC}"
                sudo systemctl daemon-reload
                sudo mount -a
                add_cron_mount
            else
                printf "${Red} ⤅ Failed to add external driver.\n${NC}"
            fi
            ;;
        r|R)
            Add_Network_Driver
            ;;
        e|E)
            printf "${Blue}Exiting without making changes.\n${NC}"
            exit 0
            ;;
        *)
            printf "${Red}Invalid option. Please try again.\n${NC}"
            applyDriver
            ;;
    esac
}

Add_Network_Driver() {
    read -p "Enter network driver IP (e.g., 192.168.122.75): " ipChoice
    read -p "Enter the source folder (leave blank for entire driver, e.g., /documents/): " folderChoice
    read -p "Enter the destination folder (e.g., /home/user/Documents/): " destChoice
    read -p "Enter file permissions (e.g., 777): " filePerm
    read -p "Enter directory permissions (e.g., 777): " dirPerm
    read -p "Enter driver username (leave blank if no login is required): " userChoice
    
    if [[ -n "$userChoice" ]]; then
        read -sp "Enter driver password: " passChoice
        fstabEntry="//${ipChoice}${folderChoice} ${destChoice} cifs username=${userChoice},password=${passChoice},file_mode=0${filePerm},dir_mode=0${dirPerm} 0 0"
    else
        fstabEntry="//${ipChoice}${folderChoice} ${destChoice} cifs file_mode=0${filePerm},dir_mode=0${dirPerm} 0 0"
    fi

    echo -e "\n"
    applyDriver
}





