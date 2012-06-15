#!/bin/sh -e

# set the build date and virtual box version
mkdir /etc/vagabond
date > /etc/vagabond/build_date
echo "<%= template %>" > /etc/vagabond/template
echo "<%= env.vbox_version %>" > /etc/vagabond/vbox_version

# disable screen blanking and make sure it is still disabled after a reboot
setterm -blank 0 -powersave off -powerdown 0
echo "setterm -blank 0 -powersave off -powerdown 0" >> /etc/rc.local.orig

#allow adm group to sudo without password
/bin/cp /etc/sudoers /etc/sudoers.orig
/bin/sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
/bin/sed -i -e 's/%admin ALL=(ALL) ALL/%adm ALL=NOPASSWD:ALL/g' /etc/sudoers

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
#apt-get -y dist-upgrade
apt-get -y install linux-headers-$(uname -r)
apt-get -y install build-essential libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison git

# install ACPI support so we can shut the machine down without ssh
# added this to the preseed
apt-get -y install acpi-support

# Install Ruby from source in /opt so that users of Vagrant
# can install their own Rubies using packages or however.
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
tar xvzf ruby-1.9.3-p194.tar.gz
cd ruby-1.9.3-p194
./configure
make
make install
cd ..
rm -rf ruby-1.9.3-p194

# Update RubyGems
echo "Updating RubyGem System..."
/usr/local/bin/gem update --system --no-ri --no-rdoc

echo "Updating installed gems..."
/usr/local/bin/gem update -y --no-ri --no-rdoc

#echo "Cleaning up gems..."
#/usr/local/bin/gem clean -q

# Install Bundler & chef
echo "Installing Bundler and Chef..."
/usr/local/bin/gem install -y bundler chef --no-ri --no-rdoc

# setup chef directories
mkdir /etc/chef
mkdir /var/chef
mkdir /var/chef/cache

# clone cookbooks
git clone https://github.com/ilude/Cookbooks.git /var/chef/cookbooks

# create solo.rb file
cat > /etc/chef/solo.rb<<EOF
json_attribs "/etc/chef/node.json"
cookbook_path "/var/chef/cookbooks"
file_cache_path "/var/chef/cache"
EOF

# create chef-update command
cat > /usr/local/bin/chef-update<<EOF
#!/bin/bash

pushd /var/chef/cookbooks
git pull
popd

chef-solo
EOF

chmod +x /usr/local/bin/chef-update

cat > /etc/chef/node.json<<EOF
{
  "user": {
    "name": "vagabond"
  },
  "run_list": ["recipe[default]"]
}
EOF

/usr/local/bin/chef-solo

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

cp /etc/rc.local /etc/vagabond
mv /etc/rc.local.orig /etc/rc.local
rm /etc/rc.local.orig

exit 0 