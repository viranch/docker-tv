FROM base/archlinux

# Base pacman setup
RUN pacman --noprogressbar --noconfirm -Syy archlinux-keyring

# Source: https://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/
ENV container docker
RUN rm -f `find /lib/systemd/system/sysinit.target.wants -maxdepth 1 -type l ! -regex ".*/systemd-tmpfiles-setup.service"` \
        /etc/systemd/system/*.wants/* \
        /lib/systemd/system/{multi-user,local-fs,basic}.target.wants/* \
        /lib/systemd/system/sockets.target.wants/*{udev,initctl}*

# httpd
RUN pacman --noprogressbar --noconfirm -S openssl apache
ADD assets/config/httpd/ /etc/httpd/conf/

# transmission
RUN pacman --noprogressbar --noconfirm -S dnsutils s-nail transmission-cli
ADD assets/config/transmission.json /opt/

# minidlna
RUN pacman --noprogressbar --noconfirm -S minidlna
ADD assets/config/minidlna.conf /etc/minidlna.conf

# search page
ADD assets/search/ /srv/http/search/

# dashboard page
ADD assets/dashboard/ /srv/http/dashboard/

# Install our stuff
RUN pacman --noprogressbar --noconfirm -S cronie
ADD assets/scripts/ /opt/scripts/
ADD assets/systemd/ /etc/systemd/system/

# Setup
RUN systemctl enable httpd transmission minidlna cronie; \
    chmod a+x /opt/scripts/*

# Declare binds
VOLUME [ "/data" ]
EXPOSE 80

# Run command
CMD ["/opt/scripts/start.sh"]
