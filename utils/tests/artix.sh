#!/bin/bash
## Artix RC Implementation for auto install from base RC ISO. 

TARGET_DISK="/dev/sda"
TARGET_TIMEZONE="Europe/Paris"
ROOT_PASSWORD="Everest"
KB_LAYOUT="be"
TARGET_HOSTNAME="kartix"
TARGET_USER="hadean"
SWAP_SIZE="4G"
TARGET_MOUNT="/mnt"

# Ensure the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Check if the target disk exists
if [ ! -b "$TARGET_DISK" ]; then
    echo "Error: Target disk $TARGET_DISK does not exist."
    exit 1
fi

# Unmount any mounted partitions on the target disk
echo "Unmounting any mounted partitions on $TARGET_DISK..."
umount "${TARGET_DISK}"* 2>/dev/null || true

# Clear the partition table
echo "Clearing the partition table on $TARGET_DISK..."
wipefs -a "$TARGET_DISK"
dd if=/dev/zero of="$TARGET_DISK" bs=512 count=1

# Partitioning with three partitions: EFI, swap, and root
echo "Partitioning $TARGET_DISK..."
parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart primary fat32 1MiB 513MiB
parted -s "$TARGET_DISK" set 1 esp on
parted -s "$TARGET_DISK" mkpart primary linux-swap 513MiB $((513 + ${SWAP_SIZE/G/} * 1024))MiB
parted -s "$TARGET_DISK" mkpart primary ext4 $((513 + ${SWAP_SIZE/G/} * 1024))MiB 100%

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${TARGET_DISK}1"  # EFI partition
mkswap "${TARGET_DISK}2"         # Swap partition
swapon "${TARGET_DISK}2"         # Enable swap
mkfs.ext4 -F "${TARGET_DISK}3"   # Root partition

# Mount filesystems
echo "Mounting filesystems..."
mount "${TARGET_DISK}3" "$TARGET_MOUNT"       # Mount root
mkdir -p "$TARGET_MOUNT/boot/efi"
mount "${TARGET_DISK}1" "$TARGET_MOUNT/boot/efi"  # Mount EFI

# Configure mirror
echo "Configuring pacman..."
mkdir -p "$TARGET_MOUNT/etc/pacman.d"
echo 'Server = https://mirrors.artixlinux.org/$repo/os/$arch' > "$TARGET_MOUNT/etc/pacman.d/mirrorlist"

# Configure chroot environment
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
