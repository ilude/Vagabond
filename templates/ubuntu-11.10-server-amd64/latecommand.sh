/bin/cp /etc/sudoers /etc/sudoers.orig
/bin/sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
/bin/sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

/bin/cp /etc/ssh/sshd_conf /etc/ssh/sshd_conf.orig
/bin/sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_conf

# Fix SMBus error on boot in virtualbox
/bin/echo 'blacklist i2c_piix4' >> /etc/modprobe.d/blacklist.conf
/usr/sbin/update-initramfs -u -k all

/bin/cp /etc/rc.local /etc/rc.local.orig
/bin/rm /etc/rc.local
/usr/bin/wget http://<%= env.host %>:<%= env.port %>/postinstall.sh -O /etc/rc.local

/bin/chmod 755 /etc/rc.local

exit 0