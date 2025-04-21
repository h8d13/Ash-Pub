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
EOF

# Mount Arch partitions to inspect them
mkdir -p /mnt/arch
mount /dev/sdb3 /mnt/arch
mkdir -p /mnt/arch/boot
mount /dev/sdb1 /mnt/arch/boot

# List all kernels in the Arch boot partition
echo "Available kernels in Arch boot partition:"
ls -la /mnt/arch/boot/vmlinuz* /mnt/arch/boot/linux*
echo "Available initramfs in Arch boot partition:"
ls -la /mnt/arch/boot/initramfs* /mnt/arch/boot/init*

# Get exact kernel and initramfs filenames (assuming they exist)
KERNEL_FILE=$(ls /mnt/arch/boot/vmlinuz* 2>/dev/null || ls /mnt/arch/boot/linux* 2>/dev/null | head -1)
KERNEL_BASENAME=$(basename "$KERNEL_FILE")
INITRD_FILE=$(ls /mnt/arch/boot/initramfs* 2>/dev/null || ls /mnt/arch/boot/init* 2>/dev/null | head -1)
INITRD_BASENAME=$(basename "$INITRD_FILE")

echo "Using kernel: $KERNEL_BASENAME"
echo "Using initrd: $INITRD_BASENAME"

# Create custom entry with correct filenames
cat > /etc/grub.d/40_custom << EOF
#!/bin/sh
exec tail -n +3 \$0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.

menuentry "Arch Linux" {
    insmod part_msdos
    insmod ext2
    set root=(hd1,1)
    linux /$KERNEL_BASENAME root=/dev/sdb3 rw rootfstype=ext4
    initrd /$INITRD_BASENAME
}
EOF
chmod +x /etc/grub.d/40_custom

# Run os-prober
os-prober

# Reinstall GRUB
grub-install --target=i386-pc --recheck /dev/sda

# Update GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg

# Verify GRUB configuration includes the custom entry
grep -A 10 "Arch Linux" /boot/grub/grub.cfg

# Unmount Arch partitions
umount /mnt/arch/boot
umount /mnt/arch

echo "Done! The custom Arch Linux entry has been added with the correct kernel path."
