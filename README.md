# Why this project ? 

> My personal KDE/Alpine reverse engineering project from the user's perspective. The only DE that competes visually with Apple/Microsoft user-spaces. 
> Ample personalization, widgets, tools, and a rich eco-system. Props to KDE devs, Alpine and more OSS contributors.

Most people hate documention, and even more having to do manual menial tasks. 
Then it becomes a whole other story when you have to work with 100 different underlying components that each have their own unique quirks.

This project aims to do exactly this. Eliminate quirks by programatically solving issue with OoO (Order of Operations) & SoC (Separation of Concerns) & EUI (End-User Interaction). 

**It's also my kind of solution to hardware, I didn't use anymore but could have been useful all along?**

![logo](https://github.com/user-attachments/assets/b4fa123f-f38b-4361-81b8-febd5c77fcd3)  © _K2-alpine v1.0.3_

While the footprint of Alpine is low (200mb), it can be hell to configure manually.

**But this service-oriented philosophy makes it versatile, efficient and secure.**

> I also always wondered if it's used so much on servers, clusters, etc why not make it a fully operational system?
> Which brings us to today. Where I'm daily driving it for coding/general browsing but you can also extend quite quickly!

How ?
**By making one simple easy to update system and have storage on the side.**

I recommend putting work there, and being able to wipe without shame in 10 minutes, with the latest Alpine updates.
As LTT famously said the 3-2-1 rules: In this case: Some of your work probably on git/drives for cloud, external to prevent data loss and finally 1 being the system itself.

That means an external USB stick or NVMe to USB adapter, preferably over USB-C or 3.x for faster read/write 😜 
Or internal hardware. 
> At it's core storage is just storage, why is interesting to have single setup scripts instead of full live releases: so you can extend how you see fit.  

## Brickable 🧱🔧👷

> Using alpine's core isolation and clear service management, we can make reproducible installs whilst being quick:

We can aim for 200mb base iso, 2-3gb at most to download and not too much on disk (about 15gb with some extras) depending on firmware, meaning it's (easier) to maintain. Can run great on mini computers and laptops or even just on a usb/vm.
This also lets you kind of "hack" other devices as you simply mount them with adapters and explore. 

**But again more difficult to set-up for a beginner?**

Removing that issue with a single setup script.
As the essential of dev is doing things faster than the other person.

[Alpine ISOs](https://www.alpinelinux.org/downloads/) 
> Select the right architecture (usually x86_64)
> Flash to a USB (dd mode & check bios for UEFI vs BIOS, GPT vs MBR) . See [Rufus](https://rufus.ie/en/)

Do the standard `setup-alpine` 
> ⚠️ IMPORTANT: You have to create a user (this will be useful for later).

> Make the pw different from root. Lowercase usernames.

## Config 
> ⚙ All automated. Altho there is a bit to understand for specific hardware (more recent x86_64 Intel should work out of the box). 😎

I recommend jumping at least through the beginning of the script that setups firmware, graphics drivers, etc. 

> You can freely remove, edit sections to your liking. Altho you'd have to know some stuff. But the rest pretty much done for you. 

Also [Preparation-Wiki](https://github.com/h8d13/k2-alpine/wiki/1.-Preperation.)

Then `apk add git`
`git clone https://github.com/h8d13/k2-alpine`

`cd k2-alpine`
`chmod +x setup.sh`

> Here you could also edit for your preferences/firmware. 

Run the script `./setup.sh`
Once all is done, reboot again. You are all done! 
You should find a program called `Konsole` This is your new best friend. 

I've also included `micro` for friendly terminal editor and `alsamixer` so you can say your sound works on Linux 😆. 

## Also updated Konsole profile to match our setup :) 

> To go back to a user shell you can simply right click this and select Built-in:
![image](https://github.com/user-attachments/assets/77d64ab3-5f74-47e9-885b-d086a4ca77ee)

---

## Desktop Env 

- KDE because it's beautiful and reliable. (Wayland + x11 enabled)
> Also has many essentials pre-installed and is still relatively light (2.5GB/3GB Total with Wallpapers)
> Much lighter on alpine (example BSD default KDE: 7.5Gb)

> RAM Usage: > 1GB~ Idle

## What exactly: 

### One place for admin configs
> So that if you create several users down the line they can all have their own configs. 

### Auto-add main/community repos
> Giving you access to 50 000+ packages through apk 

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

----

## Wiki

### Read our Wiki: [K2-ALPINE-WIKI](https://github.com/h8d13/k2-alpine/wiki)

----

## Previews
![image](https://github.com/user-attachments/assets/c40f0701-6b63-4faf-9249-f075397fef24)
![image2](https://github.com/user-attachments/assets/f0e66b6c-1c18-4952-9bad-b8c711f903e4)
![image3](https://github.com/user-attachments/assets/3c2bd76a-2004-466c-9eb8-bea41387a48f)

## Further reading

| Resource | Description |
|----------|-------------|
| [Alpine Linux Wiki](https://wiki.alpinelinux.org/wiki/Main_Page) | **Official documentation** and guides for Alpine Linux |
| [BusyBox](https://www.busybox.net/) | Combines tiny versions of many common UNIX utilities into a single executable |
| [Ash](https://linux.die.net/man/1/ash) | Lightweight shell included in BusyBox, Alpine's default shell |
| [Bash](https://www.gnu.org/software/bash/manual/bash.html) | More scripting new shell stuff |
| [Zsh](https://github.com/zsh-users/zsh) | Extended Bourne shell with improved features and customization |
| [Musl](https://musl.libc.org/) | Lightweight C standard library alternative to glibc counterpart |
| [FreeDesktop](https://gitlab.freedesktop.org) | Desktop utils KDE uses extensively  |
| [KDE Plasma](https://kde.org/plasma-desktop/) | Feature-rich, customizable desktop environment for Linux |
| [KDE Configs](https://github.com/shalva97/kde-configuration-files) | For terminal nerds to change behavior |
| [Dolphin](https://userbase.kde.org/Dolphin) | File viewer for for KDE. Integrated permissions, etc. |
| [Util-Linux](https://github.com/util-linux/util-linux) | Random collection of Linux utilities |
| [Vi](https://docs.rockylinux.org/books/admin_guide/05-vi/) | Traditional Unix text editor available on most systems |
| [Micro](https://github.com/zyedidia/micro) | Modern and intuitive terminal-based text editor with easy keybindings |


> Note: But Hadie! I cannot game on Alpine... You absolutely can. And it works nice :) 
[Chimera-Linux](https://chimera-linux.org/docs/configuration/flatpak)

This also uses apk and MUSL so here you will find golden trove of information ^^
[Gcompat Docs](https://git.adelielinux.org/adelie/gcompat) 

**BUT! We have also included a module to self mount Arch on another disk if you are running NVIDIA stuff/Old hardware.**
Hopefully a version with RC ;)

Special thanks to user @Calvince for this file:
[Ubuntu terminal look like ParrotOS](https://gist.github.com/calvince/b4f1a321369ade869789d99a2604670f)

**My goal is to turn Konqi into Kodzilla.**

![vw398e3twkxe1-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/a8912369-a8cc-49be-af79-80994e8d2ab6)


🤖 For raspi 4+ people we have also included a debian version of the script:
You can find here [Wiki RaspB Pi](https://github.com/h8d13/k2-alpine/wiki/Z.-Rasp-Pi-4)
And here [Actual Script](https://github.com/h8d13/k2-alpine/blob/master/utils/standalone/setup_deb.sh)

---
Love <3 H8D13
