#!/bin/sh
#export PROFILENAME=k2alpine
#/scripts/mkimg.k2akpine.sh

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
        apkovl="aports/scripts/genapkovl-k2alpine.sh"
}
EOF

chmod +x ~/aports/scripts/mkimg.$PROFILENAME.sh


# ./mkimage.sh --profile k2alpine --outdir ~/out --repository https://dl-cdn.alpinelinux.org/latest-stable/main --arch x86_64 --hostkey
