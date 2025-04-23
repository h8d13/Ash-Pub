# mkimg.kalpine.sh
profile_kalpine() {
    profile_standard
    kernel_cmdline="unionfs_size=512M console=ttyS0,115200"
    syslinux_serial="0 115200"
    apks="$apks alpine-base git"
    boot_addons="amd-ucode intel-ucode"
	initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"
    local _k _a
    for _k in $kernel_flavors; do
            apks="$apks linux-$_k"
            for _a in $kernel_addons; do
                    apks="$apks $_a-$_k"
            done
    done
    apkovl="aports/scripts/genapkovl-kalpine.sh"
}

