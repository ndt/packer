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

chroot /mnt/gentoo /bin/bash <<'EOF'
alias e='MAKEOPTS="-j5" emerge -j2 --buildpkg'

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
e ">=sys-boot/grub-2.0" sys-kernel/gentoo-sources sys-kernel/genkernel-next

# install grub
echo "set timeout=0" >> /etc/grub.d/40_custom
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# install kernel
cp $SCRIPTS/kernel.config /mnt/gentoo/tmp/
chroot /mnt/gentoo /bin/bash <<'EOF'
alias e='MAKEOPTS="-j5" emerge -j2 --buildpkg'

cd /usr/src/linux
mv /tmp/kernel.config .config
genkernel --install --symlink --oldconfig --makeopts=-j5 --no-color all

# emerge packages
e @world -uDN
e ">=app-emulation/virtualbox-guest-additions-4.3"

# install virtualbox additions
rc-update add virtualbox-guest-additions default


# clean up
emerge --depclean

rm -rf /tmp/*
rm -rf /var/log/*
rm -rf /var/tmp/*
EOF

swapoff /dev/sda3
dd if=/dev/zero of=/dev/sda3
mkswap /dev/sda3

# finish
echo "All done."
