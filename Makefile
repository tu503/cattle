
all: snapshot stage3
	./do-stage4-systemd.bsh \
	&& ./do-ceph-systemd.bsh

stage3: snapshot
	./do-stage1-systemd.bsh \
	&& ./do-stage2-systemd.bsh \
	&& ./do-stage3-systemd.bsh \

snapshot:
	./do-snapshot.bsh
