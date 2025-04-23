#!/bin/sh -e
#/scrips/genapkovl-k2alpine.sh
HOSTNAME="k2alpine"

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

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
EOF

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add networking boot
rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown


# Create setup-k2 script
mkdir -p "$tmp"/usr/local/bin
makefile root:root 0755 "$tmp"/usr/local/bin/setup-k2 <<'EOF'
#!/bin/sh
# Detect environment and act accordingly
if mount | grep -q "overlay on / "; then
    # We're in the live environment
    echo "Live environment detected. Setting up K2 for Alpine Linux..."
    
    # Install git if not already installed
    apk add --quiet --no-progress --no-cache git
    
    # Find out if we're running post-installation
    if [ -d /mnt ]; then
        # Installation path - copy this script to the installed system
        echo "Alpine installation detected. Installing setup-k2 to the new system..."
        mkdir -p /mnt/usr/local/bin
        cp /usr/local/bin/setup-k2 /mnt/usr/local/bin/
        chmod +x /mnt/usr/local/bin/setup-k2
        
        # Also copy welcome message
        mkdir -p /mnt/etc/motd.d
        cp /etc/motd.d/k2-welcome /mnt/etc/motd.d/
        
        echo "K2 setup script installed to the new system."
        echo "After booting into your new system, run 'setup-k2' to complete K2 setup."
    else
        # Not in installation - maybe user wants to install K2 in the live environment
        echo "Would you like to install K2 in this live environment? (y/n)"
        read answer
        if [ "$answer" = "y" ]; then
            echo "Installing K2 in the live environment..."
            git clone https://github.com/h8d13/k2-alpine && cd k2-alpine
            chmod +x setup.sh
            ./setup.sh
            cd ..
            rm -rf k2-alpine
            echo "K2 installed in live environment. Note that changes will be lost on reboot."
        else
            echo "K2 installation skipped. Run setup-k2 after installing Alpine to disk."
        fi
    fi
else
    # We're in an installed system
    echo "Running K2 setup in installed system..."
    apk add --quiet --no-progress --no-cache git
    git clone https://github.com/h8d13/k2-alpine && cd k2-alpine
    chmod +x setup.sh
    ./setup.sh
    cd ..
    rm -rf k2-alpine
    echo "K2 setup complete! Please reboot your system."
fi
EOF

# Create a setup-alpine hook to copy our files during installation
mkdir -p "$tmp"/etc/setup-hooks
makefile root:root 0755 "$tmp"/etc/setup-hooks/10-k2-installer.sh <<'EOF'
#!/bin/sh
# This hook runs during Alpine installation
if [ "$STAGE" = "post-install" ]; then
    echo "K2-Alpine: Installing setup scripts to new system..."
    mkdir -p "$ROOT/usr/local/bin"
    cp /usr/local/bin/setup-k2 "$ROOT/usr/local/bin/"
    chmod +x "$ROOT/usr/local/bin/setup-k2"
    
    # Copy welcome message
    mkdir -p "$ROOT/etc/motd.d"
    cp /etc/motd.d/k2-welcome "$ROOT/etc/motd.d/"
    
    echo "K2-Alpine: Setup ready. After boot, run 'setup-k2'."
fi
EOF

# Create a boot message to inform user about setup-k2
mkdir -p "$tmp"/etc/motd.d
makefile root:root 0644 "$tmp"/etc/motd.d/k2-welcome <<EOF
========================================================
  Welcome to K2-Alpine Linux!
  
  Run 'setup-k2' to complete K2 installation
========================================================

EOF

# Build the overlay tarball
tar -c -C "$tmp" etc usr | gzip -9n
