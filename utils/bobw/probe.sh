#!/bin/sh
# Install os-prober if needed
apk add os-prober grub-bios

# Force GRUB to show menu and wait
cat > /etc/default/grub << EOF
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu
GRUB_DISABLE_OS_PROBER=false
GRUB_GFXMODE=1024x768
GRUB_TERMINAL_OUTPUT="gfxterm"
# Add this to help with path resolution
GRUB_DISABLE_SUBMENU=y
EOF

# Make sure our Arch installation is properly mounted
mkdir -p /mnt/arch
mount /dev/sdb3 /mnt/arch
mkdir -p /mnt/arch/boot
mount /dev/sdb1 /mnt/arch/boot

# Create custom entry for Arch Linux (more reliable than os-prober sometimes)
mkdir -p /etc/grub.d/custom
cat > /etc/grub.d/40_custom << EOF
#!/bin/sh
exec tail -n +3 \$0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.

menuentry "Arch Linux" {
    set root=(hd1,1)
    linux /vmlinuz-linux root=/dev/sdb3 rw
    initrd /initramfs-linux.img
}
EOF
chmod +x /etc/grub.d/40_custom

# Run os-prober to detect other OSes
os-prober

# Reinstall GRUB to the MBR of the primary drive
grub-install --target=i386-pc --recheck /dev/sda

# Update GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg

# Verify the kernel and initramfs files exist on Arch boot partition
echo "Checking for kernel and initramfs files:"
ls -la /mnt/arch/boot/

# Unmount the Arch partitions
umount /mnt/arch/boot
umount /mnt/arch
