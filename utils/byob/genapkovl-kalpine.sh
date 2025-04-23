#!/bin/sh
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

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF

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
rc add git boot
rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz

mkdir -p "$tmp"/sbin/
cat > "$tmp"/sbin/setup-alpine << EOF
PROGRAM=setup-alpine
VERSION=@VERSION@

PREFIX=@PREFIX@
: ${LIBDIR=$PREFIX/lib}
. "$LIBDIR/libalpine.sh"

if [ -t 1 ]; then
	COLCYAN="\e[36m"
	COLWHITE="\e[97m"
	COLRESET="\e[0m"
else
	COLCYAN=""
	COLWHITE=""
	COLRESET=""
fi

print_heading1() {
	printf "${COLCYAN}%s${COLRESET}\n" "$1"
}

print_heading2() {
    printf "${COLWHITE}%s${COLRESET}\n" "$1"
}

is_kvm_clock() {
	grep -q "kvm-clock"  "$ROOT"sys/devices/system/clocksource/clocksource0/current_clocksource 2>/dev/null
}

is_virtual_console() {
	case "$(readlink "$ROOT"/proc/self/fd/0)" in
		/dev/tty[0-9]*) return 0;;
	esac
	return 1
}

usage() {
	cat <<-__EOF__
		usage: setup-alpine [-ahq] [-c FILE | -f FILE]
		Setup Alpine Linux
		options:
		 -a  Create Alpine Linux overlay file
		 -c  Create answer file (do not install anything)
		 -e  Empty root password
		 -f  Answer file to use installation
		 -h  Show this help
		 -q  Quick mode. Ask fewer questions.
	__EOF__
	exit $1
}

while getopts "aef:c:hq" opt ; do
	case $opt in
		a) ARCHIVE=yes;;
		f) USEANSWERFILE="$OPTARG";;
		c) CREATEANSWERFILE="$OPTARG";;
		e) empty_root_password=1;;
		h) usage 0;;
		q) empty_root_password=1; quick=1; APKREPOSOPTS="-1"; HOSTNAMEOPTS="alpine";;
		'?') usage "1" >&2;;
	esac
done
shift $(expr $OPTIND - 1)

rc_sys=$(openrc --sys)
# mount xenfs so we can detect xen dom0
if [ "$rc_sys" = "XENU" ] && ! grep -q '^xenfs' /proc/mounts; then
	modprobe xenfs
	mount -t xenfs xenfs /proc/xen
fi

case "$USEANSWERFILE" in
	http*://*|ftp://*)
		# dynamically download answer file from URL (supports HTTP(S) and FTP)
		# ensure the network is up, otherwise setup a temporary interface config
		if ! rc-service networking --quiet status; then
			setup-interfaces -ar
		fi

		temp="$(mktemp)"
		wget -qO "$temp" "$USEANSWERFILE" || die "Failed to download '$USEANSWERFILE'"
		USEANSWERFILE="$temp"
		;;
	*)
		[ -n "$USEANSWERFILE" ] && USEANSWERFILE=$(realpath "$USEANSWERFILE")
		;;
esac
if [ -n "$USEANSWERFILE" ] && [ -e "$USEANSWERFILE" ]; then
	. "$USEANSWERFILE"
fi

