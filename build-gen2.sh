#!/bin/bash

# Get/Set VARS
# ZINT=`grep ^dhcp_interface /tmp/dhcp-dump | cut -f2 -d=`
# ZIP=`grep ^ip_address /tmp/dhcp-dump | cut -f2 -d=`
# ZCIDR=`grep ^subnet_cidr /tmp/dhcp-dump | cut -f2 -d=`
# ZDNS=`grep ^domain_name_servers /tmp/dhcp-dump | cut -f2 -d=`
# ZHOST=`grep ^host_name /tmp/dhcp-dump | cut -f2 -d=`
# ZINT=eno2

XHOST=192.168.88.34
REL=201808131835
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
/dev/sdb                /data           btrfs           noauto          0 1
EOT

mkdir -p ${MP}/data

cat << EOT > ${MP}/etc/systemd/timesyncd.conf
[Time]
NTP=utcnist.colorado.edu
FallbackNTP=0.gentoo.pool.ntp.org 1.gentoo.pool.ntp.org 2.gentoo.pool.ntp.org 3.gentoo.pool.ntp.org
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOT

echo "root:!jacks" | chpasswd -R ${MP}
echo sm3 > ${MP}/etc/hostname

(cd ${MP} && mount -t proc none proc)
(cd ${MP} && mount --rbind /sys sys)
(cd ${MP} && mount --rbind /dev dev) 
(cd ${MP} && chroot . eselect python set 1)
(cd ${MP} && chroot . grub-install /dev/sda)
(cd ${MP} && chroot . grub-mkconfig -o /boot/grub/grub.cfg)
(cd ${MP} && chroot . systemd-machine-id-setup)
(cd ${MP} && chroot . systemctl enable systemd-networkd.service)
(cd ${MP} && chroot . systemctl enable systemd-timesyncd.service)
(cd ${MP} && chroot . ln -snf /run/systemd/resolve/resolv.conf /etc/resolv.conf)
(cd ${MP} && chroot . systemctl enable systemd-resolved.service)
(cd ${MP} && chroot . systemctl enable sshd.service)

# umount /mnt/gentoo/dev
# umount /mnt/gentoo/sys
# umount /mnt/gentoo/proc
# umount /mnt/gentoo/boot
# umount /mnt/gentoo

# shutdown -r now && exit

