# Why this project ? 

Everybody hates docs and even more having to do manual menial tasks. 
While the footprint of Alpine is super low (200mb), it is a bit of work to configure. 

It is also versatile, efficient and secure. I wanted to see how for a single setup script can do. 

### From Alpine Docs

Create /etc/profile.d/profile.sh with (Make exec) 
```
if [ -f "$HOME/.config/ash/profile" ]; then
    . "$HOME/.config/ash/profile"
fi
```
Create ~/.config/ash/profile with:
```
export ENV="$HOME/.config/ash/ashrc"
```

### Profiles / Doas

### Parralel boot

### Zsh 

### Emoji / UTF8 support


----





