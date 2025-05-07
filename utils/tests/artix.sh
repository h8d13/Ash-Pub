#!/bin/sh
## Artix RC Implementation for auto install from base rc iso. 
TARGET_DISK="/dev/sdb"
TARGET_TIMEZONE="Europe/Paris"
ROOT_PASSWORD="Everest"
KB_LAYOUT="be"
TARGET_HOSTNAME="kartix"
TARGET_USER="hadean"
SWAP_SIZE="4G"
TARGET_MOUNT="/mnt"

# Partitioning with three partitions: EFI, swap, and root
echo "Partitioning $TARGET_DISK..."
echo "o" | fdisk "$TARGET_DISK"
echo "n" | fdisk "$TARGET_DISK"
echo "p" | fdisk "$TARGET_DISK"
echo "1" | fdisk "$TARGET_DISK"
echo "2048" | fdisk "$TARGET_DISK"
echo "+512M" | fdisk "$TARGET_DISK"
echo "t" | fdisk "$TARGET_DISK"
echo "1" | fdisk "$TARGET_DISK"
echo "1" | fdisk "$TARGET_DISK"
echo "n" | fdisk "$TARGET_DISK"
echo "p" | fdisk "$TARGET_DISK"
echo "2" | fdisk "$TARGET_DISK"
echo "+512M" | fdisk "$TARGET_DISK"
echo "+$(( ${SWAP_SIZE/G/} * 1024 ))M" | fdisk "$TARGET_DISK"
echo "t" | fdisk "$TARGET_DISK"
echo "2" | fdisk "$TARGET_DISK"
echo "19" | fdisk "$TARGET_DISK"
echo "n" | fdisk "$TARGET_DISK"
echo "p" | fdisk "$TARGET_DISK"
echo "3" | fdisk "$TARGET_DISK"
echo "+$(( ${SWAP_SIZE/G/} * 1024 + 512 ))M" | fdisk "$TARGET_DISK"
echo "" | fdisk "$TARGET_DISK"
echo "w" | fdisk "$TARGET_DISK"

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

# Configure mirror
echo "Configuring pacman..."
echo 'Server = https://mirrors.artixlinux.org/$repo/os/$arch' > "$TARGET_MOUNT/etc/pacman.d/mirrorlist"

# Configure chroot
echo "Configuring chroot..."
mount -t proc /proc "$TARGET_MOUNT/proc"
mount -t sysfs /sys "$TARGET_MOUNT/sys"
mount -o bind /dev "$TARGET_MOUNT/dev"
mount -o bind /dev/pts "$TARGET_MOUNT/dev/pts"

# Initialize pacman
echo "Initializing pacman..."
chroot "$TARGET_MOUNT" /bin/bash -c "pacman-key --init && pacman-key --populate artix"

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
pacman -S --noconfirm grub grub-efi-x86_64 networkmanager sudo util-linux

# Configure network
echo "Configuring network..."
pacman -S --noconfirm networkmanager
rc-service NetworkManager start
rc-update add NetworkManager default
# Install GRUB to EFI partition
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARTIX --recheck
# Generate GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg
EOF
chmod +x "$TARGET_MOUNT/configure.sh"
chroot "$TARGET_MOUNT" /configure.sh

echo "Done!"
