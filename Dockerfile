FROM ubuntu:xenial

# Download & install all required packages
RUN apt-get update; \
    apt-get install -y --no-install-recommends apache2 apache2-bin transmission-daemon curl ca-certificates cron jq libxml2-utils; \
    apt-get install -y apt-transport-https; \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF; \
    echo "deb http://download.mono-project.com/repo/ubuntu xenial main" > /etc/apt/sources.list.d/mono-official.list; \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5CDF62C7AE05CC847657390C10E11090EC0E438; \
    echo "deb https://mediaarea.net/repo/deb/ubuntu xenial main" > /etc/apt/sources.list.d/mediaarea.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends bzip2 ca-certificates-mono libcurl4-openssl-dev mediainfo mono-devel mono-vbnc python sqlite3 unzip; \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# Install forego
RUN FOREGO_URL="https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz"; \
    curl -kL $FOREGO_URL | tar -C /usr/local/bin/ -zx

# Install Jackett
RUN mkdir -p /opt/jackett; \
    JACKETT_RELEASE=`curl -s "https://api.github.com/repos/Jackett/Jackett/releases/latest" | jq -r .tag_name`; \
    JACKETT_URL=`curl -s https://api.github.com/repos/Jackett/Jackett/releases/tags/"${JACKETT_RELEASE}" | jq -r '.assets[].browser_download_url' | grep Mono`; \
    curl -L "$JACKETT_URL" | tar -C /opt/jackett --strip-components=1 -zx

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
