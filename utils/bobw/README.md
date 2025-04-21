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

Contrary to some common belief they all 4 support SWAP in both a file or a full partition. 

In our first case `everest.sh` we are using MBR + BIOS. 
> This is possibly the most legacy approach (relevant for old hardware pre 2012).

If you go into your BIOS, you should find an entry that either says "Boot Mode" or "UEFI/Legacy Boot" or if it's not present it might just have legacy only, or worse some (worse) weird formats like HFS for Apple, FAT32 for Windows, or custom boot options that are manufacturer-specific. Modern systems typically offer at least two options - UEFI and Legacy (BIOS) boot modes, while older systems may only support Legacy.

> Some systems also have a hybrid option called "UEFI with CSM" (Compatibility Support Module) that allows UEFI firmware to support legacy BIOS booting.
