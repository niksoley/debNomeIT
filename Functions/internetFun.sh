#!/bin/bash
#
#------------------------------------------------------------------------------------------------#
####################  Internet  #################
#------------------------------------------------------------------------------------------------#
#
## Firefox ##
#------------------------#
# Remove pre installed Firefox-esr
remFireESR() {
    if sudo apt purge -y firefox-esr; then
        printf "${BBlue} ⤅ ${Green}Successfully removed pre-installed ${Brown}Firefox-ESR${Green}.\n${NC}"
    else
        printf "${Red} ⤅ Failed to remove pre-installed Firefox ESR.\n${NC}"
    fi
}

# Creates Firefox profile 
createFireProfiles() {
    for profile_name in "$@"; do
        profile_root=""
        profile_root=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*$profile_name")
        if [ -n "$profile_root" ]; then
            printf "${BBlue} ⤅ ${Brown}${profile_name}${Green} profile already exists.\n${NC}"
        else
            flatpak run org.mozilla.firefox -CreateProfile "$profile_name"
            if [ $? -eq 0 ]; then
                printf "${BBlue} ⤅ ${Brown}${profile_name}${Green} profile created successfully.\n${NC}"
            else
                printf "${Red} ⤅ Failed to create profile ${profile_name}.\n${NC}"
            fi
        fi
    done


    # profile_name=""
    # profile_name=$1
    # if [ -z profile_name ]; then
    #     return 1
    # fi

    # # Path to the Firefox binary installed via Flatpak
    # firefox_bin="flatpak run org.mozilla.firefox"

    # # Check if the profile already exists
    # profile_root=""
    # profile_root=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*$profile_name")
    # if [ -n "$profile_root" ]; then
    #     printf "${BBlue} ⤅ ${Brown}${profile_name}${Green} profile already exists.\n${NC}"
    # else
    #     # Create a new profile
    #     $firefox_bin -CreateProfile "$profile_name"
    #     sleep 2
    #     profile_root=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*$profile_name")
        
    #     if [ -z "$profile_root" ]; then
    #         printf "${Red} ⤅ Failed to create the new profile.\n${NC}"
    #         return 1
    #     else
    #         printf "${BBlue} ⤅ ${Brown}${profile_name}${Green} profile successfully created.\n${NC}"
    #     fi
    # fi
}

# Defines a profile as default
fireProfileDefault() {
    # Check if the profile is already the default
    profile_name=""
    profile_name=$1
    current_default=""
    current_default=$(grep -A 4 "\[Profile[0-9]*\]" ~/.mozilla/firefox/profiles.ini | grep -B 4 "Default=1" | grep "Name=$profile_name")

    if [ -z "$current_default" ]; then
        # Profile is not the default, proceed to set it as default
        sed -i '/^Default=1$/d' ~/.mozilla/firefox/profiles.ini
        profile_root=""
        profile_root=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*$profile_name")
        echo -e "[Profile1]\nName=$profile_name\nIsRelative=1\nPath=$(basename $profile_root)\nDefault=1" >> ~/.mozilla/firefox/profiles.ini
        
        if [ $? -eq 0 ]; then
            printf "${BBlue} ⤅ ${Brown}${profile_name} profile${Green} set as default.\n${NC}"
        else
            printf "${Red} ⤅ Failed to set ${profile_name} profile as default.\n${NC}"
        fi
    else
        printf "${BBlue} ⤅ ${Brown}${profile_name}${Green} profile is already set as default.\n${NC}"
    fi
}

# Automate user.js overrides
userOverride() {
    if sudo sed -i "/Enter your personal overrides below this line:/a $1" ~/Downloads/Betterfox/user.js; then
        printf "${BBlue} ⤅ ${Green}Successfully configured ${Brown}$2${Green}.\n${NC}"
    else
        printf "${Red} ⤅ Failed to configure $2.\n${NC}"
    fi
}

