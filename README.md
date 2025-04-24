# Why this project ? 

> My personal KDE reverse engineering project from the user's perspective. The only DE that competes visually with Apple/Microsoft. 

Most people hate documention, and even more having to do manual menial tasks. 
Then it becomes a whole other story when you have to work with 100 different underlying components that each have their own unique quirks.

This project aims to do exactly this. Eliminate quirks by programatically solving issue with OoO (Order of Operations). 

While the footprint of Alpine is super low (200mb), it is a bit of work to configure. 
This mini-service philosophy makes it versatile, efficient and secure. 
> I also always wondered if it's used so much on servers, clusters, etc why not make it a fully operational system?
> Which brings us to today. Where I'm daily driving it for coding. 

**But again more difficult to set-up for a beginner?**

Removing that issue with a single setup script (and soon a custom ISO).
As the essential of dev is doing things faster than the other person.

[Alpine ISOs](https://www.alpinelinux.org/downloads/) 
> Select the right architecture (usually x86_64)
> Flash to a USB (dd mode & check bios for UEFI vs BIOS, GPT vs MBR) . See [Rufus](https://rufus.ie/en/) 

Also [Preparation-Wiki](https://github.com/h8d13/k2-alpine/wiki/1.-Preperation)

Do the standard `setup-alpine` 
> ⚠️ IMPORTANT: You have to create a user (this will be useful for later).

> Make the pw different from root. Lowercase usernames.

## Desktop Env 

- KDE because it's beautiful and reliable. (x11 + Wayland enabled)
> Also has many essentials pre-installed and is still relatively light (2.5GB/3GB Total with Wallpapers)
> Much lighter on alpine (example BSD default KDE: 7.5Gb)

> RAM Usage: > 1GB~ Idle

## Config 
> ⚙ All automated. You could add your desired software to line 45 like `vscodium` or do it later. 😎

---

## What exactly: 

For a better view [Project Tree](https://github.com/h8d13/k2-alpine/blob/master/utils/tests/TreeStruc.md)

### Make a DE an option not an obligation. 

That's right you terminal nerds. 
`startde`, `restartde` and `stopde` commands.

### One place for admin configs
> So that if you create several users down the line they can all have their own configs. 

### Auto-add main/community repos
> Giving you access to 30 000+ packages through apk 

### Basic /etc confs 
> System hardening, not a router stuff etc

### Emoji / UTF8 support

### Added more helpful guidance on where to start

### Zsh integrated
Sets up common aliases for Zsh & Ash 
> All in one place :) Following Alpine docs best practice but better.

![image](https://github.com/user-attachments/assets/15c3e523-59ac-4000-80ee-ff0a199245e3)

### Custom `.local/bin`
With an example script to search through your apps `iapps`: See example above ^^ 
> Managed in `/.config/environment`

### Fixed SDDM keyboard locale & Same for KDE 
> Another quirk that annoyed me to do on every fresh install. 

---

## ⌛ -  03:31m Installation vs 2 Hours Setting-up
> That on a mini-pc with horrible hardware!

Inital `setup-alpine`, follow prompts, reboot to hardisk. 
 Create a user, lowercase. Different pw than root. 
 
Then `apk add git`
`git clone https://github.com/h8d13/k2-alpine`

`cd k2-alpine`
`chmod +x setup.sh`

Run the script `./setup.sh`

Once all is done, reboot again. `startde` to start SDDM & KDE. 

![image](https://github.com/user-attachments/assets/300e8782-8506-4d96-b406-9e14e1f024be)

You should find a program called `Konsole` This is your new best friend. 

I've also included `micro` for friendly terminal editor. 

## Also updated Konsole profile to match our setup :) 
> To go back to a user shell you can simply right click this: Or `CTRL + ALT + Y`

![image](https://github.com/user-attachments/assets/77d64ab3-5f74-47e9-885b-d086a4ca77ee)

----

## Video Tutorial + Wiki

### Read our Wiki: [K2-ALPINE-WIKI](https://github.com/h8d13/k2-alpine/wiki)
https://github.com/user-attachments/assets/b488e808-174d-4a6b-ad7e-fc3dccdbbca1

## Further reading

| Resource | Description |
|----------|-------------|
| [Alpine Linux Wiki](https://wiki.alpinelinux.org/wiki/Main_Page) | Official documentation and guides for Alpine Linux |
| [BusyBox](https://www.busybox.net/) | Combines tiny versions of many common UNIX utilities into a single executable |
| [Ash](https://linux.die.net/man/1/ash) | Lightweight shell included in BusyBox, Alpine's default shell |
| [Bash](https://www.gnu.org/software/bash/manual/bash.html) | Lightweight shell included in BusyBox, Alpine's default shell |
| [Zsh](https://github.com/zsh-users/zsh) | Extended Bourne shell with improved features and customization |
| [Musl](https://musl.libc.org/) | Lightweight C standard library alternative to glibc counterpart |
| [FreeDesktop](https://gitlab.freedesktop.org) | Desktop utils KDE uses extensively  |
| [KDE Plasma](https://kde.org/plasma-desktop/) | Feature-rich, customizable desktop environment for Linux |
| [KDE Configs](https://github.com/shalva97/kde-configuration-files) | For terminal nerds to change behavior |
| [Dolphin](https://userbase.kde.org/Dolphin) | File viewer for for KDE. Integrated permissions, etc. |
| [Util-Linux](https://github.com/util-linux/util-linux) | Random collection of Linux utilities |
| [Vi](https://docs.rockylinux.org/books/admin_guide/05-vi/) | Traditional Unix text editor available on most systems |
| [Micro](https://github.com/zyedidia/micro) | Modern and intuitive terminal-based text editor with easy keybindings |

> DONT LIKE KDE? You could modify the script to install any Desktop Env, but it would be quite a bit of work.

> Note: But Hadie! I cannot game on Alpine... You absolutely can. And it works nice :) 
[Chimera-Linux](https://chimera-linux.org/docs/configuration/flatpak)

This also uses apk and MUSL so here you will find golden trove of information ^^

Special thanks to user @Calvince for this file:
[Ubuntu terminal look like ParrotOS](https://gist.github.com/calvince/b4f1a321369ade869789d99a2604670f)

---
Love <3 H8D13
