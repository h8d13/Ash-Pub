# How it all works together:

Start with a fresh Alpine Linux 3.21 installation

Do the standard `setup-alpine`
Create a user during setup!
> Make sure to use different strong passwords for root and user. Usernames lowercase.

Then follow documented steps:
```
apk add git
git clone https://github.com/h8d13/k2-alpine
cd k2-alpine
chmod +x setup.sh
./setup.sh
```
Reboot

Once Alpine is configured, proceed to `utils/bobw` module should be cloned on your desktop.


### If you want to game on Nvidia stuff. 
Run the appropriate `everest.sh` script (legacy MBR/BIOS or modern GPT/UEFI) depending on hardware (check bios if unsure).  
I use a second disk. 
Run `arch-chroot` for any extra setup steps into Arch, when done type `exit`

Follow GRUB to add Arch to the boot menu of Alpine.
Reboot and test booting into Arch.

> Gratz :) You are now double Linux masterace with coolest script around. 
> Don't forget to change hardcoded passwords `Everest` for arch.

> `passwd root` and `passwd joe`

## To do

Al
- Create info section on rc
- Create containers info section
- Fix restartde command

Ar
- Add user auto to arch install ☑️
- Keymap for console ☑️
- What if we can copy over some config KDE files over to arch auto ☑️ (To test) 
- Create GPT EFI version ☑️ (To test) 


