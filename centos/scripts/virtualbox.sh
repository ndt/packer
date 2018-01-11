VBOX_VERSION=$(cat /root/.vbox_version)

cd /tmp
mount -o loop /root/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run --nox11
umount /mnt
rm -rf /root/VBoxGuestAdditions_*.iso
rm -f /root/.vbox_version

