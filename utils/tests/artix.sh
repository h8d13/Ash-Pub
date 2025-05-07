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

# Partitioning with fdisk
echo "Partitioning $TARGET_DISK using fdisk..."
(
echo o       # Create a new empty DOS partition table
echo n       # New partition
echo p       # Primary partition
echo 1       # Partition number 1 (EFI)
echo          # Default: start at beginning of disk
echo +512M   # Size: 512MB
echo t       # Change partition type
echo 1       # Type: EFI System
echo n       # New partition
echo p       # Primary partition
echo 2       # Partition number 2 (Swap)
echo          # Default: start immediately after previous partition
echo +$(( ${SWAP_SIZE/G/} * 1024 ))M  # Size: swap size
echo t       # Change partition type
echo 2       # Select partition 2
echo 19      # Type: Linux swap
echo n       # New partition
echo p       # Primary partition
echo 3       # Partition number 3 (Root)
echo          # Default: start immediately after previous partition
echo          # Default: extend to end of disk
echo w       # Write changes
) | fdisk "$TARGET_DISK"

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

# Install GRUB and OpenRC essentials
pacman -S --noconfirm grub grub-efi-x86_64 networkmanager openrc util-linux

# Configure OpenRC services
echo "Configuring OpenRC services..."
rc-update add elogind boot
rc-update add udev sysinit
rc-update add dbus default
rc-update add cronie default
rc-update add NetworkManager default

# Install GRUB to EFI partition
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARTIX --recheck

# Generate GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg
EOF

chmod +x "$TARGET_MOUNT/configure.sh"
chroot "$TARGET_MOUNT" /configure.sh

echo "Done!"
