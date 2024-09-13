#!/bin/bash
#
#------------------------------------------------------------------------------------------------#
####################  Office  #################
#------------------------------------------------------------------------------------------------#
#
## Office ##
#------------------------#
Libre_Office() {
    if (sudo apt purge libreoffice); then
        printf "${BBlue} ⤅ ${Green}Succesfully uninstalled Libre Office from APT.\n${NC}"
    else
        printf "${Red} ⤅ Failed to uninstall Libre Office from APT.\n${NC}"
    fi 
    installFlat flathub org.libreoffice.LibreOffice
}