#!/bin/sh
# Script for Arch Linux installation on USB
set -e  # Exit on error

# Configuration variables
TARGET_DISK="/dev/sdb"
TARGET_HOSTNAME="archlinux"
TARGET_TIMEZONE="Europe/Paris"
ROOT_PASSWORD="Everest"
TARGET_MOUNT="/mnt/arch"

# Install required packages
echo "Installing required packages in Alpine..."
apk add wget curl zstd dosfstools arch-install-scripts parted grub-bios

# Clean up previous files
rm -rf /tmp/archlinux-bootstrap*

# Ensure target mount point exists
mkdir -p "$TARGET_MOUNT"

# Make sure nothing is mounted from the target disk
echo "Unmounting any existing mounts..."
for mnt in $(mount | grep ${TARGET_DISK} | awk '{print $1}'); do
  echo "Unmounting $mnt"
  umount -f "$mnt" || true
done

# Partitioning - For BIOS boot with separate /boot
echo "Partitioning $TARGET_DISK..."
parted -s "$TARGET_DISK" mklabel msdos
parted -s "$TARGET_DISK" mkpart primary ext4 1MiB 512MiB
parted -s "$TARGET_DISK" set 1 boot on
parted -s "$TARGET_DISK" mkpart primary ext4 512MiB 100%

# Format partitions
echo "Formatting partitions..."
mkfs.ext4 "${TARGET_DISK}1"  # Boot partition
mkfs.ext4 "${TARGET_DISK}2"  # Root partition

# Mount filesystems
echo "Mounting filesystems..."
mount "${TARGET_DISK}2" "$TARGET_MOUNT"       # Mount root
mkdir -p "$TARGET_MOUNT/boot"
mount "${TARGET_DISK}1" "$TARGET_MOUNT/boot"  # Mount boot

# Download and extract Arch bootstrap
echo "Downloading Arch Linux bootstrap..."
cd /tmp
wget https://mirrors.edge.kernel.org/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst
zstd -d archlinux-bootstrap-x86_64.tar.zst
tar -xf archlinux-bootstrap-x86_64.tar -C /tmp
cp -a /tmp/root.x86_64/* "$TARGET_MOUNT"/

# Configure mirror
echo "Configuring pacman..."
echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' > "$TARGET_MOUNT/etc/pacman.d/mirrorlist"

# Configure chroot
echo "Configuring chroot..."
mount -t proc /proc "$TARGET_MOUNT/proc"
mount -t sysfs /sys "$TARGET_MOUNT/sys"
mount -o bind /dev "$TARGET_MOUNT/dev"
mount -o bind /dev/pts "$TARGET_MOUNT/dev/pts"
cp /etc/resolv.conf "$TARGET_MOUNT/etc/"

# Initialize pacman
echo "Initializing pacman..."
chroot "$TARGET_MOUNT" /bin/bash -c "pacman-key --init && pacman-key --populate archlinux"

# Install base system
echo "Installing base system..."
chroot "$TARGET_MOUNT" /bin/bash -c "pacman -Sy base linux linux-firmware --noconfirm"

# Generate fstab
echo "Generating fstab..."
genfstab -U "$TARGET_MOUNT" > "$TARGET_MOUNT/etc/fstab"

# Basic system configuration
cat > "$TARGET_MOUNT/configure.sh" << EOF
#!/bin/bash
# Basic configuration
ln -sf /usr/share/zoneinfo/$TARGET_TIMEZONE /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$TARGET_HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "root:$ROOT_PASSWORD" | chpasswd

# Install GRUB and essentials
pacman -S --noconfirm grub networkmanager base-devel sudo

# Enable NetworkManager
systemctl enable NetworkManager

# Install GRUB to disk
grub-install --target=i386-pc --recheck --force $TARGET_DISK
grub-mkconfig -o /boot/grub/grub.cfg
EOF

chmod +x "$TARGET_MOUNT/configure.sh"
chroot "$TARGET_MOUNT" /configure.sh

# Cleanup with better handling
echo "Cleaning up..."
sync
sleep 2
echo "Unmounting filesystems..."
umount -l "$TARGET_MOUNT/dev/pts" 2>/dev/null || true
umount -l "$TARGET_MOUNT/dev" 2>/dev/null || true
umount -l "$TARGET_MOUNT/proc" 2>/dev/null || true
umount -l "$TARGET_MOUNT/sys" 2>/dev/null || true
umount -l "$TARGET_MOUNT/boot" 2>/dev/null || true  # Unmount boot first
umount -l "$TARGET_MOUNT" 2>/dev/null || true       # Then root

echo "Arch Linux installation complete!"
