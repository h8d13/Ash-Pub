#!/bin/sh -e
#/home/build/aports/scripts/genapkovl-kalpine.sh
HOSTNAME="kalpine"

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
trap cleanup exit
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
mkdir -p "$tmp"/etc/local.d
## Increment
makefile root:root 0644 "$tmp"/etc/local.d/k2-bc.start <<'EOF'
#!/bin/sh
count_file="/etc/boot_c"
if [ ! -f "$count_file" ]; then
  echo "0" > "$count_file"
fi
BC=$(cat "$count_file")
NBC=$((BC+1))
echo "$NBC" > "$count_file"
EOF
chmod +x "$tmp"/etc/local.d/k2-bc.start
## Log bcs 
makefile root:root 0644 "$tmp"/etc/local.d/k2-bc-log.start <<'EOF'
#!/bin/sh
count_file="/etc/boot_c"
log_file="/var/log/bc_log"
touch "$log_file"
BC=$(cat "$count_file")
echo "BC: $BC - $(date) - ${USER:-system} - PID:$$" >> "$log_file"
if [ "$BC" = "1" ]; then
  echo "SYSTEM READY FOR SETUP" >> "$log_file"
fi
EOF
chmod +x "$tmp"/etc/local.d/k2-bc-log.start
## K2 Setup pre-config # Folder already exists
makefile root:root 0644 "$tmp"/etc/setup-k2 <<'EOF'
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
chmod +x "$tmp"/etc/setup-k2
## motd for installing
makefile root:root 0644 "$tmp"/etc/motd <<EOF
Welcome to K2_OS!
Use "setup-alpine". Then reboot to hardisk.
To install DE: ". /etc/setup-k2"
Love <3 H8D13.
EOF
## init/boot/shutdown/default
rc_add local default
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
rc_add networking boot
rc_add syslog boot
rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
