#!/bin/sh -e

HOSTNAME="k2-alp"

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

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF
## Remove this network part so that the user is prompted to config.
mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
git
EOF
## K2 Setup pre-config
mkdir -p "$tmp"/etc/setup-k2.sh
cat > "$tmp"/etc/setup-k2.sh <<EOF
#!/bin/sh
echo "Setting up K2 for Alpine Linux 3.21..."
apk add --no-cache git 
echo "Cloning then move..."
git clone https://github.com/h8d13/k2-alpine && cd k2-alpine
echo "Making exec..."
chmod +x setup.sh
echo "Ready. Set. Go!"
./setup.sh
cd ..
echo "Cleaning up."
rm -rf k2-alpine
echo "K2 setup complete!"
EOF
# give to root
makefile root:root 0644 "$tmp"/etc/setup-k2.sh
chmod +x "$tmp"/etc/setup-k2.sh
## motd for installing
makefile root:root 0644 "$tmp"/etc/motd <<EOF
Welcome to K2_OS!
Use setup-alpine. Then reboot.
To install K2 after reboot: ./etc/setup-k2.sh
EOF
## init/boot/shutdown
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
rc_add git boot
rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