if [ -n "$CREATEANSWERFILE" ]; then
	touch "$CREATEANSWERFILE" || echo "Cannot touch file $CREATEANSWERFILE"
	cat > "$CREATEANSWERFILE" <<-__EOF__
		# Example answer file for setup-alpine script
		# If you don't want to use a certain option, then comment it out
		# Use US layout with US variant
		# KEYMAPOPTS="us us"
		KEYMAPOPTS=none
		# Set hostname to 'alpine'
		HOSTNAMEOPTS=alpine
		# Set device manager to mdev
		DEVDOPTS=mdev
		# Contents of /etc/network/interfaces
		INTERFACESOPTS="auto lo
		iface lo inet loopback
		auto eth0
		iface eth0 inet dhcp
		hostname alpine-test
		"
		# Search domain of example.com, Google public nameserver
		# DNSOPTS="-d example.com 8.8.8.8"
		# Set timezone to UTC
		#TIMEZONEOPTS="UTC"
		TIMEZONEOPTS=none
		# set http/ftp proxy
		#PROXYOPTS="http://webproxy:8080"
		PROXYOPTS=none
		# Add first mirror (CDN)
		APKREPOSOPTS="-1"
		# Create admin user
		USEROPTS="-a -u -g audio,input,video,netdev juser"
		#USERSSHKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIiHcbg/7ytfLFHUNLRgEAubFz/13SwXBOM/05GNZe4 juser@example.com"
		#USERSSHKEY="https://example.com/juser.keys"
		# Install Openssh
		SSHDOPTS=openssh
		#ROOTSSHKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIiHcbg/7ytfLFHUNLRgEAubFz/13SwXBOM/05GNZe4 juser@example.com"
		#ROOTSSHKEY="https://example.com/juser.keys"
		# Use openntpd
		# NTPOPTS="openntpd"
		NTPOPTS=none
		# Use /dev/sda as a sys disk
		# DISKOPTS="-m sys /dev/sda"
		DISKOPTS=none
		# Setup storage with label APKOVL for config storage
		#LBUOPTS="LABEL=APKOVL"
		LBUOPTS=none
		#APKCACHEOPTS="/media/LABEL=APKOVL/cache"
		APKCACHEOPTS=none
	__EOF__
	echo "Answer file $CREATEANSWERFILE has been created.  Please add or remove options as desired in that file"
	exit 0
fi

printf "\n\n"
print_heading1 " ALPINE LINUX INSTALL K2"
print_heading1 "----------------------"

if [ "$ARCHIVE" ] ; then
	echo "Creating an Alpine overlay"
	init_tmpdir ROOT
else
	PKGADD="apk add"
fi

# set keymap
if [ "$rc_sys" != LXC ]; then
	if is_virtual_console || [ -n "$KEYMAPOPTS" ]; then
		echo
		print_heading2 " Keymap"
		print_heading2 "--------"
		setup-keymap ${KEYMAPOPTS}
	fi
	# set hostname
	echo
	print_heading2 " Hostname"
	print_heading2 "----------"
	setup-hostname ${HOSTNAMEOPTS} && [ -z "$SSH_CONNECTION" ] && rc-service hostname --quiet restart
	setup-devd -C mdev # just to bootstrap
fi

# set Interface
[ -z "$SSH_CONNECTION" ] && rst_if=1
if [ -n "$INTERFACESOPTS" ]; then
	if [ "$INTERFACESOPTS" != none ]; then
		printf "$INTERFACESOPTS" | setup-interfaces -i ${rst_if:+-r}
	fi
else
	echo
	print_heading2 " Interfaces"
	print_heading2 "-----------"
	setup-interfaces -i ${quick:+-a} ${rst_if:+-r} ## Force interactive if not SSH 
fi

# setup up dns if no dhcp was configured
if [ -f "$ROOT"/etc/network/interfaces ] && ! grep -q '^iface.*dhcp' "$ROOT"/etc/network/interfaces; then
	setup-dns ${DNSOPTS}
fi

# set root password
if [ -z "$empty_root_password" ]; then
	echo
	print_heading2 " Root Password"
	print_heading2 "---------------"
	while ! $MOCK passwd ; do
		echo "Please retry."
	done
fi

# pick timezone
if [ -z "$quick" ]; then
	echo
	print_heading2 " Timezones"
	print_heading2 "----------"
	setup-timezone ${TIMEZONEOPTS}
fi

echo
rc-update --quiet add networking boot
rc-update --quiet add seedrng boot || rc-update --quiet add urandom boot
svc_list="cron crond"
if [ -e /dev/input/event0 ]; then
	# Only enable acpid for systems with input events entries
	# https://gitlab.alpinelinux.org/alpine/aports/-/issues/12290
	svc_list="$svc_list acpid"
