# How it all works together:

Start with a fresh Alpine Linux 3.21 installation

Do the standard setup-alpine
Create a test user during setup
Make sure to use different passwords for root and user

Then follow documented steps:

apk add git
git clone https://github.com/h8d13/k2-alpine
cd k2-alpine
chmod +x setup.sh
./setup.sh
Reboot
Test startde command

Once Alpine is configured, proceed to `bobw` module.

Run the appropriate everest.sh script (legacy MBR/BIOS or modern GPT/UEFI) depending on hardware.  

Run kdepost.sh after chrooting into Arch, when done type `exit`

Run the grub_host.sh script to add Arch to the boot menu of Alpine. 
Reboot and test booting into Arch

> Gratz :) You are now double Linux masterace with coolest script around. 
> Don't forget to change hardcoded passwords `Everest` for arch.

> `passwd root` and `passwd joe`

## To do

Ar
- Add user auto to arch install ☑️
- Keymap for console ☑️
- What if we can copy over some config KDE files over to arch auto ☑️ (To test) 
- Create GPT EFI version ☑️ (To test) 

Al
- Create info section on rc
- Create containers info section
