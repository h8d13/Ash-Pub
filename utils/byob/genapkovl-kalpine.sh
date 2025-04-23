#!/bin/sh -e
# genapkovl-kalpine.sh
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
    HOSTNAME="kalpine"
    echo "No hostname provided, using default: $HOSTNAME"
fi
cleanup() {
    rm -rf "$tmp"
}
makefile() {
    OWNER="$1"
    PERMS="$2"
    FILENAME="$3"
    cat > "$FILENAME"
    chown "$OWNER" "$FILENAME"
    chmod "$PERMS" "$FILENAME"
}
rc_add() {
    mkdir -p "$tmp"/etc/runlevels/"$2"
    ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}
mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
git
EOF
rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit
rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot
rc_add networking boot
rc_add local default
rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

# Create installation hook for setup-alpine
mkdir -p "$tmp"/etc/setup-hooks
makefile root:root 0755 "$tmp"/etc/setup-hooks/80-install-k2.sh <<EOF
#!/bin/sh
# This hook runs during the setup-alpine process 
# and directly installs K2 on the target system

# Get the target root directory from the environment
ROOT="\$ROOT"
if [ -z "\$ROOT" ]; then
    echo "ERROR: ROOT environment variable not set"
    exit 1
fi

# Install git to the target system
chroot "\$ROOT" apk add --no-cache git

# Create a temporary directory for the K2 installation
mkdir -p "\$ROOT/tmp/k2-install"
cd "\$ROOT/tmp/k2-install"

# Clone the K2 repository
git clone https://github.com/h8d13/k2-alpine .

# Make the setup script executable
chmod +x setup.sh

# Run the K2 setup script in the chroot environment
cp setup.sh "\$ROOT/tmp/"
chroot "\$ROOT" /tmp/setup.sh

# Clean up
rm -f "\$ROOT/tmp/setup.sh"
cd /
rm -rf "\$ROOT/tmp/k2-install"

# Add a message about K2 being installed
mkdir -p "\$ROOT/etc/motd.d"
cat > "\$ROOT/etc/motd.d/k2-installed.motd" <<MOTD
K2 has been successfully installed on this system.
MOTD
EOF

tar -c -C "$tmp" etc usr | gzip -9n > $HOSTNAME.apkovl.tar.gz
