#!/bin/sh

echo "root:packer" | chpasswd

apk add openssh
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
#rc-update add sshd default

ERASE_DISKS="/dev/sda" setup-alpine  -e -f answers

reboot
