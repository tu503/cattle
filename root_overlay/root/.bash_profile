set -o vi
alias eupdate='emerge -qauND --with-bdeps=y --changed-deps --backtrack=1024 @world && emerge --depclean && revdep-rebuild -i'
# alias copy-kernel-config="cp -v /etc/kernels/kernel-config-x86_64-$(uname -r) /etc/kernels/kernel-config-x86_64-$(ls -drt /usr/src/linux-*-gentoo* | tail -1 | cut -f2,3,4 -d-)"
