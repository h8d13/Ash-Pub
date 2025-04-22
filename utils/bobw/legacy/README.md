apk add grub os-prober

Mount your Arch root (if not mounted):

mount /dev/nvmeXnXpY /mnt  # Replace with your Arch root partition

Run os-prober:

os-prober

It should detect Arch and list it.

Regenerate GRUB config:

grub-mkconfig -o /boot/grub/grub.cfg
