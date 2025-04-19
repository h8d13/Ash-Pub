# Why this project ? 

Most people hate documention, and even more having to do manual menial tasks. 
Then it becomes a whole other story when you have to work with 100 different underlying components that each have their own unique quirks.

This project aims to do exactly this. Eliminate quirks by programatically solving issue with OoO (Order of Operations). 

While the footprint of Alpine is super low (200mb), it is a bit of work to configure. 
This mini-service philosophy makes it versatile, efficient and secure. 

**But again more difficult to set-up for a beginner?**

I wanted to see how how much a single setup script can do. As the essential of dev is doing things faster than the other person.

[Alpine ISOs](https://www.alpinelinux.org/downloads/) 
> Select the right architecture (usually x86_64)
> Flash to a USB (See [Rufus](https://rufus.ie/en/). 

Do the standard `setup-alpine` 
> ⚠️ IMPORTANT: You have to create a user (this will be useful for later).

> Make the pw different from root. lowercase usernames (I used k2 & hill).

## Desktop Env 

- KDE because it's beautiful and reliable. (x11 + Wayland enabled)
> Also has many essentials pre-installed and is still relatievly light (2.5GB/3GB Total with Wallpapers)

> DONT LIKE KDE? Inside utils you will find the same script without any desktop if you prefer, or with a choice ;)

## Config 
> ⚙ All automated. You could add your desired software to line 45 like `vscodium` or do it later. 😎

---

## What exactly: 

For a better view [Project Tree](https://github.com/h8d13/k2-alpine/blob/master/utils/tests/TreeStruc.md)

### Make a DE an option not an obligation. 

That's right you terminal nerds. 
`startde` and `stopde` commands.

### One place for admin configs
This modular approach makes it so that if you create several users down the line they can all have their own configs. 

![image](https://github.com/user-attachments/assets/1ae70597-2560-431e-9cdc-1368f1826173)

### Auto-add main/community repos
> Giving you access to 30 000+ packages through apk 

### Basic /etc confs 
> System hardening, not a router stuff etc

### Emoji / UTF8 support

### Added more helpful guidance on where to start

### Zsh integrated
Sets up common aliases for Zsh & Ash 
> All in one place :) Following Alpine docs best practice but better.

### Custom `.local/bin`
With an example script to search through your apps `iapps`: See example above ^^ 
> Managed in `/.config/environment`

### Fixed SDDM keyboard locale & Same for KDE 
> Another quirk that annoyed me to do on every fresh install. 

---

## ⌛ - 7 Minutes Installation vs 2 Hours Setting-up
> That on a mini-pc with horrible hardware!

Inital `setup-alpine`, follow prompts, reboot to hardisk. 
 Create a user, lowercase. Different pw than root. 
 
Then `apk add git`
`git clone https://github.com/h8d13/k2-alpine`

`cd k2-alpine`
`chmod +x setup.sh`

Run the script `./setup.sh`

Once all is done, reboot again. `startde` to start SDDM & KDE. 

![image](https://github.com/user-attachments/assets/c7dda33b-de38-435a-ac47-f29630c5205a)

You should find a program called `Konsole` This is your new best friend. 

I've also included `micro` for friendly terminal editor. 

## Also updated Konsole profile to match our setup :) 

----

## Video Tutorial

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
| [KDE Configs](https://github.com/shalva97/kde-configuration-files) | For terminal nerds to change behavior. |
| [Vi](https://docs.rockylinux.org/books/admin_guide/05-vi/) | Traditional Unix text editor available on most systems |
| [Micro](https://github.com/zyedidia/micro) | Modern and intuitive terminal-based text editor with easy keybindings |


Special thanks to user @Calvince for this file:
[Ubuntu terminal look like ParrotOS](https://gist.github.com/calvince/b4f1a321369ade869789d99a2604670f)

---
Love <3 H8D13
