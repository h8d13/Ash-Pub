#!/bin/sh
# Script for Arch installation # Assumes a couple of things: x86_64, and /dev/sdb
#### ALSO GPT / UEFI
set -e  # Exit on error


# Configuration variables
TARGET_DISK="/dev/sdb" ### VERY CAREFULY LSBLK TO CHECK 
TARGET_TIMEZONE="Europe/Paris" 
ROOT_PASSWORD="Everest" ### PLEASE CHANGE ME 
KB_LAYOUT=$(ls /etc/keymap/*.bmap.gz 2>/dev/null | head -1 | sed 's|/etc/keymap/||' | sed 's|\.bmap\.gz$||') 
TARGET_HOSTNAME=$(cat /etc/hostname)-arch
TARGET_USER=$(cat /etc/passwd | grep '/home/' | head -1 | cut -d: -f1)
SWAP_SIZE="4G" 
# Install required packages
echo "Installing required packages in Alpine..."
apk add wget curl zstd dosfstools arch-install-scripts parted
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
# Partitioning with three partitions: EFI, swap, and root
echo "Partitioning $TARGET_DISK..."
parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart primary fat32 1MiB 512MiB
parted -s "$TARGET_DISK" set 1 esp on
parted -s "$TARGET_DISK" mkpart primary linux-swap 512MiB 4.5GiB
parted -s "$TARGET_DISK" mkpart primary ext4 4.5GiB 100%
# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${TARGET_DISK}1"  # EFI partition
mkswap "${TARGET_DISK}2"        # Swap partition
swapon "${TARGET_DISK}2"        # Enable swap
mkfs.ext4 -F "${TARGET_DISK}3"  # Root partition
# Mount filesystems
echo "Mounting filesystems..."
mount "${TARGET_DISK}3" "$TARGET_MOUNT"       # Mount root
mkdir -p "$TARGET_MOUNT/boot/efi"
mount "${TARGET_DISK}1" "$TARGET_MOUNT/boot/efi"  # Mount EFI
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
chroot "$TARGET_MOUNT" /bin/bash -c "pacman -Sy base linux linux-firmware efibootmgr --noconfirm"
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
useradd -m -s /bin/bash -G wheel $TARGET_USER
echo "$TARGET_USER:$ROOT_PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Install GRUB and essentials
pacman -S --noconfirm grub grub-efi-x86_64 networkmanager base-devel sudo util-linux

# Enable NetworkManager & UFW stuff
systemctl enable NetworkManager

# Install GRUB to EFI partition
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH --recheck
# Generate GRUB configuration
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
umount -l "$TARGET_MOUNT/boot/efi" 2>/dev/null || true  # Unmount EFI first
umount -l "$TARGET_MOUNT" 2>/dev/null || true          # Then root
echo "Arch installation complete!"
