# Why this project ? 

Everybody hates documention, and even more having to do manual menial tasks. 
And even more when you have to work with 100 different underlying components that each have their own quirks.
While the footprint of Alpine is super low (200mb), it is a bit of work to configure. 
It is also versatile, efficient and secure. 

I wanted to see how how much a single setup script can do. 

Do the standard `setup-alpine` 
> ⚠️ IMPORTANT: You have to create a user (this will be useful for later). Make the pw different from root. 

## Desktop Env 

- KDE because it's beautiful and reliable.
> Also has many essentials pre-installed and is still relatievly light (2.5GB/3GB Total)

The only prereq is git to access the script.

So `apk add git`
Then `chmod +x` and `./setup.sh` 

> Then only thing you have to do is specify the user you created in the script:
`TARGET_USER=Hill`

## What exactly: 

### Make a DE an option not an obligation. 

That's right you terminal nerds. 
`startde` and `stopde` commands.

### One place for admin configs
This modular approach makes it so that if you create several users down the line they can all have their own configs. 

![image](https://github.com/user-attachments/assets/1ae70597-2560-431e-9cdc-1368f1826173)

### Auto-add main/community repos

### Basic /etc confs 

### Emoji / UTF8 support

### Added more helpful motd

### Cool splash screen
----

Sets up common aliases for Zsh & Ash 
> All in one place :)

![image](https://github.com/user-attachments/assets/f68f8c19-7b45-4af9-9c10-03a321f599c4)

----
### Custom `.local/bin`

With an example script to search through your apps `iapps`: See example above ^^ 

## ⌛ - 10 Minutes Total

Inital `setup-alpine`, reboot to hardisk. 
Then `apk add git`
Then `https://github.com/h8d13/K2-Alpine`
`cd K2-Alpine`
`chmod +x setup.sh`
run the script `./setup.sh`

Once all is done I recommend to reboot.

`startde` or `stopde`

![image](https://github.com/user-attachments/assets/c7dda33b-de38-435a-ac47-f29630c5205a)

You should find a program called `Konsole` This is your new best friend.

To get to your beautiful shell/zsh: `su -l` this tells it to run as root and as a login shell :)

Or `k2` will do the same. 

![image](https://github.com/user-attachments/assets/4538fc89-a0b0-4feb-9a02-0279dfc6109f)

----
Love <3 H8D13




