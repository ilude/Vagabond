cpus '1'
memory '384'
disk_size '10140'
disk_format 'VDI'
hostiocache 'off'
os_type 'Ubuntu_64'
iso_file "ubuntu-12.04-server-amd64.iso"
iso_src "http://releases.ubuntu.com/12.04/ubuntu-12.04-server-amd64.iso"
iso_md5 "f2e921788d35bbdf0336d05d228136eb"
boot_wait 10
boot_cmd_sequence [
  '<Esc><Esc><Enter><Wait>',
  '/install/vmlinuz noapic preseed/url=http://%IP%:%PORT%/preseed.cfg ',
  'debian-installer=en_US auto locale=en_US kbd-chooser/method=us ',
  'hostname=%NAME% ',
  'fb=false debconf/frontend=noninteractive ',
  'keyboard-configuration/layout=USA keyboard-configuration/variant=USA console-setup/ask_detect=false ',
  'initrd=/install/initrd.gz -- <Enter>'
]
install_files ["preseed.cfg", "latecommand.sh", "postinstall.sh"]