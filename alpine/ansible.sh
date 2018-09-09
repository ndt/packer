#!/bin/sh

apk add sudo
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel

adduser ansible
echo "ansible:packer" | chpasswd
adduser ansible wheel

sleep 60000
