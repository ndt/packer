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
	set 1 bios_grub on \
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

# extract stage archive
cd /mnt/gentoo
tar xjpf /tmp/$STAGE
rm -f $STAGE

# mount partitions
mount /dev/sda2 /mnt/gentoo/boot
mount -t proc proc /mnt/gentoo/proc
mount --rbind /dev /mnt/gentoo/dev
mount --rbind /sys /mnt/gentoo/sys

# copy resolf.conf
cp -L /etc/resolv.conf /mnt/gentoo/etc/
cp $SCRIPTS/kernel.config /mnt/gentoo/tmp/
cp $SCRIPTS/install.sh /mnt/gentoo/tmp/

chroot /mnt/gentoo /tmp/install.sh

swapoff /dev/sda3
dd if=/dev/zero of=/dev/sda3
mkswap /dev/sda3

# finish
echo "All done."
