# distcc_hosts:
# portage_overlay:
# pkgcache_path:
# kerncache_path:
netboot2/use:
netboot2/packages:
	app-editors/vim
	sys-apps/gptfdisk
# netboot2/fsscript:
# netboot2/splash_theme:
# netboot2/gk_mainargs:
# netboot2/linuxrc:
# netboot2/motd:
# netboot2/modblacklist:
# netboot2/rcadd:
# netboot2/rcdel:
# netboot2/root_overlay:
# netboot2/xinitrc:
# netboot2/users:
boot/kernel: gentoo
boot/kernel/gentoo/sources: gentoo-sources
boot/kernel/gentoo/config: /root/cattle/kernel-config/kernel-config-x86_64-4.14.12-gentoo
boot/kernel/gentoo/gk_kernargs: --all-ramdisk-modules
# boot/kernel/gentoo/use:
# boot/kernel/gentoo/extraversion:
# boot/kernel/gentoo/packages:
# netboot2/unmerge:
# netboot2/empty:
# netboot2/rm:
