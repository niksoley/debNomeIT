#!/bin/bash
#
#------------------------------------------------------------------------------------------------#
####################  Development  #################
#------------------------------------------------------------------------------------------------#
#
## GitHub CLI ##
#------------------------#
GitHub_CLI() {
    installAPT gh
}

## VSCode ##
#------------------------#
VSCode() {
    installFlat flathub com.visualstudio.code
}

## Docker ##
#------------------------#
Docker() {
    # Verify if docker is installed
    if dpkg -l |grep -q docker-ce; then
        printf "${BBlue} ⤅ ${Brown}Docker${Green} already installed.\n${NC}"
        return 1
    fi

    # Remove old packages to avoid conflict
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done 

    # Add Docker's official GPG key:
    installAPT ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker Packages
    installAPT docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
}

## PodMan ##
#------------------------#
PodMan() {
    installAPT podman
}

## QEMU KVM ##
#------------------------#
QEMU_KVM() {
    installAPT qemu-utils qemu-system-x86 qemu-system-gui virt-manager libguestfs-tools dmg2img
    sudo usermod -aG kvm $username
    sudo usermod -aG libvirt $username
    sudo usermod -aG input $username
}