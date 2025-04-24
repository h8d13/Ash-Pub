#################################### EXAMPLES
apk add docker docker-compose --no-cache
rc-update add docker boot
service docker start

adduser -SDHs /sbin/nologin dockremap
addgroup -S dockremap
echo dockremap:$(cat /etc/passwd|grep dockremap|cut -d: -f3):65536 >> /etc/subuid
echo dockremap:$(cat /etc/passwd|grep dockremap|cut -d: -f4):65536 >> /etc/subgid

echo "{\"userns-remap\": \"dockremap\"}" >> /etc/docker/daemon.json
#################################### 
