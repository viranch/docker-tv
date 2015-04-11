FROM base/archlinux

RUN pacman --noprogressbar --noconfirm -Syy archlinux-keyring

RUN pacman --noprogressbar --noconfirm -S apache transmission-cli

# Source: https://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/
ENV container docker
RUN rm -f `find /lib/systemd/system/sysinit.target.wants -maxdepth 1 -type l ! -regex ".*/systemd-tmpfiles-setup.service"`; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/{multi-user,local-fs,basic}.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*{udev,initctl}*;

RUN systemctl enable httpd
EXPOSE 80
VOLUME [ "/srv/http" ]

CMD ["/usr/bin/init"]
