#!/bin/sh
# REQ
apk add os-prober

# Ensure os-prober is enabled in GRUB config
if ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
fi

# Make sure the USB/Drive is connected and mounted
# You don't need to keep it mounted, just mount it so os-prober can detect it
# replace sdΣx with your own values and use lsblk to check if needed. 

mkdir -p /mnt/usb
mount /dev/sdb2 /mnt/usb
mount /dev/sdb1 /mnt/usb/boot ## Usually part 1 is boot

# Update GRUB config on the host
grub-mkconfig -o /boot/grub/grub.cfg

# Unmount / Cleanup
umount -R /mnt/usb
