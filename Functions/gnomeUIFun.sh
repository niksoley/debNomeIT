#!/bin/bash
#
#------------------------------------------------------------------------------------------------#
####################  Gnome & UI Functions  #################
#------------------------------------------------------------------------------------------------#
#
## Gnome Flatpak Plugin ##
#------------------------#
FlatPak_Plugin() {
	installAPT "gnome-software-plugin-flatpak"
}
#
## Gnome Extension Manager ##
#------------------------#
Gnome_Extension_Manager() {
    installAPT "gnome-shell-extension-manager"
}
#
## Gnome Extensions ##
#------------------------#
# Gnome Extensions Install
gnomeExtInstall() {

	export XDG_RUNTIME_DIR="/run/user/$UID" # Directory for runtime files and sockets (temp)
	export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus" # D-Bus session address for communication
	
	array=(
		https://extensions.gnome.org/extension/3193/blur-my-shell/
		https://extensions.gnome.org/extension/3396/color-picker/
		https://extensions.gnome.org/extension/3843/just-perfection/
		https://extensions.gnome.org/extension/5446/quick-settings-tweaker/
		https://extensions.gnome.org/extension/1460/vitals/
		https://extensions.gnome.org/extension/4481/forge/
		https://extensions.gnome.org/extension/5090/space-bar/
		https://extensions.gnome.org/extension/16/auto-move-windows/
		https://extensions.gnome.org/extension/4944/app-icons-taskbar/
		https://extensions.gnome.org/extension/517/caffeine/
		https://extensions.gnome.org/extension/6186/remove-alttab-delay-fork/
		https://extensions.gnome.org/extension/5237/rounded-window-corners/
	)
	for i in "${array[@]}"; do
		
		# Search for the string data-uuid="..." within the HTML and extract it using grep.
		unset EXTENSION_ID
		EXTENSION_ID=$(curl -s $i | grep -oP 'data-uuid="\K[^"]+') 
		if [ -z "$EXTENSION_ID" ]; then
			printf "${Red} ⤅ Error: Could not find EXTENSION_ID for the URL: $i\n${NC}"
            continue
		else
			printf "${BBlue} ⤅ ${Green}Sucessfully found EXTENSION_ID: ${Brown}$EXTENSION_ID\n${NC}"
        fi
		
		# If extension already installed, go to the next
		if gnome-extensions list | grep --quiet $EXTENSION_ID; then
			printf "${BBlue} ⤅ ${Green}Extension ${Brown}${EXTENSION_ID}${Green} already installed.\n${NC}"
			continue
		fi

		# Look for recent extension version by the $EXTENSION_ID
		gnome_shell_version=$(gnome-shell --version | awk '{print $3}' | awk -F. '{print $1}')
		
		# Extract the version tag
		unset VERSION_TAG
		VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=$EXTENSION_ID" | jq -r --arg version "$gnome_shell_version" --arg uuid "$EXTENSION_ID" '
		.extensions[] |
		select(.uuid == $uuid) |
		if .shell_version_map[$version] == null then
			.shell_version_map | to_entries | map(.value.pk) | max
		else
			.shell_version_map[$version].pk
		end')
		
		if [ -z "$VERSION_TAG" ]; then
			printf "${Red} ⤅ Error: Could not determine VERSION_TAG for EXTENSION_ID: $EXTENSION_ID\n${NC}"
            continue
		else
			printf "${BBlue} ⤅ ${Green}Sucessfully determined VERSION_TAG: ${Brown}$VERSION_TAG\n${NC}"
        fi
		
		# Downloads the extension file "${EXTENSION_ID}.zip"
        wget -O "${EXTENSION_ID}.zip" "https://extensions.gnome.org/download-extension/${EXTENSION_ID}.shell-extension.zip?version_tag=$VERSION_TAG"
        if [ ! -f "${EXTENSION_ID}.zip" ]; then
			printf "${Red} ⤅ Error: The file ${EXTENSION_ID}.zip was not downloaded correctly.\n${NC}"
            continue
		else
			printf "${BBlue} ⤅ ${Green}Sucessfully downloaded ${Brown}${EXTENSION_ID}.zip.\n${NC}"
        fi

		# Install via gnome-extension
		installGnomeExt() {
			if gnome-extensions install --force "${EXTENSION_ID}.zip"; then
				printf "${BBlue} ⤅ ${Green}Successfully installed extension ${Brown}${EXTENSION_ID}${Green} via "gnome-extensions".\n${NC}"
			else
				printf "${Red} ⤅ Error: Failed to install extension ${EXTENSION_ID} via "gnome-extensions".\n${NC}"
			fi
		}
		# Verify if extension is installed
		if gnome-extensions list | grep --quiet $EXTENSION_ID; then
			printf "${BBlue} ⤅ ${Green}Extension ${Brown}${EXTENSION_ID}${Green} already installed.\n${NC}"
		else
			installGnomeExt
		fi

		# If the extension is not installed, busctl is used to install"
		installGnomeBus() {
			if (busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s "${EXTENSION_ID}"); then
				printf "${BBlue} ⤅ ${Green}Successfully installed extension ${Brown}${EXTENSION_ID}${Green} via "busctl".\n${NC}"
			else
				printf "${Red} ⤅ Error: Failed to install extension ${EXTENSION_ID} via "busctl".\n${NC}"
			fi
		}
		if gnome-extensions list | grep --quiet $EXTENSION_ID; then
			printf "${BBlue} ⤅ ${Green}Extension ${Brown}${EXTENSION_ID}{Green} already installed.\n${NC}"
		else
			installGnomeBus
		fi

		# Enable the extension
		if ! gnome-extensions enable "${EXTENSION_ID}"; then
			printf "${Red} ⤅ Error: Failed to enable extension ${EXTENSION_ID}.\n${NC}"
        else
            printf "${BBlue} ⤅ ${Green}Successfully enabled extension ${Brown}${EXTENSION_ID}.\n${NC}"
        fi

		rm -f "${EXTENSION_ID}.zip"
	done
}

