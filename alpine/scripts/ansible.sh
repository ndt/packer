#!/bin/sh

apk add sudo python
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel

adduser ansible
echo "ansible:packer" | chpasswd
adduser ansible wheel

mkdir -p /home/ansible/.ssh
chown -R ansible:ansible /home/ansible/.ssh
chmod 0700 /home/ansible/.ssh

wget -O - 'https://raw.githubusercontent.com/ndt/ansible/master/secrets/ansible.pub' >> /home/ansible/.ssh/authorized_keys 
chmod 0600 /home/ansible/.ssh/authorized_keys
