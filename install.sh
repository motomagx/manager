#!/bin/bash

# https://github.com/JaKooLit

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be executed as root! Exiting......."
    exit 1
fi

# Check if SDDM is installed:
SDDM=$(apt list --installed | grep sddm | wc -l)

clear

# Welcome message
echo "$(tput setaf 6)Welcome to JaKooLit's Debian / Ubuntu Hyprland Install Script!$(tput sgr0)"
echo
echo "$(tput setaf 166)ATTENTION: Run a full system update and Reboot first!! (Highly Recommended) $(tput sgr0)"
echo
echo "$(tput setaf 3)NOTE: You will be required to answer some questions during the installation! $(tput sgr0)"
echo

read -p "$(tput setaf 6)Would you like to proceed? (y/n): $(tput sgr0)" proceed

if [ "$proceed" != "y" ]; then
    echo "Installation aborted."
    exit 1
fi

read -p "$(tput setaf 6)Have you edited your /etc/apt/sources.list? (y/n): $(tput sgr0)" proceed2

if [ "$proceed2" != "y" ]; then
    echo "Installation aborted. Kindly edit your sources.list first. Refer to readme."
    exit 1
fi

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
WARN="$(tput setaf 166)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
ORANGE=$(tput setaf 166)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# Function to colorize prompts
colorize_prompt() {
    local color="$1"
    local message="$2"
    echo -n "${color}${message}$(tput sgr0)"
}

# Set the name of the log file to include the current date and time
LOG="install-$(date +%d-%H%M%S).log"

# Initialize variables to store user responses
bluetooth=""
dots=""
gtk_themes=""
nvidia=""
nwg=""
rog=""
sddm=""
swaylock=""
swww=""
thunar=""
xdph=""
zsh=""

# Define the directory where your scripts are located
script_directory=install-scripts

# Function to ask a yes/no question and set the response in a variable
ask_yes_no() {
    while true; do
        read -p "$(colorize_prompt "$CAT"  " $1 (y/n): ")" choice
        case "$choice" in
            [Yy]* ) eval "$2='Y'"; return 0;;
            [Nn]* ) eval "$2='N'"; return 1;;
            * ) echo "Please answer with y or n.";;
        esac
    done
}

# Function to ask a custom question with specific options and set the response in a variable
ask_custom_option() {
    local prompt="$1"
    local valid_options="$2"
    local response_var="$3"

    while true; do
        read -p "$(colorize_prompt "$CAT"  "$prompt ($valid_options): ")" choice
        if [[ " $valid_options " == *" $choice "* ]]; then
            eval "$response_var='$choice'"
            return 0
        else
            echo "Please choose one of the provided options: $valid_options"
        fi
    done
}
# Function to execute a script if it exists and make it executable
execute_script() {
    local script="$1"
    local script_path="$script_directory/$script"
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        if [ -x "$script_path" ]; then
            "$script_path"
        else
            echo "Failed to make script '$script' executable."
        fi
    else
        echo "Script '$script' not found in '$script_directory'."
    fi
}


# Experimental patch - need to check if it works in MATROX card with Nvidia chips:
CHECK_NVIDIA=$(lspci | grep -i vga | grep -i nvidia  | wc -l)

if [ $CHECK_NVIDIA != 0 ]; then
    echo -e "\n${NOTE} Detected one or more NVIDIA/MATROX compatible card."
    nvidia=Y
else
    nvidia=N
fi

# Collect user responses to all questions
printf "\n"
ask_yes_no "Do you want to install GTK themes?" gtk_themes
printf "\n"
ask_yes_no "Do you want to configure Bluetooth?" bluetooth
printf "\n"
ask_yes_no "Do you want to install Thunar file manager?" thunar
printf "\n"
ask_yes_no "Installing in Asus ROG Laptops?" rog
printf "\n"
ask_yes_no "Do you want to install and configure SDDM?" sddm
printf "\n"
ask_yes_no "Do you want to install xdg-desktop-portal-hyprland?" xdph
printf "\n"
ask_yes_no "Do you want to install zsh and oh-my-zsh?" zsh
printf "\n"
ask_yes_no "Do you want to install swaylock-effects?" swaylock
printf "\n"
ask_yes_no "Do you want to install swww?" swww
printf "\n"
ask_yes_no "Do you want to install nwg-look?" nwg
printf "\n"
ask_yes_no "Do you want to copy dotfiles?" dots
printf "\n"
# Ensuring all in the scripts folder are made executable
chmod +x install-scripts/*

sudo apt update # will not work if user isnt in /etc/sudoers file by default.

# Run apt and update/install drivers for ubuntu users, so, ya dont need to edit nvidia.sh:
if [ "$?" == 0 ]; then
    echo "${ERROR} 'apt update' had a problem. Check if user $USER is configured in your /etc/sudoers file."
else
    UBUNTU=$(cat os-release | grep debian -i | wc -l)

    # Install nvidia drivers:
    if [ "$nvidia" == "Y" ]; then
        if [ $UBUNTU != 0 ]; then
            # Ubuntu users:
            ubuntu-drivers autoinstall
        else
            # Debian:
            apt install linux-headers-amd64 nvidia-driver firmware-misc-nonfree
        fi
    fi
fi

# Install hyprland packages
execute_script "00-dependencies.sh"
execute_script "00-hypr-pkgs.sh"
execute_script "fonts.sh"
execute_script "swappy.sh"

if [ "$nvidia" == "Y" ]; then
    execute_script "nvidia.sh"
fi

if [ "$nvidia" == "N" ]; then
    execute_script "hyprland.sh"
fi

if [ "$gtk_themes" == "Y" ]; then
    execute_script "gtk_themes.sh"
fi

if [ "$bluetooth" == "Y" ]; then
    execute_script "bluetooth.sh"
fi

if [ "$thunar" == "Y" ]; then
    execute_script "thunar.sh"
fi

if [ "$rog" == "Y" ]; then
    execute_script "rog.sh"
fi

if [ "$sddm" == "Y" ]; then
    execute_script "sddm.sh"
fi

if [ "$xdph" == "Y" ]; then
    execute_script "xdph.sh"
fi

if [ "$zsh" == "Y" ]; then
    execute_script "zsh.sh"
fi

if [ "$swaylock" == "Y" ]; then
    execute_script "swaylock-effects.sh"
fi

if [ "$swww" == "Y" ]; then
    execute_script "swww.sh"
fi

if [ "$nwg" == "Y" ]; then
    execute_script "nwg-look.sh"
fi

if [ "$dots" == "Y" ]; then
    execute_script "dotfiles.sh"

fi

clear

printf "\n${OK} Yey! Installation Completed.\n"
printf "\n"
printf "\n${NOTE} NOTICE TO NVIDIA OWNERS! System will reboot your system!\n"
sleep 2
printf "\n${NOTE} You can start Hyprland by typing Hyprland (IF SDDM is not installed) (note the capital H!).\n"
printf "\n"
printf "\n"
read -n1 -rep "${CAT} Would you like to start Hyprland now? (y,n)" HYP

if [[ $HYP =~ ^[Yy]$ ]]; then
    if [[ "$nvidia" == "Y" ]]; then
        echo "${NOTE} NVIDIA GPU detected. Rebooting the system..."
        systemctl reboot
    elif command -v sddm >/dev/null; then
        sudo systemctl restart sddm 2>&1 | tee -a "$LOG"
    else
        if command -v Hyprland >/dev/null; then
            exec Hyprland
        else
            echo "${ERROR} Hyprland not found. Please make sure Hyprland is installed by checking install logs"
        fi
    fi    
fi

