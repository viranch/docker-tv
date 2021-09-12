FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

# Build Transmission nightly that includes https://github.com/transmission/transmission/pull/1080
# but replace its v3.00 web interface with v2.94's web interface for JS API compatibility
# Also install other runtime dependencies of this docker image while we're apt-get'in stuff
RUN apt-get update && \
    apt-get install -y --no-install-recommends git cmake make g++ ca-certificates libcurl4-openssl-dev libssl-dev zlib1g-dev autotools-dev automake libtool && \
    git clone https://github.com/transmission/transmission /tmp/transmission && \
    cp -R /tmp/transmission /tmp/transmission2 && \
    cd /tmp/transmission && git checkout 0e2ecd8f63f9d0605d9798b0ae8e195a9d5bdc9b && git submodule update --init && \
    git -C /tmp/transmission2 checkout tags/2.94 && rm -rf web/* && cp -R /tmp/transmission2/web web/public_html && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_WEB=OFF -DENABLE_TESTS=OFF -DINSTALL_DOC=OFF -DENABLE_UTILS=OFF .. && \
    make -j$(cat /proc/cpuinfo | grep processor -c) && make install && \
    apt-get remove -y --purge git cmake make g++ libcurl4-openssl-dev libssl-dev zlib1g-dev autotools-dev automake libtool && \
    apt-get autoremove -y && \
    apt-get install -y --no-install-recommends apache2 apache2-bin curl cron jq libxml2-utils && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# Install forego
RUN FOREGO_URL="https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz"; \
    curl -kL $FOREGO_URL | tar -C /usr/local/bin/ -zx

# Install Jackett
RUN JACKETT_VERSION="$(curl -s https://api.github.com/repos/Jackett/Jackett/releases | jq -r '.[0].name')"; \
    JACKETT_URL="https://github.com/Jackett/Jackett/releases/download/${JACKETT_VERSION}/Jackett.Binaries.LinuxAMDx64.tar.gz"; \
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
