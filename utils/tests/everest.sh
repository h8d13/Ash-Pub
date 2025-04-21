#!/bin/sh
# Script for dual boot Arch & Alpine
set -e  # Exit on error

# WHAT DO WE NEED IN ALPINE ?
echo "Installing required packages in Alpine..."
apk add wget curl zstd dosfstools

## Make sure user doesnt have a file named arch-bootstrap in /tmp
## Case: failed previous install
rm -rf /tmp/archlinux-bootstrap*

# Configuration variables - adjust these
TARGET_DISK="/dev/sdb"  # The disk to install Arch on
# Find out where the Alpine install is (so we don't overwrite it.) Currently manual
# Try lazy unmount
umount -l "$TARGET_MOUNT" 2>/dev/null || true
umount -l "${TARGET_DISK}1" 2>/dev/null || true
umount -l "${TARGET_DISK}2" 2>/dev/null || true

TARGET_HOSTNAME="archlinux"
## Use the same hostname as Alpine install + arch
TARGET_TIMEZONE="Europe/Paris"
ROOT_PASSWORD="Everest"  # Please change this!
TARGET_MOUNT="/mnt/arch"

# Create directories
mkdir -p "$TARGET_MOUNT"

# Partitioning - CAUTION: This will erase all data on TARGET_DISK
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
echo "Keyrings"
chroot "$TARGET_MOUNT" /bin/bash -c "pacman-key --init && pacman-key --populate archlinux"

# Bootstrap the system
echo "Bootstrapping Arch Linux..."
chroot "$TARGET_MOUNT" /bin/bash -c "pacstrap /mnt base linux linux-firmware"
chroot "$TARGET_MOUNT" /bin/bash -c "genfstab -U /mnt >> /mnt/etc/fstab"

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
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

chmod +x "$TARGET_MOUNT/configure.sh"
chroot "$TARGET_MOUNT" /configure.sh

# Cleanup
echo "Cleaning up..."
umount -R "$TARGET_MOUNT"
echo "Arch Linux installation complete!"
