#!/bin/bash

# Colors for better readability
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

# Function to display colored messages
print_message() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${ENDCOLOR}"
}

# Detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PACKAGER="apt-get"
        PACKAGER_INSTALL="sudo apt-get install -y"
        PACKAGER_UPDATE="sudo apt-get update && sudo apt-get upgrade -y"
    elif command -v dnf &> /dev/null; then
        PACKAGER="dnf"
        PACKAGER_INSTALL="sudo dnf install -y"
        PACKAGER_UPDATE="sudo dnf upgrade -y"
    elif command -v pacman &> /dev/null; then
        PACKAGER="pacman"
        PACKAGER_INSTALL="sudo pacman -S --noconfirm"
        PACKAGER_UPDATE="sudo pacman -Syu"
    elif command -v zypper &> /dev/null; then
        PACKAGER="zypper"
        PACKAGER_INSTALL="sudo zypper install -y"
        PACKAGER_UPDATE="sudo zypper update -y"
    else
        whiptail --title "Error" --msgbox "Error: Unsupported package manager. Please install packages manually." 8 78
        exit 1
    fi
}

# Check and install Git
check_and_install_git() {
    if ! command -v git &> /dev/null; then
        print_message "Git is not installed. Installing Git..." "$YELLOW"
        $PACKAGER_INSTALL git
        if command -v git &> /dev/null; then
            print_message "Git has been successfully installed." "$GREEN"
        else
            whiptail --title "Error" --msgbox "Failed to install Git. Please install it manually and run this script again." 8 78
            exit 1
        fi
    else
        print_message "Git is already installed." "$GREEN"
    fi
}

# setup linuxtoolbox
setup_linuxtoolbox() {
    check_and_install_git

    LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

    if [ ! -d "$LINUXTOOLBOXDIR" ]; then
        print_message "Creating linuxtoolbox directory: $LINUXTOOLBOXDIR" "$YELLOW"
        mkdir -p "$LINUXTOOLBOXDIR"
        print_message "linuxtoolbox directory created: $LINUXTOOLBOXDIR" "$GREEN"
    fi

    if [ ! -d "$LINUXTOOLBOXDIR/mybash" ]; then
        print_message "Cloning mybash repository into: $LINUXTOOLBOXDIR/mybash" "$YELLOW"
        if git clone https://github.com/odiak0/mybash "$LINUXTOOLBOXDIR/mybash"; then
            print_message "Successfully cloned mybash repository" "$GREEN"
        else
            whiptail --title "Error" --msgbox "Failed to clone mybash repository" 8 78
            exit 1
        fi
    fi

    cd "$LINUXTOOLBOXDIR/mybash" || exit
}

# Set up AUR helper (only for Arch-based systems)
setup_aur_helper() {
    if [ "$PACKAGER" != "pacman" ]; then
        return
    fi

    # Ask user to choose between paru and yay using whiptail
    if ! helper=$(whiptail --title "AUR Helper Selection" --menu "Choose your preferred AUR helper:" 15 60 2 \
    "paru" "Rust-based AUR helper" \
    "yay" "Go-based AUR helper" 3>&1 1>&2 2>&3); then
        print_message "AUR helper selection cancelled. Exiting." "$YELLOW"
        exit 1
    fi

    # Install chosen AUR helper if not present
    if ! command -v "$helper" &> /dev/null; then
        print_message "Installing $helper..." "$YELLOW"
        cd || exit
        git clone "https://aur.archlinux.org/$helper.git"
        cd "$helper" || exit
        makepkg -si --noconfirm --needed
        cd .. && rm -rf "$helper"
    fi
}

# Install dependencies
install_dependencies() {
    print_message "Installing dependencies..." "$YELLOW"
    
    case $PACKAGER in
        "apt-get")
            if ! $PACKAGER_INSTALL bash tar wget unzip fastfetch batcat tree zoxide starship; then
                whiptail --title "Error" --msgbox "Failed to install dependencies." 8 78
                exit 1
            fi
            ;;
        "dnf")
            if ! $PACKAGER_INSTALL bash tar bat fastfetch wget unzip tree zoxide starship; then
                whiptail --title "Error" --msgbox "Failed to install dependencies." 8 78
                exit 1
            fi
            ;;
        "pacman")
            if ! $PACKAGER_INSTALL bash tar bat fastfetch wget unzip tree starship zoxide; then
                whiptail --title "Error" --msgbox "Failed to install dependencies." 8 78
                exit 1
            fi
            ;;
        "zypper")
            if ! $PACKAGER_INSTALL bash tar bat fastfetch wget unzip tree zoxide starship; then
                whiptail --title "Error" --msgbox "Failed to install dependencies." 8 78
                exit 1
            fi
            ;;
        *)
            whiptail --title "Error" --msgbox "Unsupported package manager." 8 78
            exit 1
            ;;
    esac
    
    print_message "Dependencies installed successfully!" "$GREEN"
}

main() {
    detect_package_manager
    setup_linuxtoolbox
    setup_aur_helper
    install_dependencies

    print_message "Updating system..." "$YELLOW"
    $PACKAGER_UPDATE
    whiptail --title "Installation Complete" --msgbox "Installation completed." 8 78
}

main