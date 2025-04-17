# Secure SSH Configuration
cat > /etc/ssh/sshd_config.d/secure.conf << 'EOF'
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding yes
PrintMotd no
EOF

# Fail2Ban 
apk add fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

## Add services here (Webservers, etc) 
[sshd] 
enabled = true
EOF
