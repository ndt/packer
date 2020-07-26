#!/bin/bash

if [[ -z $STAGE ]]
then
  echo "STAGE environment variable must be set to a timestamp."
  exit 1
fi

# partition disks
parted -a optimal --script /dev/sda -- \
	mklabel gpt \
	unit mib \
	mkpart primary 1 3 \
	name 1 grub \
	set 1 legacy_boot on \
	mkpart primary 3 131 \
	name 2 boot \
	set 2 boot on \
	mkpart primary 131 1155 \
	name 3 swap \
	mkpart primary 1155 -1 \
	name 4 root \
	print

sync

# format disks
mkfs.ext2 /dev/sda2
mkfs.ext4 /dev/sda4
mkswap /dev/sda3 && swapon /dev/sda3

# mount system partition
mount /dev/sda4 /mnt/gentoo
mkdir /mnt/gentoo/boot
mount /dev/sda2 /mnt/gentoo/boot

# extract stage archive
cd /mnt/gentoo
echo "*** extract stage archive"
tar xJpf /tmp/$STAGE --xattrs --numeric-owner
rm -f $STAGE

# copy packages
echo "*** copy packages"
ls -laR /tmp/
mkdir -p /mnt/gentoo/usr/portage/packages
cp -r /tmp/packages/ /mnt/gentoo/usr/portage/packages/
ls -laR /mnt/gentoo/usr/portage/packages/

# adding gentoo repos
mkdir /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
sed -i 's/^sync-uri\s=\s.*$/sync-uri = rsync:\/\/192.168.2.4\/gentoo-portage/' gentoo.conf

# copy resolf.conf
cp -L /etc/resolv.conf /mnt/gentoo/etc/

# copy kernel
#echo "*** copy kernel image and modules"
#mkdir /mnt/gentoo/etc/kernels
#cp /etc/kernels/* /mnt/gentoo/etc/kernels
#cp /proc/config.gz /mnt/gentoo/tmp/.config.gz
#cp /mnt/cdrom/isolinux/gentoo /mnt/gentoo/boot/kernel
#cp /mnt/cdrom/isolinux/gentoo.igz /mnt/gentoo/boot/initramfs
#mkdir -p /mnt/gentoo/lib/modules
#cp -Rp /lib/modules/`uname -r` /mnt/gentoo/lib/modules

# mount partitions
mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

cp $SCRIPTS/prepare.sh /mnt/gentoo/
cp $SCRIPTS/install.sh /mnt/gentoo/tmp/
chmod +x /mnt/gentoo/tmp/install.sh

chroot /mnt/gentoo /tmp/install.sh

ls -laR /mnt/gentoo/usr/portage/packages/

swapoff /dev/sda3
dd if=/dev/zero of=/dev/sda3
mkswap /dev/sda3

# finish
echo "All done."
