#!/bin/bash

# Get/Set VARS
# ZINT=$(grep ^dhcp_interface /tmp/dhcp-dump | cut -f2 -d=)
# ZIP=$(grep ^ip_address /tmp/dhcp-dump | cut -f2 -d=)
# ZCIDR=$(grep ^subnet_cidr /tmp/dhcp-dump | cut -f2 -d=)
# ZDNS=$(grep ^domain_name_servers /tmp/dhcp-dump | cut -f2 -d=)
# ZHOST=$(grep ^host_name /tmp/dhcp-dump | cut -f2 -d=)
# ZINT=eno2

XHOST=192.168.88.66
REL=201808131835
REL=latest
SNAP=${REL}

## Setup partion table and partions on local disk

DISK=$(lsblk -S | grep SSD | awk '{ print $1 }')

for PART in $(ls /dev/${DISK}*|sort -r)
do
	echo ${PART}
	dd if=/dev/zero of=${PART} bs=4096k count=32
done

sgdisk -z /dev/${DISK}
sgdisk -o /dev/${DISK}

SECTORS=$(sgdisk -p /dev/${DISK} | grep ^'Total free space is' | cut -f5 -d' ')

echo SECTORS: ${SECTORS}
echo MEGABYTES: $((SECTORS/2048))

END=$(sgdisk -E /dev/${DISK})

START=$(sgdisk -F /dev/${DISK})
sgdisk -n 1:${START}:$((START+(2048*8))) -t 1:ef02 -c 1:"BIOS Boot" /dev/${DISK}

START=$(sgdisk -F /dev/${DISK})
sgdisk -n 2:${START}:$((START+(2048*512))) -t 2:8300 -c 2:"/boot" /dev/${DISK}

START=$(sgdisk -F /dev/${DISK})
sgdisk -n 3:${START}:$((START+(2048*4096))) -t 3:8200 -c 3:"swap" /dev/${DISK}

START=$(sgdisk -F /dev/${DISK})
sgdisk -n 4:${START}:${END} -t 4:8300 -c 4:"/" /dev/${DISK} 

## Format partions

mkfs.ext4 -F /dev/${DISK}2
mkfs.ext4 -F /dev/${DISK}4
mkswap /dev/${DISK}3

MP=/mnt/gentoo

mkdir -p ${MP}
mount /dev/${DISK}4 ${MP}
mkdir -p ${MP}/boot
mkdir -p ${MP}/etc
mkdir -p ${MP}/etc/conf.d
mount /dev/${DISK}2 ${MP}/boot

# can't wget w/o network, see /etc/init.d/setup

### URI=http://${XHOST}/stage4-amd64-systemd-latest.tar.bz2
### wget -O - ${URI} | tar xjf - -C ${MP}

BASE_IMAGE=$(ls -rt /data/catalyst/builds/*/stage4-*.tar.bz2 | tail -1)
echo "tar xjf ${BASE_IMAGE} -C ${MP}"
tar xjf ${BASE_IMAGE} -C ${MP}

### URI=http://${XHOST}/portage-latest.tar.bz2
### wget -O - ${URI} | tar xjf - -C ${MP}/usr

PORT_SNAP=$(ls -rt /data/catalyst/snapshots/portage-*.tar.bz2 | tail -1)
echo "tar xjf ${PORT_SNAP} -C ${MP}/usr"
tar xjf ${PORT_SNAP} -C ${MP}/usr

DATA_DISK=$(lsblk -S | grep V00 | awk '{ print $1 }')
STOR_DISK=$(lsblk -S | grep 5805 | awk '{ print $1 }')

BOOT_UUID=$(blkid /dev/${DISK}2 | cut -f2 -d' ')
ROOT_UUID=$(blkid /dev/${DISK}4 | cut -f2 -d' ')
SWAP_UUID=$(blkid /dev/${DISK}3 | cut -f2 -d' ')

cat << EOT > ${MP}/etc/fstab

# /dev/${DISK}2               /boot           ext4            noauto,noatime  1 2
# /dev/${DISK}4               /               ext4            noatime         0 1
# /dev/${DISK}3               none            swap            sw              0 0
${BOOT_UUID}          /boot           ext4            noauto,noatime  1 2
${ROOT_UUID}          /               ext4            noatime         0 1
${SWAP_UUID}          none            swap            sw              0 0

# /dev/${DATA_DISK}1          /data           btrfs           noatime         0 1
# /dev/${STOR_DISK}1          /store8         btrfs           noatime         0 1
UUID="708bc1d8-8a89-4f79-8bc7-d5dd62117701" /data btrfs noatime 0 1
UUID="80f92afa-a0e8-4d38-803a-320a8be4b86b" /store8 btrfs noatime 0 1

EOT

mkdir -p ${MP}/{data,store8}

cat << EOT > ${MP}/etc/systemd/timesyncd.conf
[Time]
NTP=utcnist.colorado.edu
FallbackNTP=0.gentoo.pool.ntp.org 1.gentoo.pool.ntp.org 2.gentoo.pool.ntp.org 3.gentoo.pool.ntp.org
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOT

echo -n "root password: " && read -s PASSWORD && export PASSWORD && echo

echo "root:${PASSWORD}" | chpasswd -R ${MP}
echo sm3 > ${MP}/etc/hostname

####
cat > ${MP}/etc/portage/make.conf << EOT
COMMON_FLAGS="-O2 -pipe"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"
PORTDIR="/usr/portage"
DISTDIR="/data/catalyst/distfiles"
PKGDIR="/data/catalyst/binpkgs"
LC_MESSAGES=C
MAKEOPTS="-j25"
GENTOO_MIRRORS="http://mirrors.evowise.com/gentoo/ http://104.19.138.75/gentoo/ http://104.19.137.75/gentoo/ http://104.19.135.75/gentoo/ http://104.19.139.75/gentoo/"
EOT
####

ln -sf /usr/portage/profiles/default/linux/amd64/17.0/systemd ${MP}/etc/portage/make.profile

(cd ${MP} && mount -t proc none proc)
(cd ${MP} && mount --rbind /sys sys)
(cd ${MP} && mount --rbind /dev dev) 
(cd ${MP} && chroot . eselect python set 1)
(cd ${MP} && chroot . grub-install /dev/${DISK})
(cd ${MP} && chroot . grub-mkconfig -o /boot/grub/grub.cfg)
(cd ${MP} && chroot . systemd-machine-id-setup)
(cd ${MP} && chroot . ln -snf /run/systemd/resolve/resolv.conf /etc/resolv.conf)
(cd ${MP} && chroot . systemctl enable systemd-networkd.service)
(cd ${MP} && chroot . systemctl enable systemd-timesyncd.service)
(cd ${MP} && chroot . systemctl enable systemd-resolved.service)
(cd ${MP} && chroot . systemctl enable syslog-ng@default.service)
(cd ${MP} && chroot . systemctl enable rsyncd.service)
(cd ${MP} && chroot . systemctl enable sshd.service)

# umount /mnt/gentoo/dev
# umount /mnt/gentoo/sys
# umount /mnt/gentoo/proc
# umount /mnt/gentoo/boot
# umount /mnt/gentoo

# shutdown -r now && exit

