#!/usr/bin/env -S bash -e
# Created By TheRealKANi 2023-09-20
# https://github.com/TheRealKANi/scripts/blob/main/archInstall.sh
# TheRealARCH Installer for my personal usage.
# Inspired heavly and adapted from: 'https://github.com/classy-giraffe/easy-arch'
# Run with bash <(curl -L https://raw.githubusercontent.com/TheRealKANi/scripts/main/archInstall.sh)
clear
echo "===================================================================================="
echo "   _______  _             ______                 _   _______                _       "
echo "  (_______)| |           (_____ \               | | (_______)              | |      "
echo "      _    | |__   _____  _____) ) _____  _____ | |  _______   ____   ____ | |__    "
echo "     | |   |  _ \ | ___ ||  __  / | ___ |(____ || | |  ___  | / ___) / ___)|  _ \   "
echo "     | |   | | | || ____|| |  \ \ | ____|/ ___ || | | |   | || |    ( (___ | | | |  "
echo "     |_|   |_| |_||_____)|_|   |_||_____)\_____| \_)|_|   |_||_|     \____)|_| |_|  "
echo "===================================================================================="
echo "Starting 'TheRealArch' Base Installer.."
echo " "

# This section is taken from:
# https://github.com/classy-giraffe/easy-arch/blob/main/easy-arch.sh

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

# User enters a hostname (function).
hostname_selector () {
    input_print "Please enter the hostname: "
    read -r hostname
    if [[ -z "$hostname" ]]; then
        error_print "You need to enter a hostname in order to continue."
        return 1
    fi
    return 0
}

# Microcode detector (function).
microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ "$CPU" == *"AuthenticAMD"* ]]; then
        info_print "An AMD CPU has been detected, the AMD microcode will be installed."
        microcode="amd-ucode"
    else
        info_print "An Intel CPU has been detected, the Intel microcode will be installed."
        microcode="intel-ucode"
    fi
}

# Selecting a kernel to install (function).
kernel_selector () {
    info_print "List of kernels:"
    info_print "1) Stable: Vanilla Linux kernel with a few specific Arch Linux patches applied"
    info_print "2) Hardened: A security-focused Linux kernel"
    info_print "3) Longterm: Long-term support (LTS) Linux kernel"
    info_print "4) Zen Kernel: A Linux kernel optimized for desktop usage"
    input_print "Please select the number of the corresponding kernel (e.g. 1): " 
    read -r kernel_choice
    case $kernel_choice in
        1 ) kernel="linux"
            return 0;;
        2 ) kernel="linux-hardened"
            return 0;;
        3 ) kernel="linux-lts"
            return 0;;
        4 ) kernel="linux-zen"
            return 0;;
        * ) error_print "You did not enter a valid selection, please try again."
            return 1
    esac
} 

# User enters a password for the LUKS Container (function).
lukspass_selector () {
    input_print "Please enter a password for the LUKS container (you're not going to see the password): "
    read -r -s password
    if [[ -z "$password" ]]; then
        echo
        error_print "You need to enter a password for the LUKS Container, please try again."
        return 1
    fi
    echo
    input_print "Please enter the password for the LUKS container again (you're not going to see the password): "
    read -r -s password2
    echo
    if [[ "$password" != "$password2" ]]; then
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# Setting up a password for the user account (function).
userpass_selector () {
    input_print "Please enter name for a user account (enter empty to not create one): "
    read -r username
    if [[ -z "$username" ]]; then
        return 0
    fi
    input_print "Please enter a password for $username (you're not going to see the password): "
    read -r -s userpass
    if [[ -z "$userpass" ]]; then
        echo
        error_print "You need to enter a password for $username, please try again."
        return 1
    fi
    echo
    input_print "Please enter the password again (you're not going to see it): " 
    read -r -s userpass2
    echo
    if [[ "$userpass" != "$userpass2" ]]; then
        echo
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# Setting up a password for the root account (function).
rootpass_selector () {
    input_print "Please enter a password for the root user (you're not going to see it): "
    read -r -s rootpass
    if [[ -z "$rootpass" ]]; then
        echo
        error_print "You need to enter a password for the root user, please try again."
        return 1
    fi
    echo
    input_print "Please enter the password again (you're not going to see it): " 
    read -r -s rootpass2
    echo
    if [[ "$rootpass" != "$rootpass2" ]]; then
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

check_internet () {
    input_print "Checking internet connection.." 
    wget -q --spider https://google.com
    if [ $? -ne 0 ]; then
        error_print "Internet is required to proceed"
        exit
    else
        info_print_clean "OK.."
    fi
}

# User chooses the locale (function).
locale_selector () {
    input_print "Please insert the locale you use (format: xx_XX. Enter empty to use en_DK, or \"/\" to search locales): " locale
    read -r locale
    case "$locale" in
        '') locale="en_DK.UTF-8"
            info_print "$locale will be the default locale."
            return 0;;
        '/') sed -E '/^# +|^#$/d;s/^#| *$//g;s/ .*/ (Charset:&)/' /etc/locale.gen | less -M
             clear
             return 1;;
        *)  if ! grep -q "^#\?$(sed 's/[].*[]/\\&/g' <<< "$locale") " /etc/locale.gen; then
                error_print "The specified locale doesn't exist or isn't supported."
                return 1
            fi
            return 0
    esac
}

