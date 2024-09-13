#!/bin/bash
#
#------------------------------------------------------------------------------------------------#
####################  System Conf Functions  #################
#------------------------------------------------------------------------------------------------#

## Function to install basic packages ##
#--------------------------------------#
Basic_Packages() {
    for pack in "${basic_packs[@]}"; do
        installAPT "$pack"
    done
}

## Flat Seal ##
#-------------#
# Configure Flat Seal
flatConf() {
    printf "${BBlue} ⤅ ${Blue}Configuring Flat Seal.\n${NC}"
    flatpak override --user --filesystem=xdg-config/gtk-4.0:ro --filesystem=xdg-config/gtk-3.0:ro
    flatpak override --user --device=dri
    flatpak override --user --filesystem=home
}
# Install Flat Seal
Flat_Seal() {
    installFlat "flathub" "com.github.tchx84.Flatseal"
    flatConf
}


## Trash CLI Install & Config ##
#------------------------------#
Trash_CLI() {
	if (installAPT "trash-cli"); then
        if ! grep -qxF "alias rm='trash-put'" /home/nikolas/.bashrc; then
            if sed -i "/'ls -CF'/a alias rm='trash-put'\nrmr='rm'" /home/nikolas/.bashrc; then
            source ~/.bashrc
            printf "${BBlue} ⤅ ${Green}Successfully configured Trash CLI.\n${NC}"
            else
            printf "${Red} ⤅ Failed to configured Trash CLI.\n${NC}"
            fi
        else
			printf "${BBlue} ⤅ ${Green}Trash CLI already configured.\n${NC}"
		fi
	fi
}

## Install Btop++ ##
#------------------#
BTOP() {
	installAPT "btop"
}

## Image to Text ##
#-----------------#
# Image to Text Script Creation
imageToTextScript() { 
    sudo bash -c 'cat > /usr/local/bin/screenshot_to_clipboard.sh <<EOF
#!/bin/bash

# Create a temporary directory
TMPDIR=\$(mktemp -d)

# Take a screenshot of a selected area and save it as screenshot.png in the temporary directory
gnome-screenshot -a -f \$TMPDIR/screenshot.png

# Process the screenshot with Tesseract and save the result to a text file in the temporary directory
tesseract \$TMPDIR/screenshot.png \$TMPDIR/output

# Copy the result to the clipboard
# ignore all non-ASCII characters
cat \$TMPDIR/output.txt |
    tr -cd '\''\\11\\12\\15\\40-\\176'\'' | grep . | perl -pe '\''chomp if eof'\'' |
    xclip -selection clipboard

# Optionally, remove the temporary directory when done
rm -r \$TMPDIR
EOF'
    sudo chmod 777 "/usr/local/bin/screenshot_to_clipboard.sh"
}
# Image to Text Shortcut Configuration
imageToTextShortchut() {
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Image_to_Text'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command '/bin/bash /usr/local/bin/screenshot_to_clipboard.sh'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Primary><Shift>t'
}
# Image to Text Installation
Image_to_Text() {
    installAPT "tesseract-ocr"
    installAPT "gnome-screenshot"
    if imageToTextScript; then
        printf "${BBlue} ⤅ ${Green}Successfully created Image to Text Script.\n${NC}"
        if imageToTextShortchut; then
            printf "${BBlue} ⤅ ${Green}Successfully created shortcut for Image to Text.\n${NC}"
        else
            printf "${Red} ⤅ Failed to create shortcut for Image to Text.\n${NC}"
        fi
    else
        printf "${Red} ⤅ Failed to create Image to Text Script.\n${NC}"
    fi
}