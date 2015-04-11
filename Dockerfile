FROM base/archlinux

RUN pacman --noprogressbar --noconfirm -Syy archlinux-keyring

RUN pacman --noprogressbar --noconfirm -S apache dnsutils s-nail transmission-cli python2 cronie

# Source: https://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/
ENV container docker
RUN rm -f `find /lib/systemd/system/sysinit.target.wants -maxdepth 1 -type l ! -regex ".*/systemd-tmpfiles-setup.service"`; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/{multi-user,local-fs,basic}.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*{udev,initctl}*;

# Apache
RUN systemctl enable httpd
EXPOSE 80

# Transmission
RUN systemctl enable transmission
ADD assets/transmission.json /opt/
ADD assets/tr_email.sh /opt/scripts/tr_email.sh
RUN chmod a+x /opt/scripts/tr_email.sh
ADD assets/tv.sh /opt/scripts/
RUN chmod a+x /opt/scripts/tv.sh
ADD assets/tr_httpd.conf /etc/httpd/conf/extra/transmission.conf
RUN echo "Include conf/extra/transmission.conf" >> /etc/httpd/conf/httpd.conf

# Cron
RUN systemctl enable cronie

VOLUME [ "/data" ]

# Run command
ADD assets/start.sh /opt/
RUN chmod a+x /opt/start.sh
CMD ["/opt/start.sh"]
