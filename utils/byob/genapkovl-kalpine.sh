#!/bin/sh -e
#/scripts/genapkovl-kalpine.sh
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
    echo "usage: $0 hostname"
    exit 1
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

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
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

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

# Setup the K2 installation after reboot
mkdir -p "$tmp"/usr/local/bin
makefile root:root 0755 "$tmp"/usr/local/bin/setup-k2 <<EOF
#!/bin/sh
# K2 setup script to be run after reboot

# Check if K2 setup is already done
if [ -f /etc/k2-setup-done ]; then
    echo "K2 setup already completed."
    exit 0
fi

# Install git if not already installed
apk add --no-cache git

# Clone K2 repo and run the setup
git clone https://github.com/h8d13/k2-alpine && cd k2-alpine
chmod +x setup.sh
./setup.sh
cd ..
rm -rf k2-alpine

# Mark the setup as done
touch /etc/k2-setup-done
EOF

# Create a setup hook for post-installation
mkdir -p "$tmp"/etc/setup-hooks
makefile root:root 0755 "$tmp"/etc/setup-hooks/10-k2-installer.sh <<EOF
#!/bin/sh
# This hook runs after the first boot

if [ ! -f /etc/k2-setup-done ]; then
    echo "Running K2 setup..."
    /usr/local/bin/setup-k2
fi
EOF

tar -c -C "$tmp" etc usr | gzip -9n > $HOSTNAME.apkovl.tar.gz
