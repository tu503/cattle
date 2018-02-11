#!/bin/bash

# Get/Set VARS
# ZINT=`grep ^dhcp_interface /tmp/dhcp-dump | cut -f2 -d=`
# ZIP=`grep ^ip_address /tmp/dhcp-dump | cut -f2 -d=`
# ZCIDR=`grep ^subnet_cidr /tmp/dhcp-dump | cut -f2 -d=`
# ZDNS=`grep ^domain_name_servers /tmp/dhcp-dump | cut -f2 -d=`
# ZHOST=`grep ^host_name /tmp/dhcp-dump | cut -f2 -d=`
# ZINT=eno2

XHOST=192.168.88.209
REL=20170917
SNAP=${REL}

## Setup partion table and partions on local disk

for i in $(ls /dev/sda*|sort -r)
do
	echo $i
	dd if=/dev/zero of=$i count=256 bs=1024k
done

sgdisk -z /dev/sda
sgdisk -o /dev/sda

SECTORS=`sgdisk -p /dev/sda | grep ^'Total free space is' | cut -f5 -d' '`

echo SECTORS: ${SECTORS}
echo MEGABYTES: $((SECTORS/2048))

END=$(sgdisk -E /dev/sda)

START=$(sgdisk -F /dev/sda)
sgdisk -n 1:${START}:$((START+(2048*8))) -t 1:ef02 -c 1:"BIOS Boot" /dev/sda

START=`sgdisk -F /dev/sda`
sgdisk -n 2:${START}:$((START+(2048*512))) -t 2:8300 -c 2:"/boot" /dev/sda

START=`sgdisk -F /dev/sda`
sgdisk -n 3:${START}:$((START+(2048*4096))) -t 3:8200 -c 3:"swap" /dev/sda

START=`sgdisk -F /dev/sda`
sgdisk -n 4:${START}:${END} -t 4:8300 -c 4:"/" /dev/sda 

## Format partions

mkfs.ext4 -F /dev/sda2
mkfs.ext4 -F /dev/sda4
mkswap /dev/sda3

MP=/mnt/gentoo

mkdir -p ${MP}
mount /dev/sda4 ${MP}
mkdir -p ${MP}/boot
mkdir -p ${MP}/etc
mkdir -p ${MP}/etc/conf.d
mount /dev/sda2 ${MP}/boot

# can't wget w/o network, see /etc/init.d/setup

URI=http://${XHOST}/stage4-amd64-systemd-latest.tar.bz2
wget -O - ${URI} | tar xjf - -C ${MP}

URI=http://${XHOST}/portage-latest.tar.bz2
wget -O - ${URI} | tar xjf - -C ${MP}/usr

cat << EOT > ${MP}/etc/fstab
/dev/sda2               /boot           ext4            noauto,noatime  1 2
/dev/sda4               /               ext4            noatime         0 1
/dev/sda3               none            swap            sw              0 0
#10.175.188.54:/shared   /mnt/shared  nfs auto,rw,bg,hard,intr,tcp,vers=3,rsize=32768,wsize=32768,timeo=600
EOT

# ls /sys/class/net/*/address | grep -v '/lo/'

# needs configuration
cat << EOT > ${MP}/etc/conf.d/net
#config_eno1="dhcp"
#routes_eno1="default via 192.168.88.1"
config_${ZINT}="${ZIP}/${ZCIDR}"
EOT

# need to set /etc/resolv.conf to dhcp value
cat << EOT > ${MP}/etc/resolv.conf
nameserver 192.168.88.209
#nameserver ${ZDNS}
EOT

# cd /mnt/gentoo/etc/init.d
#ln -s net.lo net.eno1
# ln -s net.lo net.${ZINT}

# cd /mnt/gentoo/etc/runlevels/default
#ln -s /etc/init.d/net.eno1
# ln -s /etc/init.d/net.${ZINT}
# ln -s /etc/init.d/sshd

cat << EOT > ${MP}/etc/conf.d/hostname 
# Set to the hostname of this machine
hostname="${ZHOST}"
EOT

sed -i 's/root:\*/root:$6$9v2bT0AA$\/dkXNpUDnEyuyA3tXzmT1Hmcsou4XYYNX7b89Xh8UXIRhO5ChnGHpyKccMMugPnLyaMtZW\/oUb6H.5J4T53xN1/' ${MP}/etc/shadow

(cd ${MP} && mount -t proc none proc)
(cd ${MP} && mount --rbind /sys sys)
(cd ${MP} && mount --rbind /dev dev) 
(cd ${MP} && chroot . eselect python set 1)
(cd ${MP} && chroot . grub-install /dev/sda)
(cd ${MP} && chroot . grub-mkconfig -o /boot/grub/grub.cfg)
(cd ${MP} && chroot . echo sm3 >/etc/hostname)
(cd ${MP} && chroot . systemd-machine-id-setup)
(cd ${MP} && chroot . systemctl enable systemd-networkd.service)
(cd ${MP} && chroot . ln -snf /run/systemd/resolve/resolv.conf /etc/resolv.conf)
(cd ${MP} && chroot . systemctl enable systemd-resolved.service)
(cd ${MP} && chroot . systemctl enable sshd.service)

# Enable serial tty's so "virsh console" works
sed -i 's/^#s0:/s0:/' ${MP}/etc/inittab 
#sed -i 's/^#s1:/s1:/' ${MP}/etc/inittab 

# umount /mnt/gentoo/dev
# umount /mnt/gentoo/sys
# umount /mnt/gentoo/proc
# umount /mnt/gentoo/boot
# umount /mnt/gentoo

#scp /etc/init.d/setup ${XHOST}:/root/catalyst/root_overlay/netboot2/etc/init.d/setup
#scp /root/.scripts/setup.bsh ${XHOST}:/root/catalyst/root_overlay/netboot2/root/.scripts/setup.bsh
### shutdown -r now && exit
