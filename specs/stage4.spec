# distcc_hosts:
# portage_overlay:
# pkgcache_path:
# kerncache_path:
stage4/use:
stage4/packages:
	gentoolkit
	grub
	vim
	etcd
	app-misc/tmux
	dev-lang/go
	sys-apps/ipmitool
	dev-go/go-bindata
	sys-fs/btrfs-progs
	app-emulation/docker
	sys-cluster/kube-apiserver
	sys-cluster/kube-controller-manager
	sys-cluster/kube-proxy
	sys-cluster/kube-scheduler
	sys-cluster/kubectl
	sys-cluster/kubelet
	net-misc/socat
	net-misc/cni-plugins
	app-emulation/flannel
	net-firewall/conntrack-tools
# stage4/fsscript:
# stage4/splash_theme:
# stage4/gk_mainargs:
# stage4/linuxrc:
# stage4/motd:
# stage4/modblacklist:
# stage4/rcadd:
# stage4/rcdel:
# stage4/root_overlay:
# stage4/xinitrc:
# stage4/users:
boot/kernel: gentoo
boot/kernel/gentoo/sources: gentoo-sources
boot/kernel/gentoo/config: /root/cattle/kernel-config/kernel-config-x86_64-4.14.12-gentoo
# boot/kernel/gentoo/gk_kernargs:
# boot/kernel/gentoo/use:
# boot/kernel/gentoo/extraversion:
# boot/kernel/gentoo/packages:
# stage4/unmerge:
# stage4/empty:
# stage4/rm:
