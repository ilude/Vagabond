# Fix SMBus error on boot in virtualbox
/bin/echo 'blacklist i2c_piix4' >> /etc/modprobe.d/blacklist.conf
/usr/sbin/update-initramfs -u -k all

/bin/cp /etc/rc.local /etc/rc.local.orig
/bin/rm /etc/rc.local
/usr/bin/wget http://<%= env.host %>:<%= env.port %>/postinstall.sh -O /etc/rc.local

/bin/chmod 755 /etc/rc.local

exit 0