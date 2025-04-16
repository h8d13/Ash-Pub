# From Alpine Docs

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

Clone repo and copy style for ashrc file paste it into it. 
Add aliases here too. 



