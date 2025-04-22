# Install os-prober if needed
apk add grub os-prober

#Mount your Arch root (if not mounted):
mount /dev/nvmeXnXpY /mnt  # Replace with your Arch root partition

#Run os-prober:
os-prober
#It should detect Arch and list it.# Regenerate GRUB config:

grub-mkconfig -o /boot/grub/grub.cfg

# Enable os-prober in GRUB config
cat > /etc/default/grub << EOF
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu
GRUB_DISABLE_OS_PROBER=false
EOF

# Weird is that legacy is much easier to detect kind of just works by itself. 
# Update GRUB configuration (this runs os-prober automatically again because of setting)
grub-mkconfig -o /boot/grub/grub.cfg
