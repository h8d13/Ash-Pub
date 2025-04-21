#!/bin/sh
# Script for Arch installation # Assumes a couple of things: x86_64, and /dev/sdb

set -e  # Exit on error
# Configuration variables
KB_LAYOUT=$(ls /etc/keymap/*.bmap.gz 2>/dev/null | head -1 | sed 's|/etc/keymap/||' | sed 's|\.bmap\.gz$||') 
TARGET_DISK="/dev/sdb"
TARGET_HOSTNAME=$(cat /etc/hostname)-arch
TARGET_TIMEZONE="Europe/Paris"
ROOT_PASSWORD="Everest"
SWAP_SIZE="4G" 
# Install required packages
echo "Installing required packages in Alpine..."
apk add wget curl zstd dosfstools arch-install-scripts parted grub-bios
# Clean up previous files if canceled/failed install
rm -rf /tmp/archlinux-bootstrap*
# Ensure target mount point exists
TARGET_MOUNT="/mnt/arch"
mkdir -p "$TARGET_MOUNT"
# Make sure nothing is mounted from the target disk
echo "Unmounting any existing mounts..."
for mnt in $(mount | grep ${TARGET_DISK} | awk '{print $1}'); do
  echo "Unmounting $mnt"
  umount -f "$mnt" || true
done
# Partitioning with three partitions: boot, swap, and root
echo "Partitioning $TARGET_DISK..."
parted -s "$TARGET_DISK" mklabel msdos
parted -s "$TARGET_DISK" mkpart primary ext4 1MiB 512MiB
parted -s "$TARGET_DISK" set 1 boot on
parted -s "$TARGET_DISK" mkpart primary linux-swap 512MiB 4.5GiB
parted -s "$TARGET_DISK" mkpart primary ext4 4.5GiB 100%
# Format partitions
echo "Formatting partitions..."
mkfs.ext4 "${TARGET_DISK}1"  # Boot partition
mkswap "${TARGET_DISK}2"     # Swap partition
swapon "${TARGET_DISK}2"     # Enable swap
mkfs.ext4 "${TARGET_DISK}3"  # Root partition
# Mount filesystems
echo "Mounting filesystems... And target mount."
mount "${TARGET_DISK}3" "$TARGET_MOUNT"       # Mount root
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
echo "KEYMAP=$KB_LAYOUT" > /etc/vconsole.conf 
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "root:$ROOT_PASSWORD" | chpasswd

# Install GRUB and essentials including os-prober
pacman -S --noconfirm grub networkmanager base-devel sudo util-linux os-prober

# Enable os-prober to detect other operating systems
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

# Enable NetworkManager
systemctl enable NetworkManager

# Install GRUB to disk
grub-install --target=i386-pc --recheck --force $TARGET_DISK

# Run os-prober to detect other operating systems
os-prober

# Generate GRUB configuration with detected operating systems
grub-mkconfig -o /boot/grub/grub.cfg
EOF
chmod +x "$TARGET_MOUNT/configure.sh"
chroot "$TARGET_MOUNT" /configure.sh
# Cleanup with better handling
echo "Cleaning up..."
sync
sleep 2
echo "Unmounting filesystems..."
swapoff "${TARGET_DISK}2" || true
umount -l "$TARGET_MOUNT/dev/pts" 2>/dev/null || true
umount -l "$TARGET_MOUNT/dev" 2>/dev/null || true
umount -l "$TARGET_MOUNT/proc" 2>/dev/null || true
umount -l "$TARGET_MOUNT/sys" 2>/dev/null || true
umount -l "$TARGET_MOUNT/boot" 2>/dev/null || true  # Unmount boot first
umount -l "$TARGET_MOUNT" 2>/dev/null || true       # Then root
echo "Arch Linux installation complete!"
