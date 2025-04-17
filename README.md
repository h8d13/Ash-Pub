# Why this project ? 

Everybody hates documention, and even more having to do manual menial tasks. 
While the footprint of Alpine is super low (200mb), it is a bit of work to configure. 
It is also versatile, efficient and secure. 

I wanted to see how how much a single setup script can do. 

The only prereq is git to access the script.

Do the standard `setup-alpine` 
So `apk add git`
Then `chmod +x` and `./setup.sh` 

## What exactly: 

### From Alpine Docs

Create /etc/profile.d/profile.sh with
```
if [ -f "$HOME/.config/ash/profile" ]; then
    . "$HOME/.config/ash/profile"
fi
```
Create ~/.config/ash/profile with:
```
export ENV="$HOME/.config/ash/ashrc"
```

^^ Same for zsh and BOTH to /.config/aliases

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

With an example script to search through your apps `iapps`