fi
for svc in $svc_list; do
	if rc-service --exists $svc; then
		rc-update --quiet add $svc
	fi
done

# start up the services
$MOCK openrc ${SSH_CONNECTION:+-n} boot
$MOCK openrc ${SSH_CONNECTION:+-n} default

# update /etc/hosts - after we have got dhcp address
# Get default fully qualified domain name from *first* domain
# given on *last* search or domain statement.
_dn=$(sed -n \
-e '/^domain[[:space:]][[:space:]]*/{s///;s/\([^[:space:]]*\).*$/\1/;h;}' \
-e '/^search[[:space:]][[:space:]]*/{s///;s/\([^[:space:]]*\).*$/\1/;h;}' \
-e '${g;p;}' "$ROOT"/etc/resolv.conf 2>/dev/null)

_hn=$(hostname)
_hn=${_hn%%.*}

sed -i -e "s/^127\.0\.0\.1.*/127.0.0.1\t${_hn}.${_dn:-$(get_fqdn my.domain)} ${_hn} localhost.localdomain localhost/" \
	"$ROOT"/etc/hosts 2>/dev/null

if [ -z "$quick" ]; then
	echo
	print_heading2 " Proxies"
	print_heading2 "-------"
	setup-proxy -q ${PROXYOPTS}
fi
# activate the proxy if configured
if [ -r "$ROOT/etc/profile" ]; then
	. "$ROOT/etc/profile"
fi

if ! is_kvm_clock && [ "$rc_sys" != "LXC" ] && [ "$quick" != 1 ]; then
	echo
	print_heading2 " Network Time Protocol"
	print_heading2 "-----------------------"
	setup-ntp ${NTPOPTS}
fi

echo
print_heading2 " APK Mirrors"
print_heading2 "------------"
setup-apkrepos ${APKREPOSOPTS}

# Now that network and apk are operational we can install another device manager
if [ "$rc_sys" != LXC ] && [ -n "$DEVDOPTS" -a "$DEVDOPTS" != mdev ]; then
	setup-devd ${DEVDOPTS}
fi

# lets stop here if in "quick mode"
if [ "$quick" = 1 ]; then
	exit 0
fi

echo "Adding git..."
echo "Setting up K2 for Alpine Linux..."
apk add --no-cache git
git clone https://github.com/h8d13/k2-alpine
cd k2-alpine
chmod +x setup.sh
./setup.sh
cd ..
rm -rf k2-alpine
echo "K2 setup complete!"

echo
print_heading2 " User (Recommended)"
print_heading2 "------------------"
setup-user ${USERSSHKEY+-k "$USERSSHKEY"} ${USEROPTS:--a -g 'audio input video netdev'}
for i in "$ROOT"home/*; do
	if [ -d "$i" ]; then
		lbu add $i
	fi
done

setup-sshd ${ROOTSSHKEY+-k "$ROOTSSHKEY"} ${SSHDOPTS}
root_keys="$ROOT"/root/.ssh/authorized_keys
if [ -f "$root_keys" ]; then
	lbu add "$ROOT"/root
fi

if is_xen_dom0; then
	echo
	print_heading2 " Xen"
	print_heading2 "-----"
	setup-xen-dom0 ${XENDOM0OPTS}
fi

if [ "$rc_sys" = "LXC" ]; then
	exit 0
fi

echo
print_heading2 " Disk & Install"
print_heading2 "----------------"
DEFAULT_DISK=none \
	setup-disk -w /tmp/alpine-install-diskmode.out -q ${DISKOPTS} || exit

diskmode=$(cat /tmp/alpine-install-diskmode.out 2>/dev/null)

# setup lbu and apk cache unless installed sys on disk
if [ "$diskmode" != "sys" ]; then
	setup-lbu ${LBUOPTS}
	setup-apkcache ${APKCACHEOPTS}
	if [ -L "$ROOT"/etc/apk/cache ]; then
		apk cache sync
	fi
fi
EOF
chmod +x "$tmp"/sbin/setup-alpine