# Gnome Extensions Config
# Auto Move Windows
autoMoveWindows() {
    moveWinStatus=$(gsettings get org.gnome.shell.extensions.auto-move-windows application-list)

	if [[ "$moveWinStatus" == *"$1"* ]]; then
        printf "${BBlue} ⤅ ${Brown}$1${Green} already configured in auto-move-windows extension.\n${NC}"
        return 1
    fi
    
    # Remove the last character (which is the closing bracket `]`)
    moveWinStatus="${moveWinStatus%?}"

    # Add the new application and workspace before the closing bracket
    moveWinStatus="$moveWinStatus, '$1:$2']"

    # Set the updated list back to gsettings
    if gsettings set org.gnome.shell.extensions.auto-move-windows application-list "$moveWinStatus"; then
        printf "${BBlue} ⤅ ${Brown}Auto Move Windows${Green} extension successfully configured.\n${NC}"
    else
        printf "${Red} ⤅ Failed to configure Auto Move Windows\n${NC}"
    fi

#gsettings set org.gnome.shell.extensions.auto-move-windows application-list "['telegramdesktop.desktop:9', 'discord.desktop:9', 'tor-browser.desktop:2', 'qbittorrent.desktop:10', 'code.desktop:4', 'virt-manager.desktop:7', 'obsidian.desktop:6', 'slack.desktop:9', 'gnome-terminal.desktop:3', 'anki.desktop:5']")
}

