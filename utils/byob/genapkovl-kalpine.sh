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

# Setup the K2 installation after reboot
mkdir -p "$tmp"/usr/local/bin
makefile root:root 0755 "$tmp"/usr/local/bin/setup-k2 <<EOF
#!/bin/sh
# K2 setup script
# Check if K2 setup is already done
if [ -f /etc/k2-setup-done ]; then
    echo "K2 setup already completed."
    exit 0
fi
# Clone K2 repo and run the setup
git clone https://github.com/h8d13/k2-alpine && cd k2-alpine
chmod +x setup.sh
./setup.sh
cd ..
rm -rf k2-alpine
# Mark the setup as done
touch /etc/k2-setup-done
EOF

# Create a local.d script to run at boot
mkdir -p "$tmp"/etc/local.d
makefile root:root 0755 "$tmp"/etc/local.d/k2-setup.start <<EOF
#!/bin/sh
/usr/local/bin/setup-k2
EOF

# Create installation hook for setup-alpine
mkdir -p "$tmp"/etc/setup-hooks
makefile root:root 0755 "$tmp"/etc/setup-hooks/50-install-k2.sh <<EOF
#!/bin/sh
# This hook runs during the setup-alpine process 
# and ensures that git and setup-k2 are installed on the target system

# Get the target root directory from the environment
ROOT="\$ROOT"
if [ -z "\$ROOT" ]; then
    echo "ERROR: ROOT environment variable not set"
    exit 1
fi

# Install git to the target system
chroot "\$ROOT" apk add --no-cache git

# Copy our setup script to the target system
mkdir -p "\$ROOT/usr/local/bin"
cat > "\$ROOT/usr/local/bin/setup-k2" <<'SETUPSCRIPT'
#!/bin/sh
# K2 setup script
# Check if K2 setup is already done
if [ -f /etc/k2-setup-done ]; then
    echo "K2 setup already completed."
    exit 0
fi
# Clone K2 repo and run the setup
git clone https://github.com/h8d13/k2-alpine && cd k2-alpine
chmod +x setup.sh
./setup.sh
cd ..
rm -rf k2-alpine
# Mark the setup as done
touch /etc/k2-setup-done
SETUPSCRIPT

# Make the script executable
chmod 755 "\$ROOT/usr/local/bin/setup-k2"

# Create a local.d startup script to run at boot
mkdir -p "\$ROOT/etc/local.d"
cat > "\$ROOT/etc/local.d/k2-setup.start" <<'STARTSCRIPT'
#!/bin/sh
/usr/local/bin/setup-k2
STARTSCRIPT
chmod 755 "\$ROOT/etc/local.d/k2-setup.start"

# Make sure local service is enabled
ln -sf /etc/init.d/local "\$ROOT/etc/runlevels/default/local"

# Add a firstboot message
mkdir -p "\$ROOT/etc/motd.d"
cat > "\$ROOT/etc/motd.d/k2-setup.motd" <<EOF
K2 setup will run automatically on first boot.
You can also run it manually with: setup-k2
EOF
EOF

tar -c -C "$tmp" etc usr | gzip -9n > $HOSTNAME.apkovl.tar.gz
