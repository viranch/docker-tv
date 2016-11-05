FROM debian:jessie

# Download & install all required packages
RUN apt-get update; \
    apt-get install -y --no-install-recommends apache2 libapache2-mod-proxy-html transmission-daemon curl heirloom-mailx dnsutils cron minidlna; \
    rm -rf /var/lib/apt/lists/*

# Install forego
RUN FOREGO_URL="https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz"; \
    curl -kL $FOREGO_URL | tar -C /usr/local/bin/ -zx

# Install github.com/viranch/tivo
RUN TIVO_URL="https://github.com/viranch/tivo/releases/download/0.3/tivo-linux-amd64-0.3.tar.gz"; \
    curl -kL $TIVO_URL | tar -C /usr/local/bin/ -zx

# Setup apache
RUN for mod in headers proxy proxy_ajp proxy_balancer proxy_connect proxy_ftp proxy_html proxy_http proxy_scgi ssl xml2enc; do a2enmod $mod; done
COPY assets/config/apache2 /etc/apache2/conf-enabled/
COPY assets/dashboard/ assets/apaxy/ /var/www/html/

# Setup transmission
COPY assets/config/transmission.json /opt/

# Setup minidlna
COPY assets/config/minidlna.conf /etc/minidlna.conf

# Add required scripts
COPY assets/scripts/ /opt/scripts/

# Setup forego, our process supervisor
COPY assets/config/forego/ /opt/forego/

# Finally declare public things
VOLUME /data
EXPOSE 80

# Define how to run the image
ENTRYPOINT ["/opt/scripts/start.sh"]
CMD ["forego", "start", "-f", "/opt/forego/Procfile", "-e", "/opt/forego/env", "-r"]