# User chooses the console keyboard layout (function).
keyboard_selector () {
    input_print "Please insert the keyboard layout to use in console, X11 (enter empty to use DK, or \"/\" to look up for keyboard layouts): "
    read -r kblayout
    case "$kblayout" in
        '') kblayout="dk"
            info_print "The standard DK keyboard layout will be used.";;
        '/') localectl list-keymaps
             clear
          return 1;;
        *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
               error_print "The specified keymap doesn't exist."
               return 1
           fi
    esac
    info_print "Changing console and X11 layout to $kblayout."
    # NEDDED?
    #loadkeys "$kblayout"
    #localectl set-keymap "$kblayout"
    #localectl set-x11-keymap "$kblayout"
    return 0
}

diskSelector () {
    # Choosing the target for the installation.
    info_print "Available disks for the installation:"
    PS3="Please select the number of the corresponding disk (e.g. 1): "
    select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd|mmc");
    do
        DISK="$ENTRY"
        info_print "Arch Linux will be installed on the following disk: '$DISK'"
        break
    done
}

secureErase () {
    info_print "Overwriting entire selected disk with random data.. (This may take a while)"
    pv --stop-at-size -s "$(blockdev --getsize64 $DISK)" /dev/urandom > $DISK
}

createPartitions () {
    info_print "Writing new partiton setup to disk"
    sgdisk --clear $DISK &>/dev/null
    sgdisk --new=1:0:+512MiB --typecode=1:ef00 --change-name=1:EFI $DISK &>/dev/null
    sgdisk --new=2:0:0 --typecode=2:8300 --change-name=2:cryptsystem $DISK &>/dev/null
}

modprobe dm-crypt
modprobe dm-mod

formatLUKSPartition () {
    CRYPTROOT="/dev/disk/by-partlabel/cryptsystem"
    # Creating a LUKS Container for the root partition.
    info_print "Creating LUKS Container for the root partition."
    echo -n "$password" | cryptsetup luksFormat \
                                     --type luks2 --key-size 512 --hash sha512 \
                                     --use-urandom "$CRYPTROOT" -d - &>/dev/null
    echo -n "$password" | cryptsetup open "$CRYPTROOT" \
                                     cryptsystem -d - 
}

formatEFI () {
    info_print "Formatting EFI partition as FAT32.."
    mkfs.fat -F 32 -n EFI /dev/disk/by-partlabel/EFI &>/dev/null
}

formatLuksContainer () {
    info_print "Formatting LUKS Container as BTRFS.."
    mkfs.btrfs --label system /dev/mapper/cryptsystem &>/dev/null
    mount -t btrfs LABEL=system /mnt
}

createSubvolumes () {
    info_print "Creating BTRFS subvolumes.."
    subvols=(root home snapshots)
    for subvol in "${subvols[@]}"; do
        btrfs subvolume create /mnt/@"$subvol" &>/dev/null
    done
}

mountSubvolumes () {
    umount -R /mnt
    info_print "Mounting all BTRFS Subvolumes.."
    mountopts="defaults,x-home.mkdir,ssd,noatime,compress-force=zstd:3,discard=async"
    mount -t btrfs -o "$mountopts",subvol=@root LABEL=system /mnt

    # Create dirs for subvolumes
    mkdir -p /mnt/{.snapshots,home}
    mount -t btrfs -o "$mountopts",subvol=@home LABEL=system /mnt/home
    mount -t btrfs -o "$mountopts",subvol=@snapshots LABEL=system /mnt/.snapshots
}

createMountEFI () {
    info_print "Creating and mounting EFI partition"
    mkdir /mnt/efi
    mount LABEL=EFI /mnt/efi
}

installBaseSystem () {
    info_print "Updaing pacman"
    pacman -Syy
    info_print "Installing the base system (it may take a while)."
    pacstrap -K /mnt base "$kernel" "$microcode" linux-firmware \
             "$kernel"-headers archlinux-keyring sudo
}

installBaseAddons () {
    info_print "Installing Addons to Base System"
    pacstrap /mnt nano btrfs-progs sbctl efibootmgr git base-devel go plymouth reflector htop
}

setupNetworking () {
    info_print "Setting up network.."
    pacstrap /mnt networkmanager >/dev/null
    systemctl enable NetworkManager --root=/mnt &>/dev/null
}

setupFirewall () {
    info_print "Setting up UFW firewall.."
    pacstrap /mnt ufw >/dev/null
    systemctl enable ufw --root=/mnt &>/dev/null
    #arch-chroot /mnt /bin/bash -e <<EOF
#        ufw enable
#EOF
}

