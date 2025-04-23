#!/bin/sh -e
#/scripts/genapkovl-k2alpine.sh
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

HOSTNAME="k2alpine"

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

# Base config
mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
EOF

# Services
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

# setup-k2 script
mkdir -p "$tmp"/usr/local/bin
makefile root:root 0755 "$tmp"/usr/local/bin/setup-k2 <<'EOF'
#!/bin/sh
# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo "Git not found, installing..."
    apk update
    apk add --no-cache git
fi

echo "Running K2 setup..."

git clone https://github.com/h8d13/k2-alpine && cd k2-alpine
chmod +x setup.sh
./setup.sh
cd ..
rm -rf k2-alpine

echo "K2 setup complete. You may reboot."
EOF
# Auto-run setup-k2 on first boot (once)
mkdir -p "$tmp"/etc/local.d
makefile root:root 0755 "$tmp"/etc/local.d/setup-k2-onboot.start <<'EOF'
#!/bin/sh
/usr/local/bin/setup-k2
rc-update del local
rm -f /etc/local.d/setup-k2-onboot.start
EOF
# Enable local service
mkdir -p "$tmp"/etc/runlevels/default
ln -sf /etc/init.d/local "$tmp"/etc/runlevels/default/local
# Tarball output
tar -c -C "$tmp" etc usr | gzip -9n
EOF
