# Clean up
#apt-get -y remove linux-headers-$(uname -r) build-essential
apt-get --yes autoremove
apt-get --yes clean

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces
