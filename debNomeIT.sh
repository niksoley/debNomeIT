#!/bin/bash
#-------------------------------------------------------------------------------------------------#
###################################################################################################
########################## Debian 12 Installation & Configuration Script ##########################
###################################################################################################
#-------------------------------------------------------------------------------------------------#
#
#------------------------------------------------------------------------------------------------#
####################  Source Files  #################
#------------------------------------------------------------------------------------------------#

for file in ./Functions/*.sh; do
	source "$file"
done
#
#------------------------------------------------------------------------------------------------#
####################  Values  #################
#------------------------------------------------------------------------------------------------#

# Main Menu Options
mainmenu_options=("Initial Setup" "Package Manager" "System Utils" "Gnome and UI" "Internet" "Office" "Communication" "Academic" "Dev" "Players" "Games" "Miscellaneous" "General View" "Exit")
#------------------------------------------------------------

# Initial Setup Options
Initial_Setup_options=("Add User to Sudo" "Add Network Driver")

#------------------------------------------------------------

# Package Manager Options
Package_Manager_options=("Disable CD from source list" "Add Testing and Unstable Repo" "Add Flatpak")

#------------------------------------------------------------
# System Conf Options
System_Utils_options=("Basic Packages" "Flat Seal" "Trash CLI" "BTOP" "Image to Text")

#*System Conf Basic Packages*
basic_packs=(git curl python3 locate wget p7zip-full make)

#------------------------------------------------------------
# Gnome Custom
Gnome_and_UI_options=("FlatPak Plugin" "Gnome Extension Manager" "Gnome Extensions" "WhiteSur Theme" "Shell Theme" "Wallpaper"  "Nerd Fonts" "Other Confs" "Starship" "EZA" "Neofetch" "GRUB Config")

#------------------------------------------------------------
# Internet
Internet_options=("Hardened Firefox" "Chromium" "Tor" "Local piHole")

#------------------------------------------------------------
# Office
Office_options=(("Libre Office" "Only Office") "MS Office")

#------------------------------------------------------------
# Communication
Communication_options=("Discord" "Slack" "Telegram")

#------------------------------------------------------------
# Academic
Academic_options=("Obsidian" "Anki")

#------------------------------------------------------------
# Development
Dev_options=("GitHub CLI" "VSCode" "Docker" "PodMan" "QEMU KVM")

#------------------------------------------------------------
# Players
Players_options=("VLC")

#------------------------------------------------------------
# Games
Games_options=("Uninstall Gnome Games")

#------------------------------------------------------------
# Miscellaneous
Miscellaneous_options=("QBitTorrent")

#------------------------------------------------------------------------------------------------#
####################  Start  #################
#------------------------------------------------------------------------------------------------#
# Call the main function
menu "${mainmenu_options[@]}"
