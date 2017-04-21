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

# extract stage archive
cd /mnt/gentoo
echo "extracting stage archive"
tar xjpf /tmp/$STAGE --xattrs --numeric-owner
rm -f $STAGE

# adding gentoo repos
mkdir /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

# copy resolf.conf
cp -L /etc/resolv.conf /mnt/gentoo/etc/

# copy kernel
echo "copying kernel image and modules"
mkdir /mnt/gentoo/etc/kernels
cp /etc/kernels/* /mnt/gentoo/etc/kernels
cp /mnt/cdrom/isolinux/gentoo{,.igz} /mnt/gentoo/boot
mkdir -p /mnt/gentoo/lib/modules
cp -Rp /lib/modules/`uname -r` /mnt/gentoo/lib/modules

# mount partitions
mount /dev/sda2 /mnt/gentoo/boot

mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

cp $SCRIPTS/install.sh /mnt/gentoo/
chmod +x /mnt/gentoo/install.sh
ls -la /mnt/gentoo/
sleep; sync; sleep

chroot /mnt/gentoo /bin/bash -c "whoami"

swapoff /dev/sda3
dd if=/dev/zero of=/dev/sda3
mkswap /dev/sda3

# finish
echo "All done."