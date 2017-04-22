#!/bin/bash
EMERGE='emerge -j2 --buildpkg'

source /etc/profile
export PS1="(chroot) $PS1"

# sync portage
emerge-webrsync

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
echo "de_DE.utf-8 utf-8" >> /etc/locale.gen
locale-gen
eselect locale set de_DE.utf8
env-update && source /etc/profile && export PS1="(chroot) $PS1"

# install boot packages
MAKEOPTS='-j5' $EMERGE sys-boot/syslinux sys-kernel/gentoo-sources sys-kernel/genkernel-next

# install syslinux
dd bs=440 conv=notrunc count=1 if=/usr/share/syslinux/gptmbr.bin of=/dev/sda
cd /boot
mkdir /boot/extlinux
extlinux --install /boot/extlinux
ln -snf . /boot/boot

cd /usr/share/syslinux
cp menu.c32 memdisk libcom32.c32 libutil.c32 /boot/extlinux

cat > /boot/extlinux/extlinux.conf <<'DATA'
DEFAULT gentoo
LABEL gentoo
	LINUX /boot/kernel
	INITRD /boot/initramfs
	APPEND root=/dev/sda4
DATA

# emerge packages
MAKEOPTS='-j5' $EMERGE @world -uDN
MAKEOPTS='-j5' $EMERGE app-emulation/virtualbox-guest-additions

# clean up
emerge --depclean

rm -rf /tmp/*
rm -rf /var/log/*
