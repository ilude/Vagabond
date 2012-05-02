#!/bin/sh -e
# set the build date and virtual box version
date > /etc/vagabond_build_date
echo "<%= env.vbox_version %>" > /etc/vagabond_vbox_version
#echo "4.1.8" > /etc/vagabond_vbox_version

# disable screen blanking
setterm -blank 0

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
apt-get -y dist-upgrade
apt-get -y install linux-headers-$(uname -r)
apt-get -y install build-essential libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison curl git

# install ACPI support so we can shut the machine down without ssh
apt-get -y install acpi-support

# Install Ruby from source in /opt so that users of Vagrant
# can install their own Rubies using packages or however.
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p125.tar.gz
tar xvzf ruby-1.9.3-p125.tar.gz
cd ruby-1.9.3-p125
./configure
make
make install
cd ..
rm -rf ruby-1.9.3-p125

# Update RubyGems
/usr/local/bin/gem update --system --no-ri --no-rdoc
/usr/local/bin/gem update --no-ri --no-rdoc
/usr/local/bin/gem clean

# Install Bundler & chef
/usr/local/bin/gem install bundler chef --no-ri --no-rdoc

# Installing vagrant keys
#mkdir /home/vagrant/.ssh
#chmod 700 /home/vagrant/.ssh
#cd /home/vagrant/.ssh
#wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
#chmod 600 /home/vagrant/.ssh/authorized_keys
#chown -R vagrant /home/vagrant/.ssh

# Installing the virtualbox guest additions
#VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
#cd /tmp
#wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
#mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
#sh /mnt/VBoxLinuxAdditions.run
#rm VBoxGuestAdditions_$VBOX_VERSION.iso

#VBOX_VERSION=$(cat /etc/vagabond_vbox_version)
#wget http://download.virtualbox.org/virtualbox/4.1.8/VBoxGuestAdditions_4.1.8.iso
#wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
#mount -o loop,ro VBoxGuestAdditions_4.1.8.iso
#mount -o loop,ro VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
#sh /mnt/VBoxLinuxAdditions.run
#umount /mnt
#rm VBoxGuestAdditions_4.1.8.iso
#rm VBoxGuestAdditions_$VBOX_VERSION.iso
#unset VBOX_VERSION

# Remove items used for building, since they aren't needed anymore
# apt-get -y remove linux-headers-$(uname -r) build-essential
apt-get -y clean
apt-get -y autoclean
apt-get -y autoremove

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces

mv /etc/rc.local.orig /etc/rc.local

exit 0 