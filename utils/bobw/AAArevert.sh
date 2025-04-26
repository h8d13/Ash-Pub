#!/bin/sh
#alpine on sda stable
#sdb is arch temp
#sdc is backup
## revert 
dd if=/dev/sdc of=/dev/sdb bs=4M status=progress conv=sync,noerror