# Install & Configure Betterfox
hardFire() {
    # Download user.js
    sudo rm -R ~/Downloads/FireExt/

    if git clone $2 --depth=1 ~/Downloads/FireExt; then
        printf "${BBlue} ⤅ ${Green}Successfully downloaded ${Brown}Betterfox${Green}.\n${NC}"
    else
        printf "${Red} ⤅ Failed to download Betterfox.\n${NC}"
        return 1
    fi

    # Configure user.js
    if [ "$1" = "betterfox" ]; then
        if userOverride 'user_pref("browser.newtabpage.activity-stream.feeds.topsites", true);' "Shortcuts" \
        && userOverride 'user_pref("browser.search.suggest.enabled", true);' "Search Suggestion" \
        && userOverride 'user_pref("permissions.default.geo", 0);' "Geolocation"; then
            printf "${BBlue} ⤅ ${Green}Successfully configured ${Brown}Betterfox${Green} overrides.\n${NC}"
        else
            printf "${Red} ⤅ Failed to configure Betterfox overrides.\n${NC}"
            return 1
        fi
    fi

    # Move Betterfox user.js to the profile directory
    profile_root=""
    profile_root=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*$profile_name")
    if sudo mv ~/Downloads/FireExt/user.js "$profile_root/"; then
        printf "${BBlue} ⤅ ${Green}Successfully installed ${Brown}Betterfox${Green}.\n${NC}"
        sudo rm -R ~/Downloads/FireExt/
    else
        printf "${Red} ⤅ Failed to install Betterfox.\n${NC}"
    fi
}

# Install Firefox Extension
fireExtInst() {
    extension_url=$1
    profile_name=$3
    profile_root=""
    profile_root=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*$profile_name")

    # Check if profile exist
    if [ -z "$profile_root" ]; then
        printf "${Red} ⤅ Failed to find ${profile_name}.\n${NC}"
        return 1
    fi

    # Download the XPI file for the extension
    mkdir -p ~/Downloads/FireExt/
    if wget -O ~/Downloads/FireExt/addon.xpi "$extension_url"; then
        printf "${BBlue} ⤅ ${Green}Successfully downloaded extension ${Brown}$2.\n${NC}"
    else
        printf "${Red} ⤅ Failed to download $2 extension.\n${NC}"
        return 1
    fi
    
    # get extension UID from manifest.json
    ADDON_ID=""
    ADDON_ID=$(unzip -p ~/Downloads/FireExt/addon.xpi manifest.json | grep -Po '"id": "\K[^"]*')
    if [ -f ADDON_ID ]; then
        printf "${Red} ⤅ Failed to extract $2 id from json.\n${NC}"
        return 1
    else
        printf "${BBlue} ⤅ ${Green}Successfully extracted ${Brown}$2${Green} extension json ID.\n${NC}"
    fi
    
    # Rename addon.xpi
    if sudo mv ~/Downloads/FireExt/addon.xpi ~/Downloads/FireExt/${ADDON_ID}.xpi; then
        printf "${BBlue} ⤅ ${Green}Successfully renamed extension ${Brown}$2 to ${ADDON_ID}.xpi.\n${NC}"
    else
        printf "${Red} ⤅ Failed to rename $2 extension.\n${NC}"
        return 1
    fi

    # Ensure the extensions directory exists
    sudo mkdir "$profile_root/extensions/"
    if [ ! -d "$profile_root/extensions/" ]; then
        printf "${Red} ⤅ Firefox extensions folder not found.\n${NC}"
        return 1
    fi

    # Copy the XPI file to the Firefox profile's extensions folder
    if sudo cp ~/Downloads/FireExt/${ADDON_ID}.xpi "$profile_root/extensions/"; then
        sudo chmod 777 "$profile_root/extensions/${ADDON_ID}.xpi"
        printf "${BBlue} ⤅ ${Green}Successfully copied ${Brown}$2${Green} in the betterfox profile.\n${NC}"
    else
        printf "${Red} ⤅ Failed to copy $2 extension.\n${NC}"
    fi
    
    sudo rm -R ~/Downloads/FireExt/
}

# Main function to set up hardened Firefox
Hardened_Firefox() {
    remFireESR
    installFlat flathub org.mozilla.firefox
    createFireProfiles betterfox
    fireProfileDefault betterfox
    hardFire betterfox "https://github.com/yokoffing/Betterfox.git"
    fireExtInst "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/addon-607454-latest.xpi" uBlock betterfox
    autoMoveWindows org.mozilla.firefox.desktop 2
}

## Chromium ##
#------------------------#
Chromium() {
    installFlat flathub org.chromium.Chromium
}

## Tor ##
#------------------------#
Tor() {
    installFlat flathub org.torproject.torbrowser-launcher
}

