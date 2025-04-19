# TreeStruc
```
Alpine KDE Setup Script
├── System Detection
│   ├── TARGET_USER detection
│   └── KB_LAYOUT detection
│
├── System Setup
│   ├── Repository Configuration
│   │   ├── Community repository
│   │   ├── Main repository
│   │   └── Testing repository
│   ├── Package Management
│   │   ├── System update
│   │   ├── KDE Plasma installation
│   │   └── Package cleanup (removing bloat)
│   └── System Tweaks
│       └── SDDM service configuration
│
├── Keyboard Configuration
│   ├── Login Screen KB Layout (/usr/share/sddm/scripts/Xsetup)
│   └── KDE KB Layout (/home/$TARGET_USER/.config/kxkbrc)
│
├── Directory Structure Creation
│   ├── Admin Directories
│   │   ├── ~/.config and subdirectories
│   │   ├── ~/.local/bin
│   │   └── ~/.zsh/plugins
│   └── User Directories
│       ├── /home/$TARGET_USER/.config/ and subdirectories
│       └── /home/$TARGET_USER/.local/share/konsole
│
├── Editor Configuration
│   ├── Root Micro config
│   └── User Micro config
│
├── Terminal Configuration
│   └── Konsole
│       ├── Base configuration (/home/$TARGET_USER/.config/konsolerc)
│       └── User profile (/home/$TARGET_USER/.local/share/konsole/$TARGET_USER.profile)
│
├── Shell Environment
│   ├── Common Components
│   │   ├── Environment file (~/.config/environment)
│   │   └── Aliases file (~/.config/aliases)
│   ├── ASH Shell Configuration
│   │   ├── System profile hook (/etc/profile.d/profile.sh)
│   │   ├── User profile (~/.config/ash/profile)
│   │   └── RC file (~/.config/ash/ashrc) with blue prompt
│   └── ZSH Shell Configuration
│       ├── Plugin installation
│       ├── Config directory setup (~/.config/zsh/)
│       ├── ZSH RC file (~/.config/zsh/zshrc) with red prompt
│       └── User .zshrc link
│
├── Utility Scripts
│   └── iapps (package search utility)
│
├── System Security & Performance
│   ├── Temporary file cleanup
│   ├── Network performance settings
│   ├── Security hardening
│   └── Firewall configuration
│
└── User Experience
   ├── System welcome message (/etc/motd)
   ├── Login banner (/etc/issue)
   └── Post-login welcome message (/etc/profile.d/welcome.sh)
```
