#!/usr/bin/env -S bash -e
# Cosmetics (colours for text).
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print (function).
info_print () {
    echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
}

# Pretty print no newline (function).
info_print_clean () {
    echo -e "${BOLD}${BGREEN} $1${RESET}"
}

# Pretty print for input (function).
input_print () {
    echo -ne "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
}

# Alert user of bad input (function).
error_print () {
    echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

info_print "Starting TheRealArch Desktop Installation"
info_print "Installing 'xf86-video-intel' 'mesa' and 'vulkan-intel' Video drivers.."
pacstrap /mnt xf86-video-intel mesa vulkan-intel &>/dev/null


info_print "Installing 'xorg' and 'i3-wm' as desktop enviroment.."
pacstrap /mnt i3-wm py3status i3status xorg-server xorg-xauth &>/dev/null

# Install file manager and addons
#   thunar-volman - removable drives and media management
#            gvfs - Trash support etc..
#
info_print "Installing 'thunar' and 'gvfs' as filemanager.."
pacstrap /mnt thunar thunar-volman gvfs &>/dev/null


info_print "Installing 'rofi' as App launcher.."
pacstrap /mnt rofi &>/dev/null

info_print "Installing 'ly' as Display Manager.."
pacstrap /mnt ly &>/dev/null

info_print "Installing 'cool-retro-term' as terminal emulator"
pacstrap /mnt cool-retro-term &>/dev/null

info_print "Installing 'keepassxc' password manager"
pacstrap /mnt keepassxc &>/dev/null

info_print "Installing 'pipewire' for alsa and pulse.."
pacstrap /mnt pipewire-{jack,alsa,pulse} &>/dev/null

info_print "Installing 'speedcrunch' calculator.."
pacstrap /mnt speedcrunch &>/dev/nul

info_print "Installing 'YADM' config management.."
pacstrap /mnt yadm tree &>/dev/null

info_print "Configuing system wide 'ly' Display Manager.."
echo "animate = true" > /mnt/etc/ly/config.ini # Enable lock screen animation
echo "animation = 1" > /mnt/etc/ly/config.ini # Select Matrix like live wallpaper

info_print "Customizing install with 'yay' 'brave' 'brillo' and 'dotfiles' repo"
arch-chroot /mnt /bin/bash -e <<EOF

         # Install yay in arch-chroot
         mkdir -p /home/""$username""/tmp
         cd /home/""$username""/tmp
         git clone https://aur.archlinux.org/yay-bin.git
         chown -R kani:kani /home/""$username""
         cd yay-bin
         sudo -u ""$username"" bash -c 'makepkg -si --noconfirm'

         # Yay Install brave
         yay -S --noconfirm brave-bin

         # Yay install brillo
         yay -S --noconfirm brillo

         #cd .. # Back to tmp
         # TODO - Clone dorfiles repo - Apply config later!
         #yadm clone https://github.com/TheRealKANi/dotfiles

EOF

# Enable Desktop Services
info_print "Starting Global Services: ly-dm.."
services=(ly)
for service in "${services[@]}"; do
    systemctl enable "$service" --root=/mnt &>/dev/null
done

info_print "Starting User Services: pipewire.."
services=(pipewire pipewire-pulse wireplumber)
for service in "${services[@]}"; do
    systemctl --user enable "$service" --root=/mnt &>/dev/null
done
