FROM rockylinux:9.3

RUN dnf install -y epel-release
RUN dnf install -y xorriso syslinux createrepo dnf-plugins-core

WORKDIR /
ADD build.sh /build.sh
RUN chmod +x /build.sh

ENTRYPOINT ["/build.sh"]