FROM debian:jessie

ENV APAXY_URL https://github.com/AdamWhitcroft/Apaxy/archive/master.tar.gz
ENV FOREGO_URL https://github.com/viranch/forego/releases/download/0.16.2/forego

RUN apt-get update; \
    apt-get install -y --no-install-recommends apache2 libapache2-mod-proxy-html transmission-daemon heirloom-mailx dnsutils cron minidlna curl; \
    curl -kL "$APAXY_URL" | tar -C /tmp/ -zx && mv /tmp/Apaxy-master/apaxy/* /var/www/html/ && rm -rf /tmp/Apaxy-master; \
    curl -kL "$FOREGO_URL" -o /usr/local/bin/forego && chmod a+x /usr/local/bin/forego; \
    apt-get purge -y curl && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

RUN cd /var/www/html; \
    sed -i 's/{FOLDERNAME}\///g' htaccess.txt; \
    mv htaccess.txt .htaccess; \
    mv theme/htaccess.txt theme/.htaccess; \
    sed -i '/explore.*header\.html.*footer\.html/d' theme/footer.html; \
    sed -i 's/NameWidth=\*/NameWidth=40/g' .htaccess

RUN for mod in proxy proxy_ajp proxy_balancer proxy_connect proxy_ftp proxy_html proxy_http proxy_scgi ssl xml2enc; do a2enmod $mod; done
ADD assets/config/apache2 /etc/apache2/conf-enabled/
ADD assets/dashboard/ /var/www/html/

ADD assets/config/transmission.json /opt/

ADD assets/config/minidlna.conf /etc/minidlna.conf

ADD assets/scripts/ /opt/scripts/

ADD assets/config/forego/ /opt/forego/

VOLUME /data
EXPOSE 80

ENTRYPOINT ["/opt/scripts/start.sh"]
CMD ["forego", "start", "-f", "/opt/forego/Procfile", "-e", "/opt/forego/env", "-r"]
