# Mboot - Multiboot Disk Creator
Mboot is a bash script designed to create multi-boot disk capable of initializing and installing operating systems directly from ISO files.

## Features
- Automatically formats and prepares target drive for multi-booting;
- Sets up a bootable environment to initialize installation ISO files;
- Configures GRUB2 with support for modern UEFI x64 architectures (UEFI Secure Boot disabled);
- Generates a default menu entry for easy configuration;
- Provides custom menus for other distributions.

## Prerequisites and Dependencies
This script interacts directly with hardware storage devices and requires root privileges (`sudo`) to run.  The following system utilities must be pre-installed on your Linux host environment:

1. lsblk: to list and identify block storage devices;
2. wipefs: clean existing signatures and partition tables from disks;
3. gdisk: manipulate GPT (GUID Partition Table) structures;
4. parted: handle disk partitioning operations;
5. grub2-install: deploy the bootloader onto the target drive;
6. grub2-tools: core support utilities for configuring GRUB2;
7. grub2-efi-x64-modules: essential GRUB modules for UEFI x64 system compatibility.
 

### Installing Dependencies (Fedora Workstation 44 / RHEL)
```bash
sudo dnf install util-linux gdisk parted grub2-tools grub2-efi-x64-modules
```
### Installing Dependencies (Fedora Silverblue 44)
```bash
sudo rpm-ostree install util-linux gdisk parted grub2-tools grub2-efi-x64-modules
```

## Tutorial

# Git
Clone the repository and prepare the script for execution:
1. Clone the repository:
   ```bash
   git clone https://github.com/iacques/mboot.git
   ```
2. Navigate into the directory:
   ```bash
   cd mboot
   ```
3. Grant executable permissions to the script:
   ```bash
   chmod +x mboot.sh
   ```
# Direct download
If you prefer to download and run the script standalone without using Git, follow these step-by-step instructions:

1. Download script on terminal:
   ```bash
    wget https://github.com/iacques/mboot/raw/refs/heads/main/mboot.sh
   ```
2. Grant executable permissions to the script:
   ```bash
   chmod +x mboot.sh
   ```
# Runnig script
1. Verify your USB device: Run `lsblk` to identify your target drive;
2. Configure the script: Open `mboot.sh` in a text editor and change the target device variable to match your drive (the default is `/dev/sdd`);
3. Execute the script: Run the script with root privileges:
 ```bash
sudo ./mboot.sh
 ```
4. Partition Creation: The script will automatically prepare the USB drive for booting and generate 2 specific partitions: `MBOOT` and `MISO`;
5. Mount the ISO partition: Mount the newly created storage partition (`/MISO`);
6. Add your ISO files: Copy your downloaded ISO images directly into the `/MISO/iso/` directory;
7. Mount the boot partition: Mount the primary boot partition (`/MBOOT`);
9. Default Menu Entry: The script automatically generates a baseline configuration file with a default entry pointing to Debian 13.5 (LXQT) located at `/MBOOT/boot/grub/grub.cfg`;
9. Add more ISOs: Edit the `/MBOOT/boot/grub/grub.cfg` file to add more operating systems. Make sure to update the menu entries with your specific ISO filenames;

# Custom menu entries
Use the grub.cfg.menuentry.example as templates for your custom entries.

# Licence
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. For more information, please read the [GNU General Public License v3.0](https://gnu.org).

Copyright (C) 2026 Jacques Eduardo Nunes

