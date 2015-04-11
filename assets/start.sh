#!/bin/bash

mkdir -p /data/{transmission,watch,downloads}
cp /opt/transmission.json /data/transmission/settings.json
ln -s /data/downloads /srv/http/downloads

mkdir -p /etc/systemd/system/transmission.service.d
cat << EOF > /etc/systemd/system/transmission.service.d/env.conf
[Service]
User=root
Environment="EMAIL=$EMAIL"
ExecStart=/usr/bin/transmission-daemon -f -g /data/transmission
EOF

exec /usr/bin/init
