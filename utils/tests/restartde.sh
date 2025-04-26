#!/bin/sh
killall plasmashell
rc-service sddm stop
rc-service elogind restart
