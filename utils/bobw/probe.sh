#!/bin/sh
# REQ
apk add os-prober
# Ensure os-prober is enabled in GRUB config
if ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
fi
# Create mount points
mkdir -p /mnt/usb
mkdir -p /mnt/usb/boot
# Mount the root partition first
mount /dev/sdb3 /mnt/usb
# Then mount the boot partition
mount /dev/sdb1 /mnt/usb/boot
# No need to mount swap for os-prober
# Update GRUB config
grub-mkconfig -o /boot/grub/grub.cfg
# Unmount in reverse order
umount /mnt/usb/boot
umount /mnt/usb
# Verify the unmount worked
if mountpoint -q /mnt/usb; then
    echo "Warning: /mnt/usb is still mounted"
    echo "Attempting lazy unmount..."
    umount -l /mnt/usb
fi
