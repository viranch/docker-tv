FROM arm32v7/mono

# Download & install all required packages
RUN apt-get update; \
    apt-get install -y --no-install-recommends apache2 apache2-bin transmission-daemon curl heirloom-mailx dnsutils ca-certificates cron jq; \
    rm -rf /var/lib/apt/lists/*

# Install forego
RUN FOREGO_URL="https://github.com/viranch/forego/releases/download/0.16.2/forego-linux-armv7.tar.gz"; \
    curl -L $FOREGO_URL | tar -C /usr/local/bin/ -zx

# Install Jackett
RUN mkdir -p /opt/jackett /data/jackett/config; \
    JACKETT_RELEASE=`curl -s "https://api.github.com/repos/Jackett/Jackett/releases/latest" | jq -r .tag_name`; \
    JACKETT_URL=`curl -s https://api.github.com/repos/Jackett/Jackett/releases/tags/"${JACKETT_RELEASE}" | jq -r '.assets[].browser_download_url' | grep Mono`; \
    curl -L "$JACKETT_URL" | tar -C /opt/jackett --strip-components=1 -zx

# Install github.com/viranch/tivo
RUN TIVO_VERSION="0.8"; \
    TIVO_URL="https://github.com/viranch/tivo/releases/download/$TIVO_VERSION/tivo-linux-armv7-$TIVO_VERSION.tar.gz"; \
    curl -kL $TIVO_URL | tar -C /usr/local/bin/ -zx

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