gnomeExtConfig() {

	#App Icons Task Bar
    if dconf write /org/gnome/shell/extensions/aztaskbar/main-panel-height '(true, 39)' \
        && dconf write /org/gnome/shell/extensions/aztaskbar/show-panel-activities-button false \
        && dconf write /org/gnome/shell/extensions/aztaskbar/icon-size 22 \
		&& dconf write /org/gnome/shell/extensions/aztaskbar/show-apps-button "(true, 0)" \
        && dconf write /org/gnome/shell/extensions/aztaskbar/indicator-color-focused "'rgb(236,94,94)'"; then
        printf "${BBlue} ⤅ ${Brown}App Icons Taskbar${Green} extension successfully configured.\n${NC}"
    else
        printf "${Red} ⤅ Failed to configure App Icons Taskbar.\n${NC}"
    fi

	#Vitals
	if dconf write /org/gnome/shell/extensions/vitals/hot-sensors "['_processor_usage_', '_system_load_1m_', '__temperature_avg__', '_memory_usage_', '_network-rx_enp5s0_rx_']"; then
        printf "${BBlue} ⤅ ${Brown}Vitals${Green} extension successfully configured.\n${NC}"
    else
        printf "${Red} ⤅ Failed to configure App Vitals.\n${NC}"
    fi

	#Just Perfection
	if dconf write /org/gnome/shell/extensions/just-perfection/activities-button false \
        && dconf write /org/gnome/shell/extensions/just-perfection/app-menu false \
        && dconf write /org/gnome/shell/extensions/just-perfection/workspaces-in-app-grid false; then
        printf "${BBlue} ⤅ ${Brown}Just Perfection${Green} extension successfully configured.\n${NC}"
    else
        printf "${Red} ⤅ Failed to configure Just Perfection.\n${NC}"
    fi

	#Space Bar
	if dconf write /org/gnome/shell/extensions/space-bar/behavior/position "'center'"; then
		printf "${BBlue} ⤅ ${Brown}Space Bar${Green} extension successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Failed to configure Space Bar.\n${NC}"
	fi

	#Rounded Window Corners
	if dconf write /org/gnome/shell/extensions/rounded-window-corners/skip-libadwaita-app false; then
		printf "${BBlue} ⤅ ${Brown}Rounded Window Corners${Green} extension successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Failed to configure Rounded Window Corners.\n${NC}"
	fi
}

# Update Gnome Shell to "Testing" repo 
gnomeTesting() {
	gnome_packages=("gnome-session" "mutter" "gjs" "gnome-shell")
	all_successful=true  # Control Variable

	for package in "${gnome_packages[@]}"; do
        if (confAptPref "$package" testing 1000); then
			printf "${BBlue} ⤅ ${Green}Successfully added ${Brown}$package${Green} as testing to APT Preferences.\n${NC}"
		else
			printf "${Red} ⤅ Failed to add $package as testing to APT Preferences\n${NC}"
			all_successful=false
		fi
    done 
	
	updateAPT

	if $all_successful; then
        return 0
    else
        return 1 
    fi
}

