#!/bin/sh

#
# variables
#
KEYMAPOPTS="de de"
HOSTNAMEOPTS="-n packed-alpine"
DOMAINNAMEOPTS="v.n6dt.de"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
APKREPOSOPTS="http://dl-cdn.alpinelinux.org/alpine/v3.8/main"

#
# run script
#
echo "root:packer" | chpasswd

setup-keymap $KEYMAPOPTS
setup-timezone -z UTC

# networking
setup-hostname $HOSTNAMEOPTS
printf "$INTERFACESOPTS" | setup-interfaces -i
rc-update --quiet add networking boot
rc-update --quiet add urandom boot
for svc in acpid cron crond; do
	if rc-service --exists $svc; then
		rc-update --quiet add $svc
	fi
done

# enable new hostname
/etc/init.d/hostname --quiet restart

_dn=$DOMAINNAMEOPTS
_hn=$(hostname)
_hn=${_hn%%.*}

sed -i -e "s/^127\.0\.0\.1.*/127.0.0.1\t${_hn}.${_dn} ${_hn} localhost.localdomain localhost/" /etc/hosts

setup-apkrepos $APKREPOSOPTS

# ssh
apk add openssh
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
rc-update --quiet add sshd default

# cron [via busybox]
rc-update add ntpd default

# install to disk
ERASE_DISKS="/dev/sda" setup-disk -q -m sys /dev/sda

reboot