#!/bin/sh
# Install os-prober if needed
apk add os-prober grub-bios

# Force GRUB to show menu and wait
cat > /etc/default/grub << EOF
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu
GRUB_DISABLE_OS_PROBER=false
# Uncomment to get a GRUB menu with a transparent background
# GRUB_GFXMODE=auto
EOF

# Make sure our Arch installation is detectable
mkdir -p /mnt/arch
mount /dev/sdb3 /mnt/arch
## 2 is usually swap
mount /dev/sdb1 /mnt/arch/boot

# Run os-prober to explicitly detect other OSes
os-prober

# Reinstall GRUB to the MBR of the primary drive
grub-install --target=i386-pc --recheck /dev/sda

# Update GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg

# Verify the output
echo "OS-prober output:"
os-prober

# Check if Arch was detected in the GRUB config
if grep -q "Arch" /boot/grub/grub.cfg; then
    echo "Arch Linux was successfully detected!"
else
    echo "Warning: Arch Linux was not detected in GRUB config"
fi

# Unmount the Arch partitions
umount /mnt/arch/boot
umount /mnt/arch