# 
Gnome_Extensions() {
	gnomeTesting
    if [ $? -eq 0 ]; then  # Verify return code from gnomeTesting
        export -f gnomeExtInstall
        gnomeExtInstall
		gnomeExtConfig
    else
        echo "Some packages failed to be added as testing. Aborting gnomeExtInstall."
    fi
}
#
## WhiteSur Theme ##
#------------------#
enableUserTheme() {
	if (gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com); then
		printf "${BBlue} ⤅ ${Green}Successfully enabled user-theme extension.\n${NC}"
	else
		printf "${Red} ⤅ Failed to enable user-theme extension.\n${NC}"
	fi
}
# Enable and Set to the left window buttons "Close,Mini,Max" 
windowButtons() {
	if (gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'); then
		printf "${BBlue} ⤅ ${Green}Window buttons successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Failed to configure window buttons.\n${NC}"
	fi
}
# WhiteSur Icons Theme
whiteSurIcons() {
	printf "${BBlue} ⤅ ${Blue}Downloading Breeze Round Icons.\n${NC}"
	if (git clone https://www.opencode.net/ju1464/Breeze_Round_Corners.git --depth=1 ~/Downloads/BreezeRound); then
		printf "${BBlue} ⤅ ${Green}Succesfully downloaded Breeze Round Icons Theme.\n${NC}"
		if (sudo mv ~/Downloads/BreezeRound/{Breeze_Dark_RC,Breeze_RC}/ /usr/share/icons) && (gsettings set org.gnome.desktop.interface icon-theme 'Breeze_RC');then
			sudo rm -r ~/Downloads/BreezeRound
			printf "${BBlue} ⤅ ${Green}Succesfully configured Breeze Round Icons Theme.\n${NC}"
		else
			printf "${Red} ⤅ Failed to configure Breeze Round Icon Theme.\n${NC}"
			sudo rm -r ~/Downlaods/BreezeRound
		fi
	else
		printf "${Red} ⤅ Failed to download Breeze Round Icon Theme.\n${NC}"
	fi
}
# Install and Configure WhiteSur Theme
WhiteSur_Theme() {
	windowButtons
	enableUserTheme
	printf "${BBlue} ⤅ ${Blue}Downloading WhiteSur Theme.\n${NC}"
	if (git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1 ~/Downloads/WhiteSur-gtk-theme); then
		printf "${BBlue} ⤅ ${Green}Succesfully downloaded WhiteSur Theme.\n${NC}"
		if (bash -c '~/Downloads/WhiteSur-gtk-theme/install.sh' \
		&& bash -c '~/Downloads/WhiteSur-gtk-theme/install.sh -l -c Light'); then
			printf "${BBlue} ⤅ ${Green}Succesfully installed WhiteSur Theme.\n${NC}"
			if (gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Light' \
			&& bash -c '~/Downloads/WhiteSur-gtk-theme/tweaks.sh -F' \
			&& sudo flatpak override --filesystem=xdg-config/gtk-4.0); then
				printf "${BBlue} ⤅ ${Green}Succesfully enabled WhiteSur Theme.\n${NC}"
				sudo rm -r ~/Downlaods/WhiteSur-gtk-theme
			else
				printf "${Red} ⤅ Failed to enable WhiteSur Theme.\n${NC}"
			fi
		else
			printf "${Red} ⤅ Failed to install WhiteSur Theme.\n${NC}"
		fi
	else
		printf "${Red} ⤅ Failed to download WhiteSur Theme.\n${NC}"
	fi
	whiteSurIcons
}
#
## Shell Theme ##
#------------------#
Shell_Theme() {
	enableUserTheme
	printf "${BBlue} ⤅ ${Blue}Downloading Marble Shell.\n${NC}"
	if (git clone https://github.com/imarkoff/Marble-shell-theme.git ~/Downloads/MarbleShell); then
		printf "${BBlue} ⤅ ${Green}Succesfully downloaded Marble Yellow Dark Shell Theme.\n${NC}"
		if (cd ~/Downloads/MarbleShell && python3 install.py --yellow); then
			printf "${BBlue} ⤅ ${Green}Succesfully installed Marble Yellow Dark Shell Theme.\n${NC}"
			if (bash -c "gsettings set org.gnome.shell.extensions.user-theme name 'Marble-yellow-dark'"); then
				printf "${BBlue} ⤅ ${Green}Succesfully configured Marble Yellow Dark Shell Theme.\n${NC}"
				sudo rm -r ~/Downloads/MarbleShell
			else
				printf "${Red} ⤅ Failed to configure Marble Yellow Dark Shell Theme.\n${NC}"
			fi
		else
			sudo rm -r ~/Downloads/MarbleShell
			printf "${Red} ⤅ Failed to install Marble Yellow Dark Shell Theme.\n${NC}"
		fi
	else
		printf "${Red} ⤅ Failed to download Marble Yellow Dark Shell Theme.\n${NC}"
	fi
}

## Wallpaper ##
#------------------#
Wallpaper() {
	printf "${BBlue} ⤅ ${Blue}Downloading Dynamic Wallpapers.\n${NC}"
	if (git clone https://github.com/saint-13/Linux_Dynamic_Wallpapers.git ~/Downloads/Linux_Dynamic_Wallpapers); then
		printf "${BBlue} ⤅ ${Green}Succesfully downloaded Dynamic Wallpapers.\n${NC}"
		if (sudo mkdir -p /usr/share/backgrounds/Dynamic_Wallpapers && sudo mkdir -p /usr/share/gnome-background-properties/) && (sudo mv ~/Downloads/Linux_Dynamic_Wallpapers/Dynamic_Wallpapers/* /usr/share/backgrounds/Dynamic_Wallpapers) && (sudo mv ~/Downloads/Linux_Dynamic_Wallpapers/xml/* /usr/share/gnome-background-properties/); then
			if (bash -c "gsettings set org.gnome.desktop.background picture-uri /usr/share/backgrounds/Dynamic_Wallpapers/BigSur.xml"); then
				printf "${BBlue} ⤅ ${Green}Succesfully configured Dynamic Wallpapers.\n${NC}"
				sudo rm -R ~/Downloads/Linux_Dynamic_Wallpapers
			else
				printf "${Red} ⤅ Failed to configure Dynamic Wallpapers.\n${NC}"
			fi
		else
			printf "${Red} ⤅ Failed to copy Dynamic Wallpapers to usr folders.\n${NC}"
		fi
	else
		printf "${Red} ⤅ Failed to dowload Dynamic Wallpapers.\n${NC}"
	fi
}

## Nerd Fonts ##
#------------------#
Nerd_Fonts() {
	if (cd ~/Downloads/ && curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz) && (
	cd ~/Downloads/ && curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Go-Mono.tar.xz); then
		printf "${BBlue} ⤅ ${Green}Successfully downloaded NerdFonts.\n${NC}"
		sudo mkdir -p /usr/share/fonts/{NerdFontsSymbolsOnly,Go-Mono}
		if (sudo tar -xf ~/Downloads/NerdFontsSymbolsOnly.tar.xz -C /usr/share/fonts/NerdFontsSymbolsOnly) && (
		sudo tar -xf ~/Downloads/Go-Mono.tar.xz -C /usr/share/fonts/Go-Mono) && (
		sudo chown -R root:root /usr/share/fonts/{NerdFontsSymbolsOnly,Go-Mono}) && (
		sudo chmod -R 655 /usr/share/fonts/{NerdFontsSymbolsOnly,Go-Mono}) && (
		sudo fc-cache); then
			cd ~/Downloads/
			rm -r NerdFontsSymbolsOnly.tar.xz Go-Mono.tar.xz
			printf "${BBlue} ⤅ ${Green}Successfully extracted NerdFonts.\n${NC}"
		else
			printf "${Red} ⤅ Failed to extract NerdFonts.\n${NC}"
		fi
	else
		printf "${Red} ⤅ Failed to download NerdFonts.\n${NC}"
	fi
}
#
## Other Configurations ##
#------------------#
# Unpin Apps from Icon Bar
unpinApp() {
	if gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop']"; then
		printf "${BBlue} ⤅ ${Green}Sucessfully redefined Icon Bar favorite apps.\n${NC}"
	else
		printf "${Red} ⤅ Fail to redefined Icon Bar favorite apps.\n${NC}"
	fi
}

# Night Shift 
nightShift() {
	if (bash -c "gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true") && (bash -c "gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2800"); then
		printf "${BBlue} ⤅ ${Green}Night Shift enabled.\n${NC}"
	else
		printf "${Red} ⤅ Fail to enable Nighe Shift.\n${NC}"
	fi
}
#
hotCorner() {
# Disable Hot Corner
	if gsettings set org.gnome.desktop.interface enable-hot-corners false; then
		printf "${BBlue} ⤅ ${Green}Hot Corner disabled.\n${NC}"
	else
		printf "${Red} ⤅ Fail to disable Hot Corner.\n${NC}"
	fi
}
# Configure WorkSpaces
workSpaces() {
	if (bash -c "gsettings set org.gnome.mutter dynamic-workspaces false"); then
		printf "${BBlue} ⤅ ${Green}Dynamic Workspaces desabled.\n${NC}"
		if (bash -c "gsettings set org.gnome.desktop.wm.preferences num-workspaces 10"); then
			printf "${BBlue} ⤅ ${Green}Workspaces sucessfully created.\n${NC}"
			if bash -c "gsettings set org.gnome.desktop.wm.preferences workspace-names \"['1', 'Web', 'Dev', 'Dev2', '5', 'Acad', 'Virt', 'Mail', 'Comms', '10']\""; then
				printf "${BBlue} ⤅ ${Green}Workspaces named sucessfully.\n${NC}"
			else
				printf "${Red} ⤅ Fail to name Workspaces.\n${NC}"
			fi
		else
			printf "${Red} ⤅ Fail to create Workspaces.\n${NC}"
		fi
	else
		printf "${Red} ⤅ Fail to desable Dynamic Workspaces.\n${NC}"
	fi
}
# Nautilus Configuration
nautilus() {
	# Enable Copy/Input Adress
	if (bash -c "gsettings set org.gnome.nautilus.preferences always-use-location-entry true"); then
		printf "${BBlue} ⤅ ${Green}File Manager Input Address successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Fail to configure File Manager Input Address.\n${NC}"
	fi

	# Adjust Folders/Files Icons Zoom
	if (bash -c "gsettings set org.gnome.nautilus.icon-view default-zoom-level small"); then
		printf "${BBlue} ⤅ ${Green}File Manager Icon Zoom successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Fail to configure File Manager Icon Zoom.\n${NC}"
	fi

	# Adjust Folders/Files Order
	if (bash -c "gsettings set org.gnome.nautilus.preferences default-sort-order type"); then
		printf "${BBlue} ⤅ ${Green}File Manager Sort Type successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Fail to configure File Manager Sort Type.\n${NC}"
	fi
	if (gsettings set org.gtk.Settings.FileChooser sort-directories-first true \
	&& gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true \
	&& dconf write /org/gtk/settings/file-chooser/sort-directories-first true); then
		printf "${BBlue} ⤅ ${Green}File Manager Sort Directories First successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Fail to configure File Manager Sort Directories First.\n${NC}"
	fi

	# Open as Root
	installAPT nautilus-admin

	# Show Folders/Files Size
	if gsettings set org.gnome.nautilus.icon-view captions "['size', 'none', 'none']"; then
		printf "${BBlue} ⤅ ${Green}File Manager Icon View Captions successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Fail to configure File Manager Icon View Captions.\n${NC}"
	fi

	# Nautilus Template Files
	templateFile() {
		for file in "$@"; do
			if (touch ~/Templates/"$file"); then
				printf "${BBlue} ⤅ ${Green}$file template file successfully created.\n${NC}"
			else
				printf "${Red} ⤅ Fail to create $file template file.\n${NC}"
			fi
		done
	}
	templateFile "Text Document.txt" "Word.docx" "Excel.xlsx" "PowerPoint.pptx"
}
# Gnome Terminal Configuration
gnomeTerminal() {
	# Change Profile Name
	profile_id=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')

	if (bash -c "gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile_id/ visible-name '$username'"); then
		printf "${BBlue} ⤅ ${Green}Gnome Terminal profile successfully renamed.\n${NC}"
	else
		printf "${Red} ⤅ Fail to rename Gnome Terminal Profile.\n${NC}"
	fi

	# Change Font
	if dconf write /org/gnome/terminal/legacy/profiles:/:$profile_id/font "'GoMono Nerd Font Mono 12'"; then
		printf "${BBlue} ⤅ ${Green}Gnome Terminal Font successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Fail to configure Gnome Terminal Font.\n${NC}"
	fi

	# Change Theme
	solarizedLight() {
		dconf write /org/gnome/terminal/legacy/profiles:/:$profile_id/palette "['rgb(23,20,33)', 'rgb(192,28,40)', 'rgb(38,162,105)', 'rgb(162,115,76)', 'rgb(18,72,139)', 'rgb(163,71,186)', 'rgb(42,161,179)', 'rgb(208,207,204)', 'rgb(94,92,100)', 'rgb(246,97,81)', 'rgb(51,209,122)', 'rgb(233,173,12)', 'rgb(42,123,222)', 'rgb(192,97,203)', 'rgb(51,199,222)', 'rgb(255,255,255)']"
		dconf write /org/gnome/terminal/legacy/profiles:/:$profile_id/background-color "'#fdf6e3'"
		dconf write /org/gnome/terminal/legacy/profiles:/:$profile_id/foreground-color "'#657b83'"
		dconf write /org/gnome/terminal/legacy/profiles:/:$profile_id/bold-color "'#586e75'"
		dconf write /org/gnome/terminal/legacy/profiles:/:$profile_id/bold-color-same-as-fg true
	}
	if dconf write /org/gnome/terminal/legacy/profiles:/:$profile_id/use-theme-colors false && solarizedLight; then
		printf "${BBlue} ⤅ ${Green}Gnome Terminal Solarized Theme successfully configured.\n${NC}"
	else
		printf "${Red} ⤅ Fail to configure Solarized Theme for Terminal.\n${NC}"
	fi
}

# Other Confs Call
Other_Confs() {
	unpinApp
	nightShift
	hotCorner
	workSpaces
	nautilus
	gnomeTerminal
}

## Starship ##
#------------------#
installStarShip() {
	if (cd /home/$username && curl -sS https://starship.rs/install.sh | sh); then
		printf "${BBlue} ⤅ ${Green}Successfully installed Starship.\n${NC}"
	else
		printf "${Red} ⤅ Failed to install Starship.\n${NC}"
	fi
}
bashrcStarShip() {
	if grep -q "StarShip" ~/.bashrc; then
		printf "${BBlue} ⤅ ${Blue}Starship already configured in .bashrc file.\n${NC}"
	else
		if (echo -e '\n#StarShip\neval "$(starship init bash)"' >> ~/.bashrc); then
			cd /home/$username && source .bashrc
			printf "${BBlue} ⤅ ${Green}Successfully configured Starship in .bashrc file.\n${NC}"
		else
			printf "${Red} ⤅ Failed to configure Starship in .bashrc file.\n${NC}"
		fi
	fi
}
tomStarShip() {
	if (cp "./Conf_Files/starship.toml" ~/.config/); then
		sudo chown -R $username:$username ~/.config/
		printf "${BBlue} ⤅ ${Green}Successfully configured Starship TOML.\n${NC}"
	else
		printf "${Red} ⤅ Failed to configure Starship TOML.\n${NC}"
	fi
}
Starship() {
	installStarShip
	bashrcStarShip
	tomStarShip
}

## Eza ##
#------------------#
EZAconf() {
	alias_1="alias ls='\\ls'"
	alias_2="alias ls='eza --icons --group-directories-first'"
	alias_3="alias \\eza='eza'"

	if sed -i "/#alias l='ls -CF'/a $alias_1\n$alias_2\n$alias_3" ~/.bashrc; then
		source ~/.bashrc
		printf "${BBlue} ⤅ ${Green}Successfully configured EZA alias.\n${NC}"
	else
		printf "${Red} ⤅ Failed to configure EZA alias.\n${NC}"
	fi
}

EZA() {
	sudo mkdir -p /etc/apt/keyrings
	wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
	echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
	sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
	updateAPT
	installAPT eza
	EZAconf
}

## FastFetch ##
#------------------#
Neofetch() {
	if installAPT neofetch; then
		if grep -q "neofetch" "/home/$username/.bashrc"; then
			printf "${BBlue} ⤅ ${Brown}Neofetch ${Green}already configured.\n${NC}"
		else
			if echo -e '\n#NeoFetch\nneofetch' >> /home/$username/.bashrc; then
				printf "${BBlue} ⤅ ${Green}Successfully configured ${Brown}Neofetch.\n${NC}"
			else
				printf "${Red} ⤅ Failed to configure Neofetch.\n${NC}"
			fi
		fi
	fi
}

## GRUB Config ##
#------------------#
#GRUB_Config() {

#}






