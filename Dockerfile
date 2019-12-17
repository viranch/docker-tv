FROM ubuntu:xenial

# Download & install all required packages
RUN apt-get update; \
    apt-get install -y --no-install-recommends apache2 apache2-bin transmission-daemon curl ca-certificates cron jq libxml2-utils; \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# Install forego
RUN FOREGO_URL="https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz"; \
    curl -kL $FOREGO_URL | tar -C /usr/local/bin/ -zx

# Install Jackett
RUN JACKETT_VERSION="0.12.1227"; \
    JACKETT_URL="https://github.com/Jackett/Jackett/releases/download/v${JACKETT_VERSION}/Jackett.Binaries.LinuxAMDx64.tar.gz"; \
    curl -L "$JACKETT_URL" | tar -C /opt/ -zx

# Setup apache
RUN for mod in headers proxy proxy_ajp proxy_balancer proxy_connect proxy_ftp proxy_html proxy_http proxy_scgi ssl xml2enc; do a2enmod $mod; done
COPY assets/config/apache2 /etc/apache2/conf-enabled/
COPY assets/dashboard/ assets/apaxy/ /var/www/html/

# Setup transmission
COPY assets/config/transmission.json /opt/

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
