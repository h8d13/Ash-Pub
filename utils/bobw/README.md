# Best of Both Worlds

This section is to create a double boot with Alpine as host and Arch to run systemd/glibc programs.
> It also assumes x86_64 arch beceause doing it for other architectures would require significantly more of the only real currency: time.
> Add to this unique quirks of certain architecures.

In order to make this useful the most important to understand will be:

| Part Mode | BIOS Mode |
|----------|-------------|
| MBR | BIOS |
| MBR | UEFI |
| GPT | BIOS |
| GPT | UEFI |

Contrary to some common belief they all 4 support SWAP in both forms: a file or a full partition. 

In our first case `everest.sh` we are using MBR + BIOS and a swap file of 4GB. 
> This is possibly the most legacy approach (relevant for old hardware pre 2012).

> Note it doesn't need much change to be compatible with UEFI, change the partition tables to GPT.

```
pacman -S --noconfirm grub efibootmgr networkmanager base-devel sudo util-linux os-prober
mkdir -p /boot/efi
mount ${TARGET_DISK}1 /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch
```
 
Key here is `grub-install --target=x86_64-efi` instead of `--target=i386-pc`

```
parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart primary fat32 1MiB 512MiB  # EFI partition
parted -s "$TARGET_DISK" set 1 esp on
parted -s "$TARGET_DISK" mkpart primary linux-swap 512MiB 4.5GiB
parted -s "$TARGET_DISK" mkpart primary ext4 4.5GiB 100%

## correct format after for EDI 
mkfs.fat -F32 "${TARGET_DISK}1"
```

### All depends on your hardware
----
If you go into your BIOS, you should find an entry that either says "Boot Mode" or "UEFI/Legacy Boot" or if it's not present it might just have legacy only, or worse some (worse) weird formats like HFS for Apple, FAT32 for Windows, or custom boot options that are manufacturer-specific. Modern systems typically offer at least two options - UEFI and Legacy (BIOS) boot modes, while older systems may only support Legacy.

> Some systems also have a hybrid option called "UEFI with CSM" (Compatibility Support Module) that allows UEFI firmware to support legacy BIOS booting.

Inherently storage is not that complicated, today you can get USB Thunderbold NVMe adapters (Like Ugreen) I actually own 2 of them, and even a MSI from 2017 has ports for USB-C making it the perfect place for quicker writing than wha tthe manufacturer stuffed in it. 
That means that, you can have all your important work on one, your second OS on the other... Etc. 
> Note: Take skripts (kde fan lol) with a grain of salt. They should be adapted to your needs sometimes and not just blindly followed. Risk overwriting your data.

## Another quirk in BIOS

- IDE/Legacy mode - Very old mode, limited functionality
- AHCI - Modern standard, recommended for most systems
- RAID - For disk arrays
- Intel RST/Intel Rapid Storage Technology - Intel's proprietary mode
- SATA Native Mode
- SATA Compatible Mode
- AMD RAID/AMD-RAIDXpert - AMD's equivalent to Intel RST

> If your CMOS battery is dead and you turn off your power for some reason or lightning just hit your house lol, well it might default back to it's initial value, and if you have old hardware that might just break your boot. Anyways happened to me on older Acer motherboard that defaults to RST.


### About Multi-booting

It's 100% doable and not that complex if you understand all that is above here. ^^ 

But I tend to stay away from it having had bad experiences especially trying Windows with something else and not being able to boot because of either downright criminal Windows code or Hardware incompatibility.
Also storage has become one of the least expensive and easiest to find refurbished compared to other hardware. Again I recommend looking into NVMe adapters with USB-C support. 

----

## Lazy & Impatient

The advantage of being both of these at the same time is that you will think of heuristics of how to get to where you want but to do it quickly too. Even if it takes days to get there, once it's done it can be replicated instantly. 
Second part of this is to still try to realize that you do need patience and hard work to get there. So this is the philosophy that I adhere by to build this system for others: so they can just enjoy the final results. 


 
