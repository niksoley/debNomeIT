#!/bin/bash
#
#------------------------------------------------------------------------------------------------#
####################  Games  #################
#------------------------------------------------------------------------------------------------#
#
## Uninstall Gnome Games ##
#------------------------#
Uninstall_Gnome_Games() {
    if (apt purge --autoremove gnome-games); then
        printf "${BBlue} ⤅ ${Green}Succesfully uninstalled Gnome Games from APT.\n${NC}"
    else
        printf "${Red} ⤅ Failed to uninstall Gnome Games from APT.\n${NC}"
    fi
}