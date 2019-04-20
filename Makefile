
all:
	./do-snapshot.bsh \
	&& ./do-stage1-systemd.bsh \
	&& ./do-stage2-systemd.bsh \
	&& ./do-stage3-systemd.bsh \
	&& ./do-stage4-systemd.bsh \
	&& ./do-ceph-systemd.bsh

