#!/bin/sh
# Install os-prober if needed
apk add os-prober grub-efi
# Force GRUB to show menu and wait
cat > /etc/default/grub << EOF
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu
GRUB_DISABLE_OS_PROBER=false
GRUB_GFXMODE=1024x768
GRUB_TERMINAL_OUTPUT="gfxterm"
EOF
# Make sure our Arch installation is detectable
mkdir -p /mnt/arch
mount /dev/sdb3 /mnt/arch
## 2 is usually swap
mount /dev/sdb1 /mnt/arch/boot/efi
# Run os-prober to explicitly detect other OSes
os-prober
# Reinstall GRUB to the EFI partition
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
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
umount /mnt/arch/boot/efi
umount /mnt/arch
