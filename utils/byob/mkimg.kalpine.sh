#!/bin/sh
export PROFILENAME=kalpine
#/scripts/mkimg.kalpine.sh
cat << EOF > ~/aports/scripts/mkimg.$PROFILENAME.sh
profile_$PROFILENAME() {
        profile_standard
        kernel_cmdline="unionfs_size=512M console=ttyS0,115200"
        syslinux_serial="0 115200"
        apks="\$apks alpine-base git"
        
        local _k _a
        for _k in \$kernel_flavors; do
                apks="\$apks linux-\$_k"
                for _a in \$kernel_addons; do
                        apks="\$apks \$_a-\$_k"
                done
        done
        apks="\$apks linux-firmware"
        
        # Include our custom overlay setup
        apkovl="genapkovl-kalpine.sh"
}
EOF
chmod +x ~/aports/scripts/mkimg.$PROFILENAME.sh

