#!/bin/sh
# Install os-prober if needed ##  KEY DIFF is grub-bios package
apk add os-prober grub-bios

# Enable os-prober in GRUB config
cat > /etc/default/grub << EOF
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu
GRUB_DISABLE_OS_PROBER=false
EOF

# Weird is that legacy is much easier to detect kind of just works by itself. 
# Update GRUB configuration (this runs os-prober automatically)
grub-mkconfig -o /boot/grub/grub.cfg
