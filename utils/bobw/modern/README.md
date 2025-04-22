#### Install os-prober if needed

apk add grub os-prober

#### Mount your Arch root (if not mounted):

mount /dev/nvmeXnXpY /mnt  # Replace with your Arch root partition

#### Run os-prober:
os-prober

>It should detect Arch and list it.


#### Enable os-prober in GRUB config
nano /etc/default/grub
```
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu
GRUB_DISABLE_OS_PROBER=false

````

>Regenerate GRUB config:
grub-mkconfig -o /boot/grub/grub.cfg

-----


If you're like me you can run `efibootmgr`

You will see a bunch of old entries. 

To clean up: 

`efibootmgr -b 0000 -B` especially that windows one. 
