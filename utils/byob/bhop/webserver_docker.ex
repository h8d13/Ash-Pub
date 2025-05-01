# apk add docker docker-compose vscodium
# rc-service docker start (or add it to boot rc-update add docker) 
# git clone https://github.com/h8d13/Lighttpd-Steroids also download release ZIP. 
# Unzip the file in dir
# Doas python3 run.py --rebuild
## Alpineception
# Boom https webserver you can access from any device on your network. use ip a to find out device adress and on any browser: https://<ip> 
#### You can now freely customize. And change passwords in Dockerfile. 


# ADVANCED #################################### EXAMPLES
#adduser -SDHs /sbin/nologin dockremap
#addgroup -S dockremap
#echo dockremap:$(cat /etc/passwd|grep dockremap|cut -d: -f3):65536 >> /etc/subuid
#echo dockremap:$(cat /etc/passwd|grep dockremap|cut -d: -f4):65536 >> /etc/subgid

#echo "{\"userns-remap\": \"dockremap\"}" >> /etc/docker/daemon.json
#################################### 
