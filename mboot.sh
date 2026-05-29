#!/bin/bash

# Title:        mboot.sh
# Version:      0.7
# Author:       Jacques Eduardo Nunes <iacques@yahoo.com.br> + IA Assist
# License:      GPL-3.0 (GNU General Public License v3.0)
#
# Description:  This script will create a multi-boot disk that can init install ISO files.
# Dependencies: lsblk, wipefs, gdisk, grub2-install, grub2-tools, grub2-efi-x64-modules and parted.
# Tested on:    Fedora Silverblue 44 with UEFI Secure Boot DISABLED.

# Alert the user immediately if not executed as Root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

echo "Welcome to Mboot 0.7. Use with caution!"
echo "Your devices:"
lsblk

##### -------------------------------------------------------------------------------------- ###
##### CHECK AND CHANGE YOUR USB DEVICE HERE
DISK="/dev/sdc"
##### -------------------------------------------------------------------------------------- ###

# Partition Labels
EFI_LABEL="MBOOT"
ISO_LABEL="MISO"

# Mount points
MNT_BOOT="/mnt/m-boot"
MNT_ISO="/mnt/m-iso"

# Default downloaded ISO name
ISO_DEBIAN="debian-live-13.5.0-amd64-lxqt.iso"

# Target disk validation
if [[ ! -b "$DISK" ]]; then
    echo "Invalid disk or not found: $DISK"
    exit 1
fi

# Detects the host main OS drive to protect it
ROOT_DISK=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /) 2>/dev/null)
if [[ -n "$ROOT_DISK" && "$DISK" == "/dev/$ROOT_DISK" ]]; then
    echo "##### ERROR: The selected disk ($DISK) is your CURRENT SYSTEM DRIVE!"
    echo "Operation aborted for safety."
    exit 1
fi

echo "##### ATTENTION! The following disk will be COMPLETELY WIPED: $DISK"
echo "Make sure this is your portable USB adapter."
read -r -p "Type YES to continue: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || {
    echo "Operation canceled."
    exit 1
}

# Tests if the disk is in use by any system process
if fuser -s "${DISK}"; then
    echo "The disk is BUSY! You must close active processes before proceeding."
    exit 1
else
    echo "Disk is idle. Unmounting existing partitions for safety..."
    umount -R "$MNT_BOOT" 2>/dev/null || true
    umount -R "$MNT_ISO" 2>/dev/null || true
    umount "${DISK}"* 2>/dev/null || true
fi

wipefs -a "$DISK" || { exit 1; }

sgdisk --zap-all "$DISK" || { exit 1; }

parted -s "$DISK" mklabel gpt || { exit 1; }

parted -s -a min "$DISK" mkpart BOOT fat32 1MiB 1025MiB || { exit 1; }
parted -s "$DISK" set 1 esp on || { exit 1; }

parted -s -a min "$DISK" mkpart ISOs ext4 1025MiB 100% || { exit 1; }

# Waits for the kernel to update the hardware partition table
sleep 2

# Partition naming
if [[ "$DISK" =~ "nvme" || "$DISK" =~ "mmcblk" ]]; then
    BOOT_PART="${DISK}p1"
    ISO_PART="${DISK}p2"
else
    BOOT_PART="${DISK}1"
    ISO_PART="${DISK}2"
fi

# Formating
mkfs.fat -F32 -n "$EFI_LABEL" "$BOOT_PART"
mkfs.ext4 -F -L "$ISO_LABEL" "$ISO_PART"

# Captures UUID of the EXT4 partition (ISO)
ISO_UUID=$(blkid -o value -s UUID "$ISO_PART")

mkdir -p "$MNT_BOOT" "$MNT_ISO" || { exit 1; }

mount "$BOOT_PART" "$MNT_BOOT" || { exit 1; }
mount "$ISO_PART" "$MNT_ISO" || { exit 1; }

mkdir -p "$MNT_BOOT/EFI/BOOT" "$MNT_BOOT/boot/grub" "$MNT_ISO/iso" || { exit 1; }

chown -R "$SUDO_USER:$SUDO_USER" "$MNT_ISO/iso" 2>/dev/null || chown -R 1000:1000 "$MNT_ISO/iso" || { exit 1; }

grub2-install \
    --target=x86_64-efi \
    --efi-directory="$MNT_BOOT" \
    --boot-directory="$MNT_BOOT/boot" \
    --removable \
    --recheck \
    --force

cat <<'EOF' | tee "$MNT_BOOT/EFI/BOOT/grub.cfg" >/dev/null
search --no-floppy --set=root --file /boot/grub/grub.cfg
configfile /boot/grub/grub.cfg
EOF

cat <<'EOF' | tee "$MNT_BOOT/boot/grub/grub.cfg" >/dev/null
set menu_color_normal=white/black
set menu_color_highlight=black/green

set timeout=5
set default=0
set pager=1

insmod iso9660
insmod loopback
insmod part_gpt
insmod ext2
insmod btrfs
insmod gzio
insmod all_video
EOF

# GRUB global variables
echo "set iso_part_uuid=\"$ISO_UUID\"" | tee -a "$MNT_BOOT/boot/grub/grub.cfg" >/dev/null
echo "set iso_debian=\"$ISO_DEBIAN\"" | tee -a "$MNT_BOOT/boot/grub/grub.cfg" >/dev/null

# Adds menu entries
cat <<'EOF' | tee -a "$MNT_BOOT/boot/grub/grub.cfg" >/dev/null

menuentry "Debian 13.5 (LXQT)" {
    search --no-floppy --set=root --fs-uuid "$iso_part_uuid"
    set isofile="/iso/$iso_debian"
    loopback loop ($root)$isofile
    linux (loop)/live/vmlinuz-6.12.86+deb13-amd64 boot=live components findiso=${isofile}
    initrd (loop)/live/initrd.img-6.12.86+deb13-amd64
}

menuentry "Reboot Computer" {
    reboot
}

menuentry "Power Off Computer" {
    halt
}
EOF

sync

umount "$MNT_BOOT"
umount "$MNT_ISO"

echo "Your multi-boot disk has been created."
exit 0
