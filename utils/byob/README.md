# Bring Your Own Booze
> Create your own ISOs and collaborate on K2. Instead of "recreating the wheel" steal all the beautiful code and add to it to make a Lambo. 

[AlpineWiki-CreateYourIso](https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage)

Follow the initial steps for prereqs. 
> This is a good practice in general, as it will make your paths cleaners, permissions, etc.
> Create a user give it permissions, got clone to /home/user root

You can also `apk add gnome-disk-utils` as it's a good program quick formatting. 

export PROFILENAME=calpine

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
    apks="$apks linux-firmware"
    apkovl="genapkovl-calpine.sh"
}
```

Little hack you can `set -x` int he `mkimage.sh` to get verbose outputs. 

Make sure heredocs `EOF` are expanded do not use `'EOF'`

```
./mkimage.sh --profile calpine --outdir ~/out --repository https://dl-cdn.alpinelinux.org/latest-stable/main --arch x86_64 --hostkeys
```

Example launch command for building. Will not work if perms are wrong or key not gen'd.

Check you are on right profile `whoami`

You can also add --simulate but I've found it to just return silent errors this is more useful for debug: `set -x` at the beginning of mkimg.sh                                                                                                                                                                                                                                                                                                                                                                                                                         > Notes: Naming needs to be consistent as the final tar archive is what gets appended is kept post-install (setup-alpine). 

IMPORTANT:

![image](https://github.com/user-attachments/assets/8f1480fa-a5af-4431-9e5e-011157f92061)

Make sure to properly eject using this little menu. For example when devices are still wrtiting files this will avoid corruption. See above.

[WikipediaLubburnia](https://en.wikipedia.org/wiki/Libburnia) 
[Xorriso-Libburnia](https://dev.lovelyhq.com/libburnia/web/wiki#news)
[GentooRC](https://wiki.alpinelinux.org/wiki/Writing_Init_Scripts) 
[AlpineRC](https://wiki.gentoo.org/wiki/Handbook:X86/Working/Initscripts#Writing_initscripts)
[RC Docs](https://github.com/OpenRC/openrc/blob/master/service-script-guide.md)

---

"Coffee stained teeth, the gods want blood, may they be merciful" 
