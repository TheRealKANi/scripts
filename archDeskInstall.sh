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
# Run With
# bash <(curl -L https://raw.githubusercontent.com/TheRealKANi/scripts/main/archDeskInstall.sh)
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

info_print "Installing 'pipewire' audio system"
pacstrap /mnt pipewire-{jack,alsa,pulse} pavucontrol wireplumber &>/dev/null

info_print "Installing 'speedcrunch' calculator.."
pacstrap /mnt speedcrunch &>/dev/nul

info_print "Installing 'YADM' config management.."
pacstrap /mnt yadm tree &>/dev/null

info_print "Configuing system wide 'ly' Display Manager.."
echo "animate = true" >> /mnt/etc/ly/config.ini # Enable lock screen animation
echo "animation = 1" >> /mnt/etc/ly/config.ini # Select Matrix like live wallpaper

info_print "Customizing install with 'yay' 'brave' 'brillo' and 'dotfiles' repo"
arch-chroot /mnt /bin/bash -e <<EOF

               echo "Installing yay in arch-chroot.."
               mkdir -p /home/kani/tmp
               cd /home/kani/tmp
               git clone https://aur.archlinux.org/yay-bin.git
               chown -R kani:kani /home/kani
               cd yay-bin
               sudo -u kani bash -c 'makepkg -si --noconfirm'
               cd .. # back to tmp
               rm -r yay-bin

               echo "Installing 'brave' and 'brillo' using yay"
               sudo -u kani bash -c 'yay -S --noconfirm brave-bin brillo'

               # TODO - Clone dorfiles repo - Apply config later!
               # runas kani
               #yadm clone https://github.com/TheRealKANi/dotfiles

               echo "Setting up locale.."
               cat > /etc/X11/xorg.conf.d/10-keyboard.conf <<EOF
                   Section "InputClass"
                         Identifier "keyboard default"
                         MatchIsKeyboard "yes"
                         Option  "XkbLayout" "dk"
                         Option  "XkbVariant" "nodeadkeys"
                   EndSection

               # Set sound card profile
               pactl set-card-profile alsa_ctform-tgl_rt1011_rt5682 pro-audio

               # Set default output sink
               pactl set-default-sink alsa_output.pci-0000_00_1f.3-platform-tgl_rt1011_rt5682.pro-output-0

               # Mute all sources
               pactl list short sources | awk '/input.*RUNNING/ {system("pactl set-source-mute " $1 " true")}'

               # Mute all sinks
               pactl list short sinks | awk '/output.*IDLE/ {system("pactl set-sink-mute " $1 " true")}'

               # Unmute Default sink
               pactl set-sink-mute @DEFAULT_SINK@ off
EOF

echo "Starting User Services.."
services=(pipewire pipewire-pulse wireplumber)
for service in "${services[@]}"; do
    sudo -u kani bash -c 'systemctl --user enable "$service"'
done

EOF

# Enable Desktop Services
info_print "Starting Global Services.."
services=(ly)
for service in "${services[@]}"; do
    systemctl enable "$service" --root=/mnt
done
info_print "Creating i3 keybinds to cool-retro-term, brave, brillo and rofi"
mkdir -p /home/kani/.config/i3
# Remove drun and enable rofi
sed -i 's/# bindcode $mod+40 exec "rofi -modi drun,run -show drun"/bindsym $mod+d exec "rofi -modi drun,run -show drun"/' /mnt/home/kani/.config/i3/config
sed -i 's/bindsym $mod+d exec --no-startup-id dmenu_run/# bindsym $mod+d exec --no-startup-id dmenu_run/' /mnt/home/kani/.config/i3/config

# Use cool-retro-term and add brave
sed -i 's/bindsym $mod+Return exec i3-sensible-terminal/bindsym $mod+Return exec cool-retro-term\n\n# start brave browser\nbindsym $mod+b exec brave/' /mnt/home/kani/.config/i3/config

# brillo backlight control   
sed -i 's/bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status/\n# Use brillo to control screen and keyboard backlight\nbindsym XF86MonBrightnessDown exec --no-startup-id brillo -q -u 25000 -s intel_backlight -U 2\nbindsym XF86MonBrightnessUp exec --no-startup-id brillo -q -u 25000 -s intel_backlight -A 2\nbindsym $mod+XF86MonBrightnessDown exec --no-startup-id brillo -q -k -u 25000 -s chromeos::kbd_backlight -U 5\nbindsym $mod+XF86MonBrightnessUp exec --no-startup-id brillo -q -k -u 25000 -s chromeos::kbd_backlight -A 5/' /mnt/home/kani/.config/i3/config

# use py3status instead of i3status - DISABLED
#sed -i 's/status_command i3status/status_command py3status/' /mnt/home/kani/.config/i3/config
