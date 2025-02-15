#!/bin/bash

set -e

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS."
    exit 1
fi

# Function for Debian-based systems (Ubuntu, Pop!_OS, Debian, Linux Mint)
install_debian() {
    sudo apt update
    sudo apt install -y curl
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y lsd fzf bat gh git python3 python3-pip
    # Create bat symlink
    sudo ln -sf "$(which batcat)" /usr/local/bin/bat
}

# Function for Arch-based systems (Arch Linux, Manjaro)
install_arch() {
    sudo pacman -Sy --noconfirm lsd fzf bat github-cli git python python-pip
}

# Function for Fedora
install_fedora() {
    sudo dnf install -y epel-release
    sudo dnf install -y dnf-plugins-core curl
    sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo dnf install -y lsd fzf bat gh git python3 python3-pip
}

# Execute installation based on OS
case $OS in
    ubuntu|pop|debian|linuxmint)
        install_debian ;;
    arch|manjaro)
        install_arch ;;
    fedora)
        install_fedora ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1 ;;
esac

# Install GitHub CLI extension
gh extension install mislav/gh-repo-collab --force

# Install GitPython
pip3 install --user gitpython

echo "Installation completed successfully!"