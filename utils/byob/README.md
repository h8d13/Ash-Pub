# Bring Your Own Booze
> Create your own ISOs and collaborate on K2. Instead of "recreating the wheel" steal all the beautiful code and add to it to make a Lambo. 

[AlpineWiki](https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage)

Follow the initial steps for prereqs. 

Make sure to use the build profile and use `chmod 777` on a files that are causing issues if you started from your personal env.

```
git clone https://gitlab.alpinelinux.org/alpine/aports.git
git clone https://gitlab.alpinelinux.org/alpine/alpine-conf.git
```

Follow the instruction in the wiki for temp.
Also as build user `mkdir -p out`

![image](https://github.com/user-attachments/assets/2ba8cf03-bda6-4289-b6b9-c389957844d2)

Explore the dirs a little. They contain 90% of what you'll need. 
Here are some key things to look for:
```
aports/scripts/genapkovl-dhcp.sh
```

### Attempt 001 
Create an example profile:
`touch mkimg.calpine.sh`

```
/bin, /sbin, /usr/bin, /usr/sbin, and /usr/local/bin is:

/bin and /usr/bin: For essential user commands (used by both normal users and system administrators)
/sbin and /usr/sbin: For system administration commands (primarily used by root)
/usr/local/bin: For locally installed commands that aren't part of the base system
```

Example file content:
```
#!/bin/sh
# Based on genapkovl-dhcp.sh
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp"/usr/local/bin

cat > "$tmp"/usr/local/bin/setup-k2 << 'EOF'
#!/bin/sh
echo "Setting up K2 for Alpine Linux 3.21..."
apk add --quiet --no-progress --no-cache git 
echo "Clone then move"
git clone https://github.com/h8d13/k2-alpine && cd k2-alpine
echo "Make exec."
chmod +x setup.sh
echo "Ready."
./setup.sh
cd ..
echo "Cleaning up."
rm -rf k2-alpine
echo "K2 setup complete!"
EOF

chmod +x "$tmp"/usr/local/bin/setup-k2

tar -c -C "$tmp" etc usr | gzip -9n > $HOSTNAME.apkovl.tar.gz
```

Here the apkovl specifies a script to append. 

Defined here in our profile:

```
#!/bin/sh
profile_calpine() {
    profile_standard
    kernel_cmdline="unionfs_size=512M console=tty0 console=ttyS0,115200"
    syslinux_serial="0 115200"
    local _k _a
    for _k in $kernel_flavors; do
            apks="$apks linux-$_k"
            for _a in $kernel_addons; do
                    apks="$apks $_a-$_k"
            done
    done
    apks="$apks linux-firmware wpa_supplicant"
    apkovl="genapkovl-calpine.sh"
}
```

Little hack you can `set -x` int he `mkimage.sh` to get verbose outputs. 

Make sure heredocs `EOF` are expanded do not use `'EOF'`

```
./mkimage.sh --profile calpine --outdir ~/out --repository https://dl-cdn.alpinelinux.org/latest-stable/main --arch x86_64
```

Example launch command for building.

IMPORTANT:

![image](https://github.com/user-attachments/assets/8f1480fa-a5af-4431-9e5e-011157f92061)

Make sure to properly eject using this little menu. For example when devices are still wrtiting files this will avoid corruption. See above.
