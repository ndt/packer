#!/bin/bash

EMERGE='emerge -j2 --buildpkg'

# sync portage
mkdir /usr/portage
emerge-webrsync

# create fstab
cat > /etc/fstab <<'DATA'
# <fs>		<mount>	<type>	<opts>			<dump/pass>
/dev/sda2	/boot	ext2	noauto,noatime	1 2
/dev/sda4	/		ext4	noatime			0 1
/dev/sda3	none	swap	sw				0 0
DATA

# set timezone
ln -snf /usr/share/zoneinfo/UTC /etc/localtime
echo UTC > /etc/timezone

# emerge packages
MAKEOPTS='-j5' $EMERGE ">=sys-boot/grub-2.0" sys-kernel/gentoo-sources sys-kernel/genkernel-next

# install grub
echo "set timeout=0" >> /etc/grub.d/40_custom
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# install kernel
cd /usr/src/linux
mv /tmp/kernel.config .config
genkernel --install --symlink --oldconfig --makeopts=-j5 --no-color all

# emerge packages
MAKEOPTS='-j5' $EMERGE @world -uDN
MAKEOPTS='-j5' $EMERGE ">=app-emulation/virtualbox-guest-additions-4.3"

# install virtualbox additions
rc-update add virtualbox-guest-additions default

# clean up
emerge --depclean

rm -rf /tmp/*
rm -rf /var/log/*