generateFstab () {
    info_print "Generating FSTAB.."
    genfstab -L -P /mnt >> /mnt/etc/fstab
}

configureLocale () {
    info_print "Configuring Locale and Keymap..."
    # Configure selected locale and console keymap
    sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
    echo "LANG=$locale" > /mnt/etc/locale.conf
    echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf
}

configureMkinitcpio () {
    info_print "Configuring /etc/mkinitcpio.conf..."
    cat > /mnt/etc/mkinitcpio.conf <<EOF
HOOKS=(base systemd autodetect plymouth keyboard sd-vconsole modconf block filesystems btrfs sd-encrypt fsck)
EOF
}

configureCmdline () {
    info_print "Configuring /etc/kernel/cmdline..."
    cat > /mnt/etc/kernel/cmdline <<EOF
fbcon=nodefer rw rd.luks.allow-discards quiet bgrt-disable root=LABEL=system rootflags=subvol=@root,rw splash vt.global_cursor_default=1  
EOF
}

configureCrypttab () {
    info_print "Configuring /etc/crypttab.initramfs..."
    echo "system /dev/disk/by-partlabel/cryptsystem none timeout=180" > /mnt/etc/crypttab.initramfs
}

pacmanSetup () {
    info_print "Setting up pacman in live installation"
    pacman-key --init &>/dev/null
    pacman-key --populate archlinux &>/dev/null
    sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /etc/pacman.conf
}

pacmanAddons () {
    # Pacman eye-candy features.
    info_print "Enabling colours, animations, and parallel downloads for pacman."
    sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /mnt/etc/pacman.conf
}

enableServices () {
    # Enabling various services.
    info_print "Enabling Reflector, BTRFS scrubbing."
    services=(reflector.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@snapshots.timer ufw)
    for service in "${services[@]}"; do
        systemctl enable "$service" --root=/mnt &>/dev/null
    done
}

configureUsers () {
    # Setting root password.
    info_print "Setting root password."
    echo "root:$rootpass" | arch-chroot /mnt chpasswd

    # Setting user password.
    if [[ -n "$username" ]]; then
        echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
        info_print "Adding the user $username to the system with root privilege."
        arch-chroot /mnt useradd -m -G wheel,audio,video -s /bin/bash "$username"
        #arch-chroot /mnt usermod -aG audio video -s /bin/bash "$username"
        info_print "Setting user password for $username."
        echo "$username:$userpass" | arch-chroot /mnt chpasswd 
    fi
}

configureSystem () {
    # Configuring the system.
    info_print "Configuring the system (timezone, system clock, initramfs, efibootmgr and plymouth-git)."
    arch-chroot /mnt /bin/bash -e <<EOF
  # Setting up timezone.
  ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) \
  /etc/localtime &>/dev/null

  # Setting up clock.
  hwclock --systohc

  # Generating locales.
  locale-gen &>/dev/null

  # Generating a new initramfs.
  mkinitcpio -P &>/dev/null

  # Create secure boot keys
  sbctl create-keys

  # Sign EFI bundle
  sbctl bundle -s /efi/main.efi

  # Set default spinner
  plymouth-set-default-theme -R spinner

  # Generating a new initramfs.
  mkinitcpio -P &>/dev/null

  # Create secure boot keys
  sbctl create-keys

  # Sign EFI bundle
  sbctl bundle -s /efi/main.efi

  # Creating UEFI boot entry
  efibootmgr --create --disk $DISK --part 1 --label "TheRealArch" --loader main.efi --unicode

EOF
}

scriptEnd () {
    # Finishing up.
    info_print "Done, you may now wish to reboot (further changes can be done by chrooting into /mnt)."
    # Query user about install desktop packages or EXIT
    exit
}

until keyboard_selector; do : ; done

# Select Disk to work on
diskSelector

# User choses the locale.
until locale_selector; do : ; done

# Setting up LUKS password.
until lukspass_selector; do : ; done

# User sets up the user/root passwords.
until userpass_selector; do : ; done
until rootpass_selector; do : ; done

# Setting up the kernel.
until kernel_selector; do : ; done

# User choses the hostname.
until hostname_selector; do : ; done

#secureErase - DISABLED for testing
createPartitions

# Informing the Kernel of the changes.
info_print "Informing the Kernel about the disk changes."
partprobe "$DISK"

formatEFI
formatLUKSPartition
formatLuksContainer

createSubvolumes
mountSubvolumes
createMountEFI

microcode_detector
pacmanSetup
installBaseSystem
installBaseAddons
configureUsers
pacmanAddons

info_print "Configuring Hostname.."
echo "$hostname" > /mnt/etc/hostname

generateFstab
configureLocale

setupNetworking
setupFirewall
configureMkinitcpio
configureCmdline
configureCrypttab

configureSystem
enableServices

scriptEnd
