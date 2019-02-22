source_subpath: default/livecd-stage1-amd64-installer-latest

livecd/cdtar: /usr/share/catalyst/livecd/cdtar/isolinux-elilo-memtest86+-cdtar.tar.bz2
livecd/fsscript: /root/cattle/chpasswd.bsh
livecd/fstype: squashfs
livecd/iso: /var/www/localhost/htdocs/livecd.iso
livecd/type: gentoo-release-livecd
livecd/volid: Gen2

#livecd/overlay: @REPO_DIR@/releases/latest/overlays/common/overlay/livecd
#livecd/root_overlay: @REPO_DIR@/releases/latest/overlays/common/root_overlay

boot/kernel: gentoo
boot/kernel/gentoo/sources: gentoo-sources
boot/kernel/gentoo/config: /root/kernel-config/kernel-config-x86_64-latest-gentoo
boot/kernel/gentoo/use: atm png truetype usb
boot/kernel/gentoo/packages:
	media-libs/alsa-oss
	media-sound/alsa-utils
	net-wireless/hostap-utils
	sys-apps/pcmciautils
	sys-kernel/linux-firmware
	sys-fs/ntfs3g

livecd/empty:
	/var/tmp
	/var/empty
	/var/run
	/var/state
	/var/cache/edb/dep
	/tmp
	/usr/portage
	/usr/src
	/root/.ccache
	/usr/share/genkernel/pkg/x86/cpio

livecd/rm:
	/etc/*-
	/etc/*.old
	/root/.viminfo
	/var/log/*.log
	/usr/share/genkernel/pkg/amd64/*.bz2
