#!/bin/sh

set -e
set -x

#######################################################################
# Debconf Dialog frontend does not work without a controlling terminal
# We restore this in the end
#######################################################################
echo 'debconf debconf/frontend select Noninteractive' | \
	debconf-set-selections

#######################################################################
# setup hostname
#######################################################################
if [ -n "$hostname" ]; then
  echo "${hostname%%.*}" > /etc/hostname
fi

#######################################################################
# speed up tweaks
#######################################################################

# Prevent DNS resolution (speed up logins)
echo 'UseDNS no' >> /etc/ssh/sshd_config
# Disable password logins
echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config

# Reduce grub timeout to 1s to speed up booting
[ -f /etc/default/grub ] && \
  sed -i s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/ /etc/default/grub

# Updating grub config right now is only safe if we are not in a chroot
# otherwise  grub complains on the lack of a mounted /
[ -x /usr/sbin/update-grub ] && \
  mountpoint -q /dev/ && \
  /usr/sbin/update-grub

#######################################################################
# cleanup
#######################################################################
apt-get clean
echo 'debconf debconf/frontend select Dialog' | \
    debconf-set-selections

# make sure /etc/machine-id is generated on next book
# /etc/machine-id needs to be unique so multiple systemd-networkd dhcp clients
# get different ip addresses from the DHCP server
rm /var/lib/dbus/machine-id
> /etc/machine-id
