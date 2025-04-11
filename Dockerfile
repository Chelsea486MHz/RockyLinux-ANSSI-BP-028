FROM rockylinux:9.5

RUN dnf install -y epel-release
RUN dnf install -y xorriso syslinux createrepo dnf-plugins-core

WORKDIR /
ADD kickstarts /kickstarts
ADD iso-patch /iso-patch
ADD packages-to-add.txt /packages-to-add.txt
ADD build.sh /build.sh
RUN chmod +x /build.sh

ENTRYPOINT ["/build.sh"]