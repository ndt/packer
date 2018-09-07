#!/bin/sh

wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers

setup-alpine -f $PWD/answers
{{user `root_password`}}
{{user `root_password`}}
y
reboot
root
{{user `root_password`}}
apk add sudo
echo 'Defaults env_keep += \"http_proxy https_proxy\"' > /etc/sudoers.d/wheel
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers.d/wheel
adduser {{user `ssh_username`}}
{{user `ssh_password`}}
{{user `ssh_password`}}
adduser {{user `ssh_username`}} wheel
