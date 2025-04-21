# Best of Both Worlds

This section is to create a double boot with Alpine as host and Arch to run systemd/glibc programs.

In order to make this useful the most important to understand will be:

| Part Mode | BIOS Mode |
|----------|-------------|
| MBR | BIOS |
| MBR | UEFI |
| GPT | BIOS |
| GPT | UEFI |

Contrary to some common belief they all 4 support SWAP in both a file or a full partition. 

In our first case `everest.sh` we are using MBR + BIOS. 

This is possibly the most legacy approach (relevant for oldhardware pre 2012).
