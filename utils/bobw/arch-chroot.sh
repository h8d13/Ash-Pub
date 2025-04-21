#!/bin/sh
### For quick maintenance from within alpine.

# Create mount point if it doesn't exist
mkdir -p /mnt/arch

# Mount Arch partitions
mount /dev/sdb3 /mnt/arch
mount /dev/sdb1 /mnt/arch/boot

# Mount virtual filesystems
mount -t proc /proc /mnt/arch/proc
mount -t sysfs /sys /mnt/arch/sys
mount -o bind /dev /mnt/arch/dev
mount -o bind /dev/pts /mnt/arch/dev/pts

# Copy resolv.conf for network access
cp /etc/resolv.conf /mnt/arch/etc/resolv.conf

# Chroot into Arch
echo "Entering Arch Linux chroot environment..."
chroot /mnt/arch /bin/bash

# When exiting the chroot, unmount everything
echo "Exiting chroot environment..."
umount /mnt/arch/dev/pts
umount /mnt/arch/dev
umount /mnt/arch/sys
umount /mnt/arch/proc
umount /mnt/arch/boot
umount /mnt/arch

echo "Chroot session ended."
