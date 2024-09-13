#!/bin/bash
#
#------------------------------------------------------------------------------------------------#
####################  Package Managers Functions  #################
#------------------------------------------------------------------------------------------------#
#
## Remove CD Install from Sources List ##
#--------------------------------------#
#
Disable_CD_from_source_list() {
	if (sudo sed -i "s:^deb cdrom:#deb cdrom:1" /etc/apt/sources.list); then
		printf "${BBlue} ⤅ ${Green}Removed CDRoom from APT repository.\n${NC}"
	else
		printf "${Red} ⤅ Error removing deb cdrom from APT repo.\n${NC}"
	fi
}
#
## Create & Manage APT Preferences File ##
#----------------------------------------#

confAptPref() {
	if  grep -q "$1" "/etc/apt/preferences" && [ "$1" != "*" ]; then
            printf "${BBlue} ⤅ ${Green}$1 package already in APT Preference file.\n${NC}"	
    elif awk -v pkg="$1" -v rel="$2" '
        BEGIN { found=0 }
        /^Package: / { 
            if ($2 == pkg) { 
                getline; 
                if ($1 == "Pin:" && $2 == "release" && $3 == "a=" rel) found=1 
            }
        }
        END { exit !found }  # Alterado para sair com sucesso (0) se NÃO encontrou (found=0)
    ' /etc/apt/preferences; then
        printf "${BBlue} ⤅ ${Green}$2 repo already in APT Preference file.\n${NC}"
        aptTrue=1
    else
        if sudo bash -c 'cat  >> /etc/apt/preferences << EOF

Package: '"$1"'
Pin: release a='"$2"'
Pin-Priority: '"$3"'
EOF
        '; then
            printf "${BBlue} ⤅ ${Green}$1 package added to APT Preferences file.\n${NC}"
            aptTrue=1
        else
            printf "${Red} ⤅ Failed to add $1 package to APT Preference file.\n${NC}"
            aptTrue=0
        fi
    fi
}

aptPreferences() {
    if [ ! -f /etc/apt/preferences ]; then
        if sudo touch /etc/apt/preferences; then
            sudo bash -c 'cat >> /etc/apt/preferences << EOF
#   How APT Interprets Priorities
#       Priorities (P) assigned in the APT preferences file must be positive or negative integers.
#       They are interpreted as follows (roughly speaking):
#
#       P >= 1000
#           causes a version to be installed even if this constitutes a downgrade of the package
#
#       990 <= P < 1000
#           causes a version to be installed even if it does not come from the target release,
#           unless the installed version is more recent
#
#       500 <= P < 990
#           causes a version to be installed unless there is a version available belonging to the
#           target release or the installed version is more recent
#
#       100 <= P < 500
#           causes a version to be installed unless there is a version available belonging to some
#           other distribution or the installed version is more recent
#
#       0 < P < 100
#           causes a version to be installed only if there is no installed version of the package
#
#       P < 0
#           prevents the version from being installed
#
#       P = 0
#           has undefined behaviour, do not use it.

Package: *
Pin: release a=stable
Pin-Priority: 500
EOF
            '
            printf "${BBlue} ⤅ ${Green}APT Preference file successfully created.\n${NC}"
            confAptPref "$@"
        else
            printf "${Red} ⤅ Failed to create APT Preference file.\n${NC}"
        fi
    else
        printf "${BBlue} ⤅ ${Green}APT Preference file already exist.\n${NC}"
        confAptPref "$@"
    fi
}
#
## Add Unstable and Testing Repos to APT ##
#----------------------------------------#
Add_Testing_and_Unstable_Repo() {
## For Testing Repo
    if grep -q "testing" "/etc/apt/sources.list"; then
        printf "${BBlue} ⤅ ${Green}Testing Repo already in APT Sources List.\n${NC}"
        aptPreferences '*' "testing" -1 	
    else
		if sudo bash -c 'cat >> /etc/apt/sources.list << EOF

# Testing
deb http://deb.debian.org/debian/ testing main
deb-src http://deb.debian.org/debian/ testing main
EOF
		'; then
            printf "${BBlue} ⤅ ${Green}Testing added to APT Sources List.\n${NC}"
            aptTrue=0
            aptPreferences '*' "testing" -1 
		else
            printf "${Red} ⤅ Failed to add Testing to APT Sources List.\n${NC}"
        fi
	fi

## For Unstable Repo
	if grep -q "unstable" '/etc/apt/sources.list'; then
        printf "${BBlue} ⤅ ${Green}Unstable Repo already in APT Sources List.\n${NC}"	
        aptPreferences '*' "unstable" -1            
    else
        if sudo bash -c 'cat >> /etc/apt/sources.list << EOF

# Unstable
deb http://deb.debian.org/debian/ unstable main
deb-src http://deb.debian.org/debian/ unstable main
EOF
        '; then
            printf "${BBlue} ⤅ ${Green}Added Unstable to APT repository.\n${NC}"
            aptTrue=0
            aptPreferences '*' "unstable" -1            
        else
            printf "${Red} ⤅ Failed to add Unstable to APT repository.\n${NC}"
        fi
	fi

    if [[ $aptTrue -eq 1 ]]; then 
        updateAPT
    else
        printf "${Red} ⤅ Cannot update APT as was an error in Preferences configuration.\n${NC}"
    fi
}
#
## FlatPak Repo Install ##
#------------------------#
# Add Flathub Repo
flatHub() {
    if (flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo); then
        printf "${BBlue} ⤅ ${Green}Flathub repo added to Flatpak.\n${NC}"
    else
        printf "${Red} ⤅ Failed to add Flathub repo to Flatpak.\n${NC}"
    fi
}
# Flatpak Install
Add_Flatpak() {
	printf "${BBlue} ⤅ ${Blue}Initianting Flatpak install.\n${NC}"
	installAPT flatpak
    flatHub
}
#
