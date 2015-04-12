FROM base/archlinux

# Base pacman setup
RUN pacman --noprogressbar --noconfirm -Syy archlinux-keyring

# Source: https://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/
ENV container docker
RUN rm -f `find /lib/systemd/system/sysinit.target.wants -maxdepth 1 -type l ! -regex ".*/systemd-tmpfiles-setup.service"` \
        /etc/systemd/system/*.wants/* \
        /lib/systemd/system/{multi-user,local-fs,basic}.target.wants/* \
        /lib/systemd/system/sockets.target.wants/*{udev,initctl}*

# Install our stuff
RUN pacman --noprogressbar --noconfirm -S apache dnsutils s-nail transmission-cli cronie minidlna
ADD assets/systemd/ /etc/systemd/system/
ADD assets/tr_email.sh assets/tv.sh assets/start.sh /opt/scripts/

# transmission
ADD assets/transmission.json /opt/

# httpd
ADD assets/tr_httpd.conf /etc/httpd/conf/extra/transmission.conf

# minidlna
ADD assets/minidlna.conf /etc/minidlna.conf

# Setup
RUN systemctl enable httpd transmission cronie minidlna; \
    chmod a+x /opt/scripts/tr_email.sh /opt/scripts/tv.sh /opt/scripts/start.sh; \
    echo "Include conf/extra/transmission.conf" >> /etc/httpd/conf/httpd.conf

# Declare binds
VOLUME [ "/data" ]
EXPOSE 80

# Run command
CMD ["/opt/scripts/start.sh"]