## Local piHole ##
#------------------------#
createDockerpiHole() {
    # Delete old pihole container and network
    sudo docker stop pihole && sudo docker rm pihole
    sudo docker network rm mynet
    
    # Create piHole docker network
    if sudo docker network create \
    --subnet=172.16.0.0/16 \
    --gateway=172.16.0.1 \
    mynet; then
        printf "${BBlue} ⤅ ${Green}Successfully created Docker network 'mynet'.\n${NC}"
    else
        printf "${Red} ⤅ Failed to create Docker network 'mynet'.\n${NC}"
        return 1
    fi

    # Create piHole container
    dest_dir="/srv/Containers/piHole/"
    sudo mkdir -p "$dest_dir"

    if sudo docker run -d --name pihole \
    --network mynet \
    --ip 172.16.0.10 \
    -p 1053:53/tcp \
    -p 1053:53/udp \
    -p 1067:67/udp \
    -p 1080:80/tcp \
    -e TZ='America/Sao_Paulo' \
    -e WEBPASSWORD='1234' \
    -v /srv/Containers/piHole/etc-pihole:/etc/pihole \
    -v /srv/Containers/piHole/etc-dnsmasq.d:/etc/dnsmasq.d \
    --dns=8.8.8.8 \
    --cap-add NET_ADMIN \
    --restart unless-stopped \
    pihole/pihole:latest; then
        printf "${BBlue} ⤅ ${Green}Successfully started ${Brown}piHole container.\n${NC}"
    else
        printf "${Red} ⤅ Failed to start ${Brown}piHole${Red} container.\n${NC}"
        return 1
    fi
}

piHoleDNSConf() {
    # Define the target subnet
    target_subnet="172.16.0.1/16"
    target_ip="172.16.0.10"

    # Get name of main connection
    main_connection=$(nmcli -t -f NAME connection show --active | head -n 1)

    # Get a list of all connections
    connections=$(nmcli -t -f NAME connection show)
    piHole_connection=""

    # Iterate over each connection and check its IP configuration
    echo "$connections"
    for conn in $connections; do
        # Get the IP configuration for the current connection
        ip_config=$(nmcli -g ipv4.addresses connection show "$conn")
        echo "Looking for IP $target_subnet in connection $ip_config"
        # Check if the IP configuration contains the target subnet
        if echo "$ip_config" | grep -q "$target_subnet"; then
            piHole_connection="$conn"
            echo "Connection name with IP $target_subnet is $piHole_connection"
            break
        fi
    done

    if [ -z "$piHole_connection" ]; then
        printf "${Red} ⤅ Failed to find connection with subnet $target_subnet.\n${NC}"
        return 1
    fi

    # Define primary DNS for piHole and second for main connection (DHCP server)
    if sudo nmcli connection modify "$main_connection" ipv4.ignore-auto-dns no && \
    sudo nmcli connection modify "$main_connection" ipv4.dns-priority 10 && \
    sudo nmcli connection modify "$piHole_connection" ipv4.dns "$target_ip" && \
    sudo nmcli connection modify "$piHole_connection" ipv4.dns-priority 1 && \
    sudo nmcli connection modify "$piHole_connection" ipv4.ignore-auto-dns yes; then
        printf "${BBlue} ⤅ ${Green}Successfully modified DNS settings.\n${NC}"
    else
        printf "${Red} ⤅ Failed to modify DNS settings.\n${NC}"
        return 1
    fi
    
    # Restart the connections
    if sudo nmcli connection down "$main_connection" && sudo nmcli connection up "$main_connection" && \
    sudo nmcli connection down "$piHole_connection" && sudo nmcli connection up "$piHole_connection" && \
    sudo docker restart pihole; then
        printf "${BBlue} ⤅ ${Green}Successfully restarted network connections.\n${NC}"
    else
        printf "${Red} ⤅ Failed to restart network connections.\n${NC}"
        return 1
    fi

    test_connection() {
        if sudo docker exec pihole ping -c 4 8.8.8.8; then
            printf "${BBlue} ⤅ ${Green}Successfully pinged from piHole, connection established.\n${NC}"
            return 0
        else
            printf "${Red} ⤅ Failed to establish connection with piHole.\n${NC}"
            return 1
        fi
    }

    if ! test_connection; then
        sudo ip route add 172.16.0.0/16 via 172.17.0.1
        printf "${BBlue} ⤅ ${Blue}Configuring IP Route Table.\n${NC}"
        sudo docker restart pihole
    fi

    if ! test_connection; then
        sudo iptables -t nat -A POSTROUTING -s 172.16.0.0/16 ! -o docker0 -j MASQUERADE
        sudo docker restart pihole
    fi

}

Local_piHole() {
    Docker
    if createDockerpiHole; then
        piHoleDNSConf
    fi
}


