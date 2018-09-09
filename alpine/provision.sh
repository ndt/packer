#!/bin/sh

ERASE_DISKS="/dev/sda"
setup-alpine  -e -f /tmp/answers

echo "ready"

sleep 300

reboot

root
{{user `root_password`}}

apk add sudo
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel
adduser {{user `ssh_username`}}
{{user `ssh_password`}}
{{user `ssh_password`}}
adduser {{user `ssh_username`}} wheel
