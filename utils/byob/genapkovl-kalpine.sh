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
# hacky way of knowing when to start counting boots #running on ram at first 
if mount | grep -E '/dev/[sh]d[a-z][0-9]' > /dev/null || mount | grep -E '/dev/nvme[0-9]n[0-9]p[0-9]' > /dev/null; then
  BC=$(cat "$count_file")
  NBC=$((BC+1))
  echo "$NBC" > "$count_file"
fi
EOF
chmod +x "$tmp"/etc/local.d/k2-bc.start
## Log bcs 
makefile root:root 0644 "$tmp"/etc/local.d/k2-bc-log.start <<'EOF'
#!/bin/sh
count_file="/etc/boot_c"
log_file="/etc/bc_log"
touch "$log_file"
BC=$(cat "$count_file")
echo "BC: ${BC} - $(date)" >> "$log_file"
EOF
chmod +x "$tmp"/etc/local.d/k2-bc-log.start
mkdir -p "$tmp"/etc/profile.d
makefile root:root 0644 "$tmp"/etc/profile.d/k2-instruct.sh <<'EOF'
#!/bin/sh
count_file="/etc/boot_c"
BC=$(cat "$count_file")
if [ "$BC" -eq 1 ]; then
  echo "Welcome again to K2_OS!"
  echo "Use '. /etc/setup-k2' to install desktop environment."
  echo "Then reboot again... Sorry."
fi
EOF
chmod +x "$tmp"/etc/profile.d/k2-instruct.sh
# if boot count is 0, then we are running on ramdisk
## K2 Setup pre-config # Folder already exists
# check minimum one boot so that no live installs, we here to stay.
makefile root:root 0644 "$tmp"/etc/setup-k2 <<'EOF'
#!/bin/sh
count_file="/etc/boot_c"
if [ -f "$count_file" ]; then
  BC=$(cat "$count_file")
  if [ "$BC" -lt 1 ]; then
    echo "Please run this after installing to disk and rebooting."
    exit 1
  fi
else
  echo "Boot count file not found. Please run this after installing to disk and rebooting."
  exit 1
fi
# continue with setup
echo "Setting up K2 for Alpine Linux..."
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
## motd for standard installing
makefile root:root 0644 "$tmp"/etc/motd <<EOF
Welcome to K2_OS!
Use "setup-alpine". Then reboot to hardisk.
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
#compress archive and add it as overlay
tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
