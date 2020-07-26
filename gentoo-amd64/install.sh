#!/bin/bash
EMERGE='emerge -j4 --buildpkg --usepkg'

source /etc/profile
export PS1="(chroot) $PS1"

# sync portage
emerge --sync

# create fstab
cat > /etc/fstab <<'DATA'
# <fs>		<mount>	<type>	<opts>			<dump/pass>
/dev/sda2	/boot	ext2	noauto,noatime	1 2
/dev/sda3	none	swap	sw				0 0
/dev/sda4	/		ext4	noatime			0 1
DATA

# set timezone
#ln -snf /usr/share/zoneinfo/UTC /etc/localtime
echo "UTC" > /etc/timezone
emerge --config sys-libs/timezone-data

# configure locales
sed -i 's/^#en_US/en_US/;s/#de_DE/de_DE/' /etc/locale.gen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set de_DE.utf8
env-update && source /etc/profile && export PS1="(chroot) $PS1"

# install boot packages
$EMERGE --autounmask-write sys-kernel/{gentoo-kernel-bin,linux-firmware}

# configure kernel
#cd /usr/src/linux
#cp /tmp/.config.gz .
#gunzip .config.gz
##make oldconfig
##make modules_prepare
#genkernel --oldconfig --install all

# install syslinux
#dd bs=440 conv=notrunc count=1 if=/usr/share/syslinux/gptmbr.bin of=/dev/sda
#cd /boot
#mkdir /boot/extlinux
#extlinux --install /boot/extlinux
#ln -snf . /boot/boot
#
#cd /usr/share/syslinux
#cp menu.c32 memdisk libcom32.c32 libutil.c32 /boot/extlinux
#
#cat > /boot/extlinux/extlinux.conf <<'DATA'
#DEFAULT gentoo
#LABEL gentoo
#	LINUX ../kernel
#	APPEND root=/dev/sda4
#	INITRD ../initramfs
#DATA

# emerge packages
$EMERGE ">app-emulation/virtualbox-guest-additions-5.1.0" --autounmask-write
etc-update --automode -3
$EMERGE ">app-emulation/virtualbox-guest-additions-5.1.0" --autounmask-write
$EMERGE @world -uDN
$EMERGE @preserved-rebuild

# clean up
emerge --depclean

rm -rf /tmp/*
rm -rf /var/log/*
