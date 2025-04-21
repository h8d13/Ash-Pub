#!/bin/sh
# Script for dual boot Arch & Alpine
set -e  # Exit on error

# WHAT DO WE NEED IN ALPINE?
echo "Installing required packages in Alpine..."
apk add wget curl zstd dosfstools arch-install-scripts parted efibootmgr

# Clean up previous attempt files
rm -rf /tmp/archlinux-bootstrap*

# Configuration variables
TARGET_DISK="/dev/sdb"
TARGET_HOSTNAME="archlinux"
TARGET_TIMEZONE="Europe/Paris"
ROOT_PASSWORD="Everest"
TARGET_MOUNT="/mnt/arch"

# Create mount directory
mkdir -p "$TARGET_MOUNT"

# Ensure all partitions are unmounted
echo "Ensuring all partitions are unmounted..."
umount -l "$TARGET_MOUNT" 2>/dev/null || true
umount -l "${TARGET_DISK}1" 2>/dev/null || true
umount -l "${TARGET_DISK}2" 2>/dev/null || true
umount -fl "${TARGET_DISK}*" 2>/dev/null || true

# Partitioning
echo "Partitioning $TARGET_DISK..."
parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart primary fat32 1MiB 513MiB
parted -s "$TARGET_DISK" set 1 esp on
parted -s "$TARGET_DISK" mkpart primary ext4 513MiB 100%

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${TARGET_DISK}1"
mkfs.ext4 "${TARGET_DISK}2"

# Mount the target filesystem
echo "Mounting filesystems..."
mount "${TARGET_DISK}2" "$TARGET_MOUNT"
mkdir -p "$TARGET_MOUNT/boot/efi"
mount "${TARGET_DISK}1" "$TARGET_MOUNT/boot/efi"

# Download and extract Arch bootstrap
echo "Downloading Arch Linux bootstrap..."
cd /tmp
wget https://mirrors.edge.kernel.org/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst
zstd -d archlinux-bootstrap-x86_64.tar.zst
tar -xf archlinux-bootstrap-x86_64.tar -C /tmp
cp -a /tmp/root.x86_64/* "$TARGET_MOUNT"/

# Configure pacman mirrorlist
echo "Configuring pacman..."
echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' > "$TARGET_MOUNT/etc/pacman.d/mirrorlist"

# Configure the chroot environment
echo "Configuring chroot environment..."
mount -t proc /proc "$TARGET_MOUNT/proc"
mount -t sysfs /sys "$TARGET_MOUNT/sys"
mount -o bind /dev "$TARGET_MOUNT/dev"
mount -o bind /dev/pts "$TARGET_MOUNT/dev/pts"
cp /etc/resolv.conf "$TARGET_MOUNT/etc/"

# Check for EFI support and mount if available
if [ -d /sys/firmware/efi/efivars ]; then
  echo "EFI system detected, mounting EFI variables..."
  mkdir -p "$TARGET_MOUNT/sys/firmware/efi/efivars"
  mount -o bind /sys/firmware/efi/efivars "$TARGET_MOUNT/sys/firmware/efi/efivars" || echo "Warning: Could not mount EFI variables"
else
  echo "BIOS system detected, will configure GRUB accordingly"
fi

# Initialize pacman keyring
echo "Initializing pacman keyring..."
chroot "$TARGET_MOUNT" /bin/bash -c "pacman-key --init && pacman-key --populate archlinux"

# Bootstrap the system
echo "Bootstrapping Arch Linux..."
chroot "$TARGET_MOUNT" /bin/bash -c "pacman -Sy base linux linux-firmware --noconfirm"
genfstab -U "$TARGET_MOUNT" > "$TARGET_MOUNT/etc/fstab"

# Configure the new system
echo "Configuring new system..."
cat > "$TARGET_MOUNT/configure.sh" << EOF
#!/bin/bash
ln -sf /usr/share/zoneinfo/$TARGET_TIMEZONE /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$TARGET_HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $TARGET_HOSTNAME.localdomain $TARGET_HOSTNAME" >> /etc/hosts
echo "root:$ROOT_PASSWORD" | chpasswd
pacman -S --noconfirm grub efibootmgr networkmanager base-devel sudo os-prober

echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
systemctl enable NetworkManager

# Install GRUB based on system type
if [ -d /sys/firmware/efi/efivars ]; then
  echo "Installing GRUB for UEFI system..."
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
else
  echo "Installing GRUB for BIOS system..."
  grub-install --target=i386-pc $TARGET_DISK
fi

# Generate GRUB config
grub-mkconfig -o /boot/grub/grub.cfg
EOF

chmod +x "$TARGET_MOUNT/configure.sh"
chroot "$TARGET_MOUNT" /configure.sh

# Cleanup
echo "Cleaning up..."
umount -R "$TARGET_MOUNT" || echo "Warning: Some filesystems could not be unmounted, may need manual cleanup"
echo "Arch Linux installation complete!"
