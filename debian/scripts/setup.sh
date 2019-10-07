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
# upgrade Debian images as the LXC template does not do it.
#######################################################################
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
apt-get update
apt-get -qy dist-upgrade

#######################################################################
# install packages from the 'important' and 'standard' sets
#######################################################################
apt-get install -qy dctrl-tools
grep-aptavail --no-field-names --show-field Package --field Priority --regex 'standard\|important' \
  | xargs apt-get install -qy pinentry-curses
  # avoid gnupg-agent pulling pinentry-gtk2 on jessie_|
apt-get purge -qy dctrl-tools

#######################################################################
# setup packer user
#######################################################################
id packer >/dev/null 2>&1 || useradd --create-home --uid 1000 --shell /bin/bash packer
mkdir -p /home/packer/.ssh
chmod 700 /home/packer/.ssh
cat > /home/packer/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== packer insecure public key
EOF
chmod 600 /home/packer/.ssh/authorized_keys
chown -R packer:packer /home/packer/.ssh

#######################################################################
# setup passwordless sudo for packer user
#######################################################################
apt-get install -qy sudo
cat > /etc/sudoers.d/packer <<EOF
packer ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/packer

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
rm -f /usr/sbin/policy-rc.d
echo 'debconf debconf/frontend select Dialog' | \
    debconf-set-selections

# make sure /etc/machine-id is generated on next book
# /etc/machine-id needs to be unique so multiple systemd-networkd dhcp clients
# get different ip addresses from the DHCP server
rm /var/lib/dbus/machine-id
> /etc/machine-id
